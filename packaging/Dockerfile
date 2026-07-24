FROM alpine:3.20 AS builder
ARG TARGETARCH

LABEL org.opencontainers.image.source="https://github.com/yogendra-avgo/k8s-shell"
LABEL org.opencontainers.image.authors="yogendrarampuria@gmail.com"
LABEL org.opencontainers.image.description "Batteries included Kubernete shell for operating and troubleshooting"

# Tool Version Matrix
ARG ISTIO_VERSION="1.22.2"
ARG VELERO_VERSION="v1.14.0"
ARG STERN_VERSION="1.30.0"

RUN apk add --no-cache curl tar gzip jq ca-certificates

WORKDIR /workspace

# 1. istioctl
RUN curl -sSL "https://github.com/istio/istio/releases/download/${ISTIO_VERSION}/istioctl-${ISTIO_VERSION}-linux-${TARGETARCH}.tar.gz" | tar -xz && \
    chmod +x istioctl

# 2. Velero
RUN curl -sSL "https://github.com/vmware-tanzu/velero/releases/download/${VELERO_VERSION}/velero-${VELERO_VERSION}-linux-${TARGETARCH}.tar.gz" | tar -xz --strip-components=1 velero-${VELERO_VERSION}-linux-${TARGETARCH}/velero && \
    chmod +x velero

# 3. Stern
RUN curl -sSL "https://github.com/stern/stern/releases/download/v${STERN_VERSION}/stern_${STERN_VERSION}_linux_${TARGETARCH}.tar.gz" | tar -xz stern && \
    chmod +x stern

# 4. herdr (AI agent terminal multiplexer)
RUN curl -fsSL https://herdr.dev/install.sh | HERDR_INSTALL_DIR=/workspace sh


# -------------------------------------------------------------
# Final Image built on nicolaka/netshoot
# -------------------------------------------------------------
FROM nicolaka/netshoot:latest

ARG TARGETARCH
ARG KREW_VERSION="v0.5.0"

# Populated by the build (Taskfile.yml) from the building checkout's own git
# remote/commit, not the tool versions above - identifies which k8s-shell
# source built this image.
ARG GIT_REPO="unknown"
ARG GIT_SHA="unknown"
ARG GIT_BRANCH="unknown"

LABEL org.opencontainers.image.source="https://github.com/yogendra-avgo/k8s-shell"
LABEL org.opencontainers.image.authors="yogendrarampuria@gmail.com"

RUN apk add --no-cache \
    bash \
    bash-completion \
    bat \
    bat-bash-completion \
    ca-certificates \
    direnv \
    dive \
    docker-cli \
    eza \
    eza-bash-completion \
    fd \
    fd-bash-completion \
    fzf \
    gawk \
    git \
    git-bash-completion \
    govc \
    grep \
    helm \
    helm-bash-completion \
    jq \
    k9s \
    k9s-bash-completion \
    kubectl \
    kubectl-bash-completion \
    kubectl-cert-manager \
    kubectl-krew \
    ncurses \
    openldap-clients \
    sed \
    starship \
    tmux \
    tree \
    yq-go \
    yq-go-bash-completion


# Non-root by default. Raw-socket netshoot tools (tcpdump, nmap SYN scans, ...)
# still need `--user root` / extra capabilities if you reach for them.
RUN addgroup -g 1000 shell && \
    adduser -D -u 1000 -G shell -h /home/shell -s /bin/bash shell

# fzf-tab-completion: pipes bash's own tab-completion candidates (for any
# command, not just files/history) through fzf. Needs real GNU awk/sed/grep
# (installed above) - it's only tested against those and busybox's versions
# of them are known to trip it up. Vendored at a pinned commit into a shared,
# world-readable path so both the shell user and root can source it.
RUN git clone --quiet https://github.com/lincheney/fzf-tab-completion.git /usr/local/share/fzf-tab-completion && \
    git -C /usr/local/share/fzf-tab-completion checkout --quiet 8ba35e65bb3792759bf17c134ce04120e5940555

# Copy the binaries with no apk package into place (see the Tool Version
# Matrix note above - everything else comes from the apk add above).
COPY --from=builder /workspace/istioctl /usr/local/bin/
COPY --from=builder /workspace/velero /usr/local/bin/
COPY --from=builder /workspace/stern /usr/local/bin/
COPY --from=builder /workspace/herdr /usr/local/bin/
COPY packaging/osc52-copy /usr/local/bin/osc52-copy
RUN chmod +x /usr/local/bin/osc52-copy

# Bake static completion files for the tools above with no apk package (and
# hence no completion file dropped in already) - same effect as sourcing
# `<tool> completion bash` in .bashrc, but generated once at build time
# instead of spawning each tool on every shell start. bash-completion (apk
# package, sourced in .bashrc) lazily loads these by filename, same as it
# does for the apk *-bash-completion packages.
RUN istioctl completion bash > /usr/share/bash-completion/completions/istioctl && \
    velero completion bash > /usr/share/bash-completion/completions/velero && \
    dive completion bash > /usr/share/bash-completion/completions/dive && \
    stern --completion=bash > /usr/share/bash-completion/completions/stern

# krew - kubectl's plugin manager, plus a handful of commonly used plugins.
# KREW_ROOT is a fixed absolute path (not under a home dir), so unlike the
# dotfiles it doesn't need duplicating per-user - both shell and root see the
# same install; chmod a+rX at the end so the non-root shell user can use it
# too, since it's installed here as root.
ENV KREW_ROOT=/usr/local/krew
ENV PATH="${KREW_ROOT}/bin:${PATH}"
RUN kubectl krew install ctx ns tree neat who-can view-secret get-all images && \
    chmod -R a+rX "${KREW_ROOT}"

# install carvel tools
RUN wget -O- https://carvel.dev/install.sh  | bash

RUN printf 'repo=%s\nsha=%s\nbranch=%s\n' "${GIT_REPO}" "${GIT_SHA}" "${GIT_BRANCH}" > /etc/k8s-shell-version

USER shell
WORKDIR /home/shell
ENV HOME=/home/shell

# Dotfiles
COPY --chown=shell:shell dotfiles/ /home/shell/

# tmux plugin manager - clone tpm itself, then run its own installer against
# the @plugin lines already declared in tmux.conf, so every plugin it lists
# is vendored at build time and tmux works fully offline on first run.
RUN mkdir -p /home/shell/.config/tmux/plugins && \
    git clone --depth 1 --quiet https://github.com/tmux-plugins/tpm.git /home/shell/.config/tmux/plugins/tpm && \
    rm -rf /home/shell/.config/tmux/plugins/tpm/.git \
    /home/shell/.config/tmux/plugins/tpm/bin/install_plugins

USER root

# Give root the same shell experience for `docker run --user root` / raw-socket work.
RUN cp -a /home/shell/.bashrc /home/shell/.bash_profile /home/shell/.vimrc /home/shell/.config /root/ && \
    chown -R root:root /root/.bashrc /root/.bash_profile /root/.vimrc /root/.config

COPY packaging/entrypoint /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint
USER shell

ENTRYPOINT ["/usr/local/bin/entrypoint"]
CMD []
