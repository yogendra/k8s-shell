#!/usr/bin/env bash
# Shared helpers sourced by every _common/*.sh install script. Not meant to be
# run directly.
set -euo pipefail

COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=versions.env
. "$COMMON_DIR/versions.env"

log() {
  echo "[$(basename "${0:-lib.sh}")] $*" >&2
}

# apt_install pkg [pkg...] — unattended, minimal, cleans up the apt cache/lists
# in the same layer so no script needs to remember to do it separately.
apt_install() {
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"
}

apt_refresh() {
  apt-get update
}

apt_cleanup() {
  rm -rf /var/lib/apt/lists/*
}

# normalize_arch — maps Docker's TARGETARCH (amd64/arm64) to the upper-case
# suffix used by versions.env's per-tool SHA256 keys (AMD64/ARM64).
normalize_arch() {
  case "${TARGETARCH:?TARGETARCH must be set}" in
  amd64) echo "AMD64" ;;
  arm64) echo "ARM64" ;;
  *) log "unsupported TARGETARCH: $TARGETARCH"; exit 1 ;;
  esac
}

# verify_sha256 <file> <expected-hex>
verify_sha256() {
  local file="$1" expected="$2" actual
  actual="$(sha256sum "$file" | awk '{print $1}')"
  if [ "$actual" != "$expected" ]; then
    log "checksum mismatch for $file: expected $expected, got $actual"
    exit 1
  fi
}

# fetch_bin <url> <dest-file> <expected-sha256>
# Downloads a single-file binary release asset straight to its final path,
# verifies it, and makes it executable.
fetch_bin() {
  local url="$1" dest="$2" expected="$3"
  log "fetching $url -> $dest"
  curl -fsSL "$url" -o "$dest"
  verify_sha256 "$dest" "$expected"
  chmod +x "$dest"
}

# fetch_tar <url> <expected-sha256> <out-dir> [tar-args...]
# Downloads a tarball to a temp file, verifies it, then extracts with
# whatever extra tar args the caller needs (e.g. --strip-components=1, or an
# explicit member to pull a single binary out of a multi-file archive).
# Decompression flag is picked from the URL's own extension - every caller so
# far has been .tar.gz, but Nerd Fonts' release assets (k8s-gui-shell only)
# are .tar.xz.
fetch_tar() {
  local url="$1" expected="$2" out_dir="$3"
  shift 3
  local tmp tar_flag
  tmp="$(mktemp)"
  case "$url" in
  *.tar.xz) tar_flag=-xJf ;;
  *) tar_flag=-xzf ;;
  esac
  log "fetching $url"
  curl -fsSL "$url" -o "$tmp"
  verify_sha256 "$tmp" "$expected"
  mkdir -p "$out_dir"
  tar "$tar_flag" "$tmp" -C "$out_dir" "$@"
  rm -f "$tmp"
}

# install_dotfiles <home_dir> <owner:group>
# Copies _common/dotfiles/* into <home_dir>, chowns to <owner:group>, and
# vendors tmux's plugin manager (tpm) so tmux.conf's @plugin lines work
# offline on first run. Idempotent/self-sufficient — safe to call once per
# target home (e.g. once for a non-root user, once for root) with no
# ordering dependency between calls.
install_dotfiles() {
  local home_dir="$1" owner="$2"
  mkdir -p "$home_dir"
  cp -a "$COMMON_DIR/dotfiles/." "$home_dir/"
  mkdir -p "$home_dir/.config/tmux/plugins"
  git clone --depth 1 --quiet https://github.com/tmux-plugins/tpm.git \
    "$home_dir/.config/tmux/plugins/tpm"
  rm -rf "$home_dir/.config/tmux/plugins/tpm/.git"
  chown -R "$owner" "$home_dir"
}
