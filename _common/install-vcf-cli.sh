#!/usr/bin/env bash
# vcf-cli via Broadcom's own official apt repo (packages.broadcom.com),
# pinned to an exact package version - same pattern as
# install-k8s-tools.sh's kubectl install. Public/unauthenticated repo; no
# BROADCOM_REGISTRY_TOKEN needed for the base CLI (VCF CLI plugins are a
# separate, token-gated registry flow, not yet wired up here).
set -euo pipefail

COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$COMMON_DIR/lib.sh"

install -m 0755 -d /etc/apt/keyrings
curl -fsSL \
  https://packages.broadcom.com/artifactory/vcfcli-debian/tools/keys/BROADCOM-PACKAGING-GPG-RSA-KEY.pub \
  https://packages.broadcom.com/artifactory/api/security/keypair/PackagesKey/public \
  | gpg --dearmor -o /etc/apt/keyrings/vcf-cli-apt-keyring.gpg
chmod a+r /etc/apt/keyrings/vcf-cli-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/vcf-cli-apt-keyring.gpg] https://packages.broadcom.com/artifactory/vcfcli-debian noble main" \
  > /etc/apt/sources.list.d/vcf-cli.list

apt_refresh
apt_install "vcf-cli=${VCF_CLI_VERSION}"
apt-mark hold vcf-cli
apt_cleanup

vcf plugin  list
vcf plugin  search -o json  | jq '.[].name' -r | while read plugin ; do vcf plugin install $plugin; done