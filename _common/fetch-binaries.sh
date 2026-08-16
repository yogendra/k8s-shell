#!/usr/bin/env bash
# Builder-stage script: downloads every pinned GitHub-release binary used by
# EITHER k8s-shell or k8s-gui-shell, sha256-verified per versions.env, into
# <out_dir>/bin/<name> (flat, ready to `COPY --from=builder .../bin/
# /usr/local/bin/`) plus <out_dir>/krew-root (bootstrapped krew install).
#
# Usage: TARGETARCH=amd64|arm64 fetch-binaries.sh <out_dir>
set -euo pipefail

COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$COMMON_DIR/lib.sh"

OUT_DIR="${1:?usage: fetch-binaries.sh <out_dir>}"
BIN_DIR="$OUT_DIR/bin"
mkdir -p "$BIN_DIR"

ARCH_KEY="$(normalize_arch)"          # AMD64 | ARM64
sha() { local var="${1}_SHA256_${ARCH_KEY}"; echo "${!var:?missing $var in versions.env}"; }

# Every tool below names its release assets differently. GO_ARCH covers most
# Go-built tools (amd64/arm64); X86_ARCH covers the govc/grpcurl convention
# (x86_64 for amd64, but arm64 stays arm64); SHORT_ARCH is termshark-only
# (x64 for amd64); RUST_ARCH is the Rust target-triple convention used by
# herdr/starship/eza/websocat/trippy (x86_64/aarch64).
case "$TARGETARCH" in
amd64)
  GO_ARCH=amd64; X86_ARCH=x86_64; SHORT_ARCH=x64; RUST_ARCH=x86_64
  ;;
arm64)
  GO_ARCH=arm64; X86_ARCH=arm64; SHORT_ARCH=arm64; RUST_ARCH=aarch64
  ;;
esac

log "fetching pinned binaries for $TARGETARCH"

# istioctl
fetch_tar "https://github.com/istio/istio/releases/download/${ISTIO_VERSION}/istioctl-${ISTIO_VERSION}-linux-${GO_ARCH}.tar.gz" \
  "$(sha ISTIOCTL)" "$BIN_DIR" istioctl

# velero (nested dir, strip-components=1)
fetch_tar "https://github.com/vmware-tanzu/velero/releases/download/${VELERO_VERSION}/velero-${VELERO_VERSION}-linux-${GO_ARCH}.tar.gz" \
  "$(sha VELERO)" "$BIN_DIR" --strip-components=1 "velero-${VELERO_VERSION}-linux-${GO_ARCH}/velero"

# stern
fetch_tar "https://github.com/stern/stern/releases/download/v${STERN_VERSION}/stern_${STERN_VERSION}_linux_${GO_ARCH}.tar.gz" \
  "$(sha STERN)" "$BIN_DIR" stern

# herdr
fetch_bin "https://github.com/herdrdev/herdr/releases/download/${HERDR_VERSION}/herdr-linux-${RUST_ARCH}" \
  "$BIN_DIR/herdr" "$(sha HERDR)"

# k9s (capital L in the release asset name)
fetch_tar "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_${GO_ARCH}.tar.gz" \
  "$(sha K9S)" "$BIN_DIR" k9s

# dive
fetch_tar "https://github.com/wagoodman/dive/releases/download/${DIVE_VERSION}/dive_${DIVE_VERSION#v}_linux_${GO_ARCH}.tar.gz" \
  "$(sha DIVE)" "$BIN_DIR" dive

# govc (amd64 asset is x86_64, capital L)
fetch_tar "https://github.com/vmware/govmomi/releases/download/${GOVC_VERSION}/govc_Linux_${X86_ARCH}.tar.gz" \
  "$(sha GOVC)" "$BIN_DIR" govc

# yq (raw binary)
fetch_bin "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${GO_ARCH}" \
  "$BIN_DIR/yq" "$(sha YQ)"

# fzf (Ubuntu's apt package is too old for the --bash flag .bashrc uses)
fetch_tar "https://github.com/junegunn/fzf/releases/download/${FZF_VERSION}/fzf-${FZF_VERSION#v}-linux_${GO_ARCH}.tar.gz" \
  "$(sha FZF)" "$BIN_DIR" fzf

# starship (musl static build)
fetch_tar "https://github.com/starship/starship/releases/download/${STARSHIP_VERSION}/starship-${RUST_ARCH}-unknown-linux-musl.tar.gz" \
  "$(sha STARSHIP)" "$BIN_DIR" starship

# eza
fetch_tar "https://github.com/eza-community/eza/releases/download/${EZA_VERSION}/eza_${RUST_ARCH}-unknown-linux-gnu.tar.gz" \
  "$(sha EZA)" "$BIN_DIR" ./eza

# helm (helm's official apt repo at baltocdn.com is defunct; get.helm.sh is
# their real, still-live binary CDN)
fetch_tar "https://get.helm.sh/helm-${HELM_VERSION}-linux-${GO_ARCH}.tar.gz" \
  "$(sha HELM)" "$BIN_DIR" --strip-components=1 "linux-${GO_ARCH}/helm"

# carvel suite (raw binaries)
fetch_bin "https://github.com/carvel-dev/ytt/releases/download/${YTT_VERSION}/ytt-linux-${GO_ARCH}" "$BIN_DIR/ytt" "$(sha YTT)"
fetch_bin "https://github.com/carvel-dev/kapp/releases/download/${KAPP_VERSION}/kapp-linux-${GO_ARCH}" "$BIN_DIR/kapp" "$(sha KAPP)"
fetch_bin "https://github.com/carvel-dev/kbld/releases/download/${KBLD_VERSION}/kbld-linux-${GO_ARCH}" "$BIN_DIR/kbld" "$(sha KBLD)"
fetch_bin "https://github.com/carvel-dev/imgpkg/releases/download/${IMGPKG_VERSION}/imgpkg-linux-${GO_ARCH}" "$BIN_DIR/imgpkg" "$(sha IMGPKG)"
fetch_bin "https://github.com/carvel-dev/vendir/releases/download/${VENDIR_VERSION}/vendir-linux-${GO_ARCH}" "$BIN_DIR/vendir" "$(sha VENDIR)"
fetch_bin "https://github.com/carvel-dev/kapp-controller/releases/download/${KCTRL_VERSION}/kctrl-linux-${GO_ARCH}" "$BIN_DIR/kctrl" "$(sha KCTRL)"

# trippy (binary inside the archive is named "trip", not "trippy")
fetch_tar "https://github.com/fujiapple852/trippy/releases/download/${TRIPPY_VERSION}/trippy-${TRIPPY_VERSION}-${RUST_ARCH}-unknown-linux-gnu.tar.gz" \
  "$(sha TRIPPY)" "$BIN_DIR" --strip-components=1 "trippy-${TRIPPY_VERSION}-${RUST_ARCH}-unknown-linux-gnu/trip"

# websocat (raw static-musl binary)
fetch_bin "https://github.com/vi/websocat/releases/download/${WEBSOCAT_VERSION}/websocat.${RUST_ARCH}-unknown-linux-musl" \
  "$BIN_DIR/websocat" "$(sha WEBSOCAT)"

# ctop (version in the asset name has no leading "v")
fetch_bin "https://github.com/bcicen/ctop/releases/download/${CTOP_VERSION}/ctop-${CTOP_VERSION#v}-linux-${GO_ARCH}" \
  "$BIN_DIR/ctop" "$(sha CTOP)"

# calicoctl
fetch_bin "https://github.com/projectcalico/calico/releases/download/${CALICOCTL_VERSION}/calicoctl-linux-${GO_ARCH}" \
  "$BIN_DIR/calicoctl" "$(sha CALICOCTL)"

# termshark (amd64 asset arch is "x64")
fetch_tar "https://github.com/gcla/termshark/releases/download/${TERMSHARK_VERSION}/termshark_${TERMSHARK_VERSION#v}_linux_${SHORT_ARCH}.tar.gz" \
  "$(sha TERMSHARK)" "$BIN_DIR" --strip-components=1 "termshark_${TERMSHARK_VERSION#v}_linux_${SHORT_ARCH}/termshark"

# grpcurl (amd64 asset arch is "x86_64")
fetch_tar "https://github.com/fullstorydev/grpcurl/releases/download/${GRPCURL_VERSION}/grpcurl_${GRPCURL_VERSION#v}_linux_${X86_ARCH}.tar.gz" \
  "$(sha GRPCURL)" "$BIN_DIR" grpcurl

# fortio (binary nested under usr/bin/)
fetch_tar "https://github.com/fortio/fortio/releases/download/${FORTIO_VERSION}/fortio-linux_${GO_ARCH}-${FORTIO_VERSION#v}.tgz" \
  "$(sha FORTIO)" "$BIN_DIR" --strip-components=2 usr/bin/fortio

chmod +x "$BIN_DIR"/*
log "fetched $(ls "$BIN_DIR" | wc -l | tr -d ' ') binaries into $BIN_DIR"

# --- krew: bootstrap the plugin manager itself (kubectl krew install <plugin>
# needs network + kubectl and happens later, in the final stage) -----------
#
# krew's installer lays down bin/kubectl-krew as an ABSOLUTE symlink into
# KREW_ROOT/store/krew/<version>/krew, so it must be bootstrapped at the same
# absolute path it'll live at in the final image (/usr/local/krew) - not a
# builder-local path like $OUT_DIR - or the symlink dangles once
# `COPY --from=builder` moves it into the final stage.
KREW_ROOT="/usr/local/krew"
mkdir -p "$KREW_ROOT"
KREW_TMP="$(mktemp -d)"
fetch_tar "https://github.com/kubernetes-sigs/krew/releases/download/${KREW_VERSION}/krew-linux_${GO_ARCH}.tar.gz" \
  "$(sha KREW)" "$KREW_TMP"
KREW_ROOT="$KREW_ROOT" "$KREW_TMP/krew-linux_${GO_ARCH}" install krew
rm -rf "$KREW_TMP"
log "bootstrapped krew into $KREW_ROOT"
