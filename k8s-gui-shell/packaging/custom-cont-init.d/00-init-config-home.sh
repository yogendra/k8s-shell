#!/usr/bin/env bash
# linuxserver custom-cont-init.d hook: runs once at container start, as root,
# after abc's uid/gid have already been remapped from PUID/PGID
# (init-adduser) but before the desktop boots.
#
# /config is a declared VOLUME in the upstream webtop image, so the
# Dockerfile deliberately does not bake dotfiles into it at build time - only
# into /etc/skel, which has no such volume semantics to fight. "First run"
# copy, mirroring the same pattern linuxserver's own init-selkies-config uses
# for openbox's config dir: populate /config from /etc/skel only if it looks
# uninitialized, so a later restart against the same volume doesn't clobber
# whatever the user has since edited in their own .bashrc/.vimrc/etc.
#
# The chown afterwards runs unconditionally (not just on first run), since a
# volume populated by an older build of this image - back when dotfiles were
# baked straight into /config - can still be carrying build-time abc
# ownership (911:911, before any PUID/PGID override) on files nothing else
# in the init chain re-chowns, e.g. starship failing with "Unable to create
# log dir /config/.cache/starship: Permission denied" the first time a shell
# opens. Same `chown -R abc:abc /config` pattern most linuxserver app images
# (plex, sonarr, nextcloud, ...) run in their own app-specific init.
set -euo pipefail

if [ ! -f /config/.config/tmux/tmux.conf ]; then
  cp -a /etc/skel/. /config/
  chown -R abc:abc /config
fi
