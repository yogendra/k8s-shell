#!/usr/bin/env bash
# The "user profile" / "root profile" step: installs the shared dotfiles
# bundle into one target home directory. Called once per profile that needs
# it (e.g. twice in k8s-shell's Dockerfile - once for the `shell` user, once
# for root; twice in k8s-gui-shell's - once for `root`, once for `abc`).
#
# Usage: install-dotfiles.sh <home_dir> <owner:group>
set -euo pipefail

COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$COMMON_DIR/lib.sh"

HOME_DIR="${1:?usage: install-dotfiles.sh <home_dir> <owner:group>}"
OWNER="${2:?usage: install-dotfiles.sh <home_dir> <owner:group>}"

install_dotfiles "$HOME_DIR" "$OWNER"
