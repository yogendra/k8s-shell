# `_common`

Shared installation scripts and dotfiles used by every image in this repo
(currently [`k8s-shell`](../k8s-shell) and [`k8s-gui-shell`](../k8s-gui-shell),
more may follow). Keeping this in one place means the two images can't
silently drift onto different tool versions or a different network-tool
list - a change here is picked up by both on the next build.

Each image's `Taskfile.yml` exposes this directory to its `Dockerfile` as a
named buildx context called `common` (`--build-context common=../_common`),
so `COPY --from=common / /opt/build/common/` works the same way from either
image without widening the build context to the whole repo.

## Files

- **`versions.env`** - single source of truth for every pinned tool version
  and its per-arch sha256 checksum. Sourced by every script below.
- **`lib.sh`** - shared bash helpers (`apt_install`, `fetch_bin`/`fetch_tar`
  with checksum verification, `install_dotfiles`).
- **`fetch-binaries.sh`** - builder-stage script: downloads every pinned
  binary that has no reliable apt package (istioctl, velero, stern, herdr,
  k9s, dive, govc, yq, starship, eza, fzf, krew, the Carvel suite, and
  netshoot's own un-packaged extras - ctop, calicoctl, termshark, grpcurl,
  fortio, trippy, websocat).
- **`install-base.sh`** - base OS packages every image needs (curl, git, jq,
  bash-completion, vim, ...).
- **`install-network-tools.sh`** - the netshoot replacement: apt-installs
  the network/troubleshooting toolset netshoot used to supply for free, plus
  the `tshark`/`dumpcap` non-root-capture setup.
- **`install-shell-experience.sh`** - the interactive-shell layer (bat, eza,
  fd, tmux, direnv, docker's CLI, fzf-tab-completion, ...).
- **`install-k8s-tools.sh`** - `kubectl` via Kubernetes' own official apt
  repo (pkgs.k8s.io), pinned to an exact package version.
- **`install-vcf-cli.sh`** - `vcf-cli` via Broadcom's own official apt repo
  (packages.broadcom.com), pinned to an exact package version. Public repo,
  no auth needed for the base CLI (VCF CLI plugins are a separate,
  token-gated registry flow, not wired up yet).
- **`install-dotfiles.sh <home_dir> <owner:group>`** - installs the shared
  dotfiles bundle into one target home. This is the "user profile"/"root
  profile" step - called once per profile that needs it.
- **`dotfiles/`** - the actual `.bashrc`/`.bash_profile`/`.vimrc`/`.config`
  bundle both images bake in for every user/profile they create.

## Bumping a tool version

Edit the `VERSION`/`SHA256_AMD64`/`SHA256_ARM64` lines for that tool in
`versions.env`. Get a fresh checksum with:

```bash
curl -sL <url-for-that-arch-and-version> | shasum -a 256
```

Nothing else needs to change - `fetch-binaries.sh` derives every URL from
`versions.env` at build time for whichever `TARGETARCH` is building.
