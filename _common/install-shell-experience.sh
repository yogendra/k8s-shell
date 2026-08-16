#!/usr/bin/env bash
# The interactive-shell "developer experience" layer: bat/eza/fzf/starship/
# tmux/etc, plus docker's CLI (no engine) via Docker's own apt repo since
# Ubuntu's default repos only ship the combined docker.io (CLI+engine) package.
set -euo pipefail

COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$COMMON_DIR/lib.sh"

apt_refresh
apt_install \
  bat \
  direnv \
  fd-find \
  gawk \
  grep \
  ldap-utils \
  ncurses-bin \
  sed \
  tmux \
  tree

# Ubuntu's `bat`/`fd-find` packages install their binaries under different
# names (a package-name clash with unrelated tools) - symlink them to the
# names every dotfile/alias in this repo already expects.
ln -sf /usr/bin/batcat /usr/local/bin/bat
ln -sf /usr/bin/fdfind /usr/local/bin/fd

# docker CLI only, no engine/containerd - Ubuntu's own repos only offer the
# combined docker.io package, so pull docker-ce-cli from Docker's official repo.
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
. /etc/os-release
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
  > /etc/apt/sources.list.d/docker.list
apt_refresh
apt_install docker-ce-cli
apt_cleanup

# fzf-tab-completion: pipes bash's own tab-completion candidates through fzf.
# Vendored at a pinned commit into a shared, world-readable path so both the
# non-root user and root can source it.
git clone --quiet https://github.com/lincheney/fzf-tab-completion.git /usr/local/share/fzf-tab-completion
git -C /usr/local/share/fzf-tab-completion checkout --quiet "$FZF_TAB_COMPLETION_COMMIT"
rm -rf /usr/local/share/fzf-tab-completion/.git
