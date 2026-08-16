ARG UBUNTU_VERSION=24.04

# -------------------------------------------------------------
# Builder: downloads every pinned binary that has no apt equivalent (see
# _common/fetch-binaries.sh + _common/versions.env for the full list and why).
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
# Final image
# -------------------------------------------------------------
FROM ubuntu:${UBUNTU_VERSION}
ARG TARGETARCH

# Populated by the build (Taskfile.yml) from the building checkout's own git
# remote/commit - identifies which k8s-shell source built this image.
ARG GIT_REPO="unknown"
ARG GIT_SHA="unknown"
ARG GIT_BRANCH="unknown"

LABEL org.opencontainers.image.source="https://github.com/yogendra-avgo/k8s-shell"
LABEL org.opencontainers.image.authors="yogendrarampuria@gmail.com"
LABEL org.opencontainers.image.description="Batteries included Kubernetes shell for operating and troubleshooting"

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

# Bake static completion files for the tools above with no apt-provided
# completion (bash-completion, installed in install-base.sh, lazily loads
# these by filename).
RUN istioctl completion bash > /usr/share/bash-completion/completions/istioctl && \
    velero completion bash > /usr/share/bash-completion/completions/velero && \
    dive completion bash > /usr/share/bash-completion/completions/dive && \
    stern --completion=bash > /usr/share/bash-completion/completions/stern && \
    helm completion bash > /usr/share/bash-completion/completions/helm && \
    kubectl completion bash > /usr/share/bash-completion/completions/kubectl

# Non-root by default, using ubuntu:24.04's own pre-created uid/gid 1000
# "ubuntu" user rather than adding a separate one. Raw-socket tools (tcpdump,
# nmap SYN scans, ...) still need `--user root` / extra capabilities if you
# reach for them. Membership in the `wireshark` group (created by installing
# tshark in install-network-tools.sh) lets this user run dumpcap/tshark
# without root.
RUN usermod -aG wireshark ubuntu

COPY packaging/osc52-copy /usr/local/bin/osc52-copy
RUN chmod +x /usr/local/bin/osc52-copy

RUN printf 'repo=%s\nsha=%s\nbranch=%s\n' "${GIT_REPO}" "${GIT_SHA}" "${GIT_BRANCH}" > /etc/k8s-shell-version

# User profile / root profile: same dotfiles bundle, installed independently
# into each home so `docker run --user root` gets an identical shell/prompt/
# multiplexer experience to the default `ubuntu` user.
RUN /opt/build/common/install-dotfiles.sh /home/ubuntu ubuntu:ubuntu
RUN /opt/build/common/install-dotfiles.sh /root root:root

COPY packaging/entrypoint /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint

RUN rm -rf /opt/build

USER ubuntu
WORKDIR /home/ubuntu
ENV HOME=/home/ubuntu

ENTRYPOINT ["/usr/local/bin/entrypoint"]
CMD []
