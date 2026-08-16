# Kubernetes GUI Shell

A full XFCE desktop reachable over a browser
([lscr.io/linuxserver/webtop:ubuntu-xfce](https://docs.linuxserver.io/images/docker-webtop/)),
layered with the same tool/dotfile bundle as [`k8s-shell`](../k8s-shell) -
kubectl, helm, istioctl, velero, k9s, stern, yq, govc, vcf-cli, the
[Carvel](https://carvel.dev) suite, [krew](https://krew.sigs.k8s.io/) with
the same plugins, the full network/troubleshooting toolset (`tcpdump`,
`tshark`, `nmap`, `mtr`, `dig`, `ctop`, `calicoctl`, `termshark`, `grpcurl`,
`fortio`, `trippy`, `websocat`, ...), and the bash/tmux/fzf/starship shell
experience. See `k8s-shell`'s README for the full tool list and rationale -
this document only covers what's different about the GUI variant.

Both images share their installation logic via [`../_common`](../_common),
so they can't silently drift onto different tool versions.

## What's different from k8s-shell

- **Base image**: `lscr.io/linuxserver/webtop:ubuntu-xfce` (itself Ubuntu
  24.04), not plain `ubuntu:24.04` - this image is a desktop, not a bare
  terminal.
- **User**: the default user is still `abc` (webtop's own), *not* renamed to
  `ubuntu`. linuxserver's own init hardcodes the literal username `abc` on
  every container start (PUID/PGID remap, `/config` ownership, ...) -
  renaming or removing it would break that step. `abc`'s uid/gid still get
  remapped from the `PUID`/`PGID` env vars at container start, same as any
  other webtop image.
- **Dotfiles installed at build time into `/root` and `/etc/skel`**: `/root`
  so `sudo`/`su -` gets the same shell, `/etc/skel` so any additional user
  created later (manually, or by a future multi-user desktop setup) gets the
  same bundle via `useradd -m` for free. **Not** installed into `/config`
  (`abc`'s home) at build time - `/config` is a declared `VOLUME` in the
  upstream webtop image, so build-time content there would carry build-time
  `abc` ownership into whatever volume gets mounted at runtime. Instead,
  [`packaging/custom-cont-init.d/00-init-config-home.sh`](packaging/custom-cont-init.d/00-init-config-home.sh)
  copies the same bundle from `/etc/skel` into `/config` at container start
  (first run only) and re-asserts ownership on every start, once `abc`'s
  real `PUID`/`PGID`-remapped ids are known.
- **No custom `ENTRYPOINT`**: unlike k8s-shell, this image does not override
  webtop's own s6-overlay init, PUID/PGID remap, or desktop boot sequence -
  there's no raw terminal here to hand a multiplexer to; you open a terminal
  app yourself inside the desktop, and it picks up the same `.bashrc`.
- **Two `custom-cont-init.d` hooks**, both running once at container start
  (linuxserver's supported one-shot extension point - `/custom-cont-init.d`,
  *not* `/config/custom-services.d`, which is reserved for long-running
  services and isn't scanned under `/config` anyway):
  [`00-init-config-home.sh`](packaging/custom-cont-init.d/00-init-config-home.sh)
  (above) and
  [`10-kubeconfig.sh`](packaging/custom-cont-init.d/10-kubeconfig.sh), which
  generates an in-cluster kubeconfig for `abc` if a
  ServiceAccount token is mounted, mirroring what k8s-shell's entrypoint
  does for its own user.
- **Nerd Font + Pastel Powerline prompt**: unlike k8s-shell's raw terminal
  (whatever client emulator the user already has open, possibly without a
  Nerd Font - hence the shared `starship.toml` in `_common/dotfiles` staying
  in a plain-text configuration), this image's terminal is a real desktop app
  it fully controls. [`packaging/install-nerd-font.sh`](packaging/install-nerd-font.sh)
  installs FiraCode Nerd Font Mono system-wide,
  [`packaging/xfce4-terminal.terminalrc`](packaging/xfce4-terminal.terminalrc)
  makes it xfce4-terminal's default font, and
  [`packaging/starship.toml`](packaging/starship.toml) overrides the shared
  prompt config with a Pastel Powerline theme for both `abc` and `root`.

## Usage - Docker

```bash
docker run -d --name k8s-gui-shell \
  -p 3000:3000 -p 3001:3001 \
  -e PUID=1000 -e PGID=1000 \
  -v k8s-gui-shell-config:/config \
  ghcr.io/yogendra-avgo/k8s-gui-shell

open https://localhost:3001   # or http://localhost:3000
```

Port `3001` is HTTPS (recommended), `3000` is HTTP. See
[linuxserver's webtop docs](https://docs.linuxserver.io/images/docker-webtop/)
for the full set of supported environment variables (`TITLE`, `SUBFOLDER`,
`CUSTOM_USER`/`PASSWORD` for basic auth, etc.) - they all apply here
unchanged.

## Usage - Kubernetes

```bash
kubectl apply -f k8s/rbac.yaml -f k8s/deployment.yaml
kubectl --context <ctx> port-forward -n k8s-gui-shell deploy/k8s-gui-shell 3001:3001
open https://localhost:3001
```

Unlike `k8s-shell`'s Deployment, this one does **not** run with
`readOnlyRootFilesystem` or a dropped-capabilities `securityContext` by
default: the XFCE desktop, D-Bus, PulseAudio, and webtop's own s6-overlay
init all expect a writable root filesystem. The manifest uses a plain
`emptyDir` for `/config`, so desktop state (browser profile, terminal
history, ...) does not survive pod restarts - mount a PVC there instead if
you want it to.

`k8s/rbac.yaml` binds the same `cluster-admin` ClusterRoleBinding pattern as
`k8s-shell` - see that README's RBAC section for the tradeoffs and safer
alternatives.

## Building locally

```bash
task build   # build for your native platform and load it into Docker
task smoke   # build + sanity-check every bundled CLI tool actually runs
task push    # build linux/amd64+linux/arm64 and push to the registry
```

`task smoke` bypasses webtop's `s6-overlay` entrypoint entirely
(`docker run --entrypoint bash`) to check CLI tools without booting the
whole desktop - it does **not** verify that XFCE/the browser UI actually
comes up. Do that manually (`docker run` + open the URL) before shipping a
change to the base-image pin or anything under `custom-cont-init.d/`.

## CI/CD

[`.github/workflows/k8s-gui-shell-main.yml`](../.github/workflows/k8s-gui-shell-main.yml)
mirrors k8s-shell's workflow: builds and smoke-tests every push/PR that
touches `k8s-gui-shell/` or `_common/`, and on pushes to `main` (or a
`gui-v*` tag) publishes multi-arch images to
`ghcr.io/yogendra-avgo/k8s-gui-shell`.

## Acknowledgements

Built on [linuxserver.io](https://www.linuxserver.io)'s
[docker-webtop](https://github.com/linuxserver/docker-webtop). The
network/troubleshooting tool curation is based on
[nicolaka/netshoot](https://github.com/nicolaka/netshoot) by
[@nicolaka](https://github.com/nicolaka) - see `k8s-shell`'s README for
details.
