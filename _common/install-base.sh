#!/usr/bin/env bash
# Base OS packages every image needs before the more specific install-*.sh
# scripts run (network tools, shell experience, k8s tools).
set -euo pipefail

COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$COMMON_DIR/lib.sh"

apt_refresh
apt_install \
  bash-completion \
  ca-certificates \
  curl \
  gnupg \
  git \
  jq \
  tar \
  gzip \
  unzip \
  vim
apt_cleanup
