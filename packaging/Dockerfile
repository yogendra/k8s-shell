FROM alpine:3.20 AS builder

ARG TARGETARCH

LABEL org.opencontainers.image.source="https://github.com/yogendra-avgo/k8s-shell"
LABEL org.opencontainers.image.authors="yogendrarampuria@gmail.com"

# Tool Version Matrix
ARG KUBECTL_VERSION="v1.30.2"
ARG HELM_VERSION="v3.15.2"
ARG ISTIO_VERSION="1.22.2"
ARG VELERO_VERSION="v1.14.0"
ARG K9S_VERSION="v0.32.4"
ARG DIVE_VERSION="0.12.0"
ARG GOVC_VERSION="v0.38.0"
ARG STERN_VERSION="1.30.0"
ARG YQ_VERSION="v4.44.2"
ARG FZF_VERSION="0.55.0"
ARG STARSHIP_VERSION="v1.26.0"

RUN apk add --no-cache curl tar gzip jq ca-certificates

WORKDIR /workspace

# 1. kubectl
RUN curl -sSL -o kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl" && \
    chmod +x kubectl

# 2. Helm
RUN curl -sSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-${TARGETARCH}.tar.gz" | tar -xz --strip-components=1 linux-${TARGETARCH}/helm && \
    chmod +x helm

# 3. istioctl
RUN curl -sSL "https://github.com/istio/istio/releases/download/${ISTIO_VERSION}/istioctl-${ISTIO_VERSION}-linux-${TARGETARCH}.tar.gz" | tar -xz && \
    chmod +x istioctl

# 4. Velero
RUN curl -sSL "https://github.com/vmware-tanzu/velero/releases/download/${VELERO_VERSION}/velero-${VELERO_VERSION}-linux-${TARGETARCH}.tar.gz" | tar -xz --strip-components=1 velero-${VELERO_VERSION}-linux-${TARGETARCH}/velero && \
    chmod +x velero

# 5. k9s (release assets use a capitalized "Linux")
RUN curl -sSL "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_${TARGETARCH}.tar.gz" | tar -xz k9s && \
    chmod +x k9s

# 6. Dive
RUN curl -sSL "https://github.com/wagoodman/dive/releases/download/v${DIVE_VERSION}/dive_${DIVE_VERSION}_linux_${TARGETARCH}.tar.gz" | tar -xz dive && \
    chmod +x dive

# 7. VMware govc CLI (release assets use "x86_64" instead of "amd64")
RUN GOVC_ARCH=$([ "${TARGETARCH}" = "amd64" ] && echo "x86_64" || echo "${TARGETARCH}") && \
    curl -sSL "https://github.com/vmware/govmomi/releases/download/${GOVC_VERSION}/govc_Linux_${GOVC_ARCH}.tar.gz" | tar -xz govc && \
    chmod +x govc

# 8. Stern
RUN curl -sSL "https://github.com/stern/stern/releases/download/v${STERN_VERSION}/stern_${STERN_VERSION}_linux_${TARGETARCH}.tar.gz" | tar -xz stern && \
    chmod +x stern

# 9. yq
RUN curl -sSL -o yq "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${TARGETARCH}" && \
    chmod +x yq

# 10. fzf (fuzzy finder, wired into .bashrc via `fzf --bash`)
RUN curl -sSL "https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-linux_${TARGETARCH}.tar.gz" | tar -xz fzf && \
    chmod +x fzf

# 11. Starship prompt (musl build, matches the Alpine base)
RUN STARSHIP_ARCH=$([ "${TARGETARCH}" = "amd64" ] && echo "x86_64-unknown-linux-musl" || echo "aarch64-unknown-linux-musl") && \
    curl -sSL "https://github.com/starship/starship/releases/download/${STARSHIP_VERSION}/starship-${STARSHIP_ARCH}.tar.gz" | tar -xz starship && \
    chmod +x starship

# 12. herdr (AI agent terminal multiplexer)
# NB: the installer reads $HERDR_INSTALL_DIR, not $BINDIR - it auto-detects the
# build's target arch/os itself, which matches TARGETARCH under QEMU emulation.
RUN curl -fsSL https://herdr.dev/install.sh | HERDR_INSTALL_DIR=/workspace sh


# -------------------------------------------------------------
# Final Image built on nicolaka/netshoot
# -------------------------------------------------------------
FROM nicolaka/netshoot:latest

ARG TARGETARCH
ARG KREW_VERSION="v0.5.0"

LABEL org.opencontainers.image.source="https://github.com/yogendra-avgo/k8s-shell"
LABEL org.opencontainers.image.authors="yogendrarampuria@gmail.com"

RUN apk add --no-cache \
    tmux \
    bash \
    git \
    jq \
    ncurses \
    ca-certificates \
    bat \
    tree \
    fd \
    eza \
    direnv \
    gawk \
    sed \
    grep

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

# Copy all binaries into place
COPY --from=builder /workspace/kubectl /usr/local/bin/
COPY --from=builder /workspace/helm /usr/local/bin/
COPY --from=builder /workspace/istioctl /usr/local/bin/
COPY --from=builder /workspace/velero /usr/local/bin/
COPY --from=builder /workspace/k9s /usr/local/bin/
COPY --from=builder /workspace/dive /usr/local/bin/
COPY --from=builder /workspace/govc /usr/local/bin/
COPY --from=builder /workspace/stern /usr/local/bin/
COPY --from=builder /workspace/yq /usr/local/bin/
COPY --from=builder /workspace/fzf /usr/local/bin/
COPY --from=builder /workspace/starship /usr/local/bin/
COPY --from=builder /workspace/herdr /usr/local/bin/
COPY packaging/osc52-copy /usr/local/bin/osc52-copy
RUN chmod +x /usr/local/bin/osc52-copy

# krew - kubectl's plugin manager, plus a handful of commonly used plugins.
# KREW_ROOT is a fixed absolute path (not under a home dir), so unlike the
# dotfiles it doesn't need duplicating per-user - both shell and root see the
# same install; chmod a+rX at the end so the non-root shell user can use it
# too, since it's installed here as root.
ENV KREW_ROOT=/usr/local/krew
ENV PATH="${KREW_ROOT}/bin:${PATH}"
RUN curl -fsSL "https://github.com/kubernetes-sigs/krew/releases/download/${KREW_VERSION}/krew-linux_${TARGETARCH}.tar.gz" -o /tmp/krew.tar.gz && \
    tar -xzf /tmp/krew.tar.gz -C /tmp && \
    /tmp/krew-linux_${TARGETARCH} install krew && \
    rm -f /tmp/krew.tar.gz "/tmp/krew-linux_${TARGETARCH}" && \
    kubectl krew install ctx ns tree neat who-can view-secret get-all images && \
    chmod -R a+rX "${KREW_ROOT}"

# install carvel tools
RUN wget -O- https://carvel.dev/install.sh  | bash

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
