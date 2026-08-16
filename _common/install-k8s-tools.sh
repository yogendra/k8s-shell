#!/usr/bin/env bash
# kubectl via Kubernetes' own official apt repo (pkgs.k8s.io), pinned to an
# exact package version. Everything else k8s-related (helm, istioctl, velero,
# stern, k9s, dive, govc, yq, carvel suite, krew itself) has no comparably
# reliable apt package and is fetched as a pinned binary by
# fetch-binaries.sh instead - this script only covers the apt-native part.
set -euo pipefail

COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$COMMON_DIR/lib.sh"

install -m 0755 -d /etc/apt/keyrings
curl -fsSL "https://pkgs.k8s.io/core:/stable:/${KUBECTL_APT_CHANNEL}/deb/Release.key" \
  | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
chmod a+r /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBECTL_APT_CHANNEL}/deb/ /" \
  > /etc/apt/sources.list.d/kubernetes.list

apt_refresh
apt_install "kubectl=${KUBECTL_VERSION}"
apt-mark hold kubectl
apt_cleanup
