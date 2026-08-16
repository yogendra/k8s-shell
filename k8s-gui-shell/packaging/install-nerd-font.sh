#!/usr/bin/env bash
# k8s-gui-shell only: installs the FiraCode Nerd Font Mono family system-wide.
# Backs both xfce4-terminal's default font (see xfce4-terminal.terminalrc)
# and the glyphs/powerline separators in this image's Pastel Powerline
# starship theme (see starship.toml) - neither renders correctly without it.
# k8s-shell has no equivalent script: its raw terminal is whatever client
# emulator the user already has open, which this image can't install fonts
# into, hence the shared starship.toml under _common/dotfiles staying in a
# Nerd-Font-free "plain text" configuration for that image.
set -euo pipefail

# /opt/build/common is where the Dockerfile's own `COPY --from=common /
# /opt/build/common/` puts _common - same fixed path every other
# install-*.sh call in that Dockerfile already relies on.
. /opt/build/common/lib.sh

FONT_DIR=/usr/local/share/fonts/nerd-fonts
mkdir -p "$FONT_DIR"

TMP="$(mktemp -d)"
fetch_tar "https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONTS_VERSION}/FiraCode.tar.xz" \
  "$NERD_FONTS_FIRACODE_SHA256" "$TMP"

# The release archive is a flat directory of every FiraCode style (Nerd Font,
# Nerd Font Mono, Nerd Font Propo, each in several weights) - only the
# monospace ("Mono") family belongs in a terminal, where the other variants'
# non-fixed-width glyphs would break column alignment.
cp "$TMP"/FiraCodeNerdFontMono-*.ttf "$FONT_DIR/"
rm -rf "$TMP"

fc-cache -f "$FONT_DIR"
