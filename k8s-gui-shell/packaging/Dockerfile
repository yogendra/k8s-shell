# WEBTOP_BASE_TAG must be declared before the first FROM to be usable in the
# second stage's FROM below; the actual pin lives in _common/versions.env and
# is passed in by Taskfile.yml so it can't drift from k8s-shell's copy.
ARG WEBTOP_BASE_TAG=ubuntu-xfce
ARG UBUNTU_VERSION=24.04

# -------------------------------------------------------------
# Builder: downloads every pinned binary that has no apt equivalent (see
# _common/fetch-binaries.sh + _common/versions.env). Same builder as
# k8s-shell's - kept separate per image so each Dockerfile stays self-
# contained and buildable on its own.
# -------------------------------------------------------------
FROM ubuntu:${UBUNTU_VERSION} AS builder
ARG TARGETARCH

COPY --from=common / /opt/build/common/

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg git tar gzip && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
RUN TARGETARCH=$TARGETARCH /opt/build/common/fetch-binaries.sh /workspace/out

# -------------------------------------------------------------
# Final image: linuxserver's Ubuntu+XFCE desktop-in-a-browser, layered with
# the same tool/dotfile bundle as k8s-shell.
# -------------------------------------------------------------
FROM lscr.io/linuxserver/webtop:${WEBTOP_BASE_TAG}
ARG TARGETARCH

# Populated by the build (Taskfile.yml) from the building checkout's own git
# remote/commit - identifies which k8s-shell source built this image.
ARG GIT_REPO="unknown"
ARG GIT_SHA="unknown"
ARG GIT_BRANCH="unknown"

LABEL org.opencontainers.image.source="https://github.com/yogendra-avgo/k8s-gui-shell"
LABEL org.opencontainers.image.authors="yogendrarampuria@gmail.com"
LABEL org.opencontainers.image.description="XFCE desktop-in-a-browser (linuxserver/webtop) with the k8s-shell tool/dotfile bundle"

USER root
COPY --from=common / /opt/build/common/

RUN /opt/build/common/install-base.sh
RUN TARGETARCH=$TARGETARCH /opt/build/common/install-network-tools.sh
RUN /opt/build/common/install-shell-experience.sh
RUN /opt/build/common/install-k8s-tools.sh
RUN /opt/build/common/install-vcf-cli.sh

# Binaries with no apt equivalent (see _common/fetch-binaries.sh) + krew's
# bootstrapped install.
COPY --from=builder /workspace/out/bin/ /usr/local/bin/
COPY --from=builder /usr/local/krew/ /usr/local/krew/
ENV KREW_ROOT=/usr/local/krew
ENV PATH="${KREW_ROOT}/bin:${PATH}"
RUN chmod -R a+rX "${KREW_ROOT}" && \
    kubectl krew install ctx ns tree neat who-can view-secret get-all images

RUN istioctl completion bash > /usr/share/bash-completion/completions/istioctl && \
    velero completion bash > /usr/share/bash-completion/completions/velero && \
    dive completion bash > /usr/share/bash-completion/completions/dive && \
    stern --completion=bash > /usr/share/bash-completion/completions/stern && \
    helm completion bash > /usr/share/bash-completion/completions/helm && \
    kubectl completion bash > /usr/share/bash-completion/completions/kubectl

# `abc` is webtop's own default user (uid/gid remapped from PUID/PGID at
# container start via the base image's own s6 init) - kept as-is rather than
# renamed/replaced: linuxserver's own init-adduser step hardcodes the literal
# username "abc" (PUID/PGID remap, /config ownership, ...) on every container
# start, so renaming or removing it would break that step. Membership in the
# `wireshark` group (created by installing tshark in install-network-tools.sh)
# lets it run dumpcap/tshark without root, same as k8s-shell's `ubuntu` user.
RUN usermod -aG wireshark abc

RUN printf 'repo=%s\nsha=%s\nbranch=%s\n' "${GIT_REPO}" "${GIT_SHA}" "${GIT_BRANCH}" > /etc/k8s-shell-version

# Root profile / abc profile: same dotfiles bundle as k8s-shell, installed
# independently into each home so whichever terminal app is opened inside the
# desktop gets the same shell/prompt experience (including `sudo su`/root
# logins). Chowned by username (not a hardcoded uid) since webtop remaps
# abc's uid/gid from PUID/PGID at runtime, after these files are already
# baked in. Also seeded into /etc/skel so any additional user created later
# (manually, or by a future multi-user desktop setup) gets the same bundle
# via `useradd -m` without needing this Dockerfile to know its name.
RUN /opt/build/common/install-dotfiles.sh /etc/skel root:root
RUN /opt/build/common/install-dotfiles.sh /root root:root
RUN /opt/build/common/install-dotfiles.sh /config abc:abc

# linuxserver's supported extension point: scripts here run once at container
# start, before the desktop boots, alongside (not instead of) the base
# image's own s6-overlay init - unlike k8s-shell's ENTRYPOINT, which this
# image deliberately does not override (there's no raw terminal to hand a
# multiplexer to; the user opens a terminal app themselves inside the
# desktop).
COPY packaging/custom-cont-init.d/ /custom-cont-init.d/
RUN chmod +x /custom-cont-init.d/*.sh

RUN rm -rf /opt/build
