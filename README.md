# k8s-shell

Batteries-included container images for operating and troubleshooting
Kubernetes clusters, built on plain Ubuntu (no `nicolaka/netshoot`, no
Alpine) - a terminal image and a full browser-based desktop, sharing one set
of installation scripts so they never drift apart.

| Image | What it is | Directory |
|---|---|---|
| **k8s-shell** | A non-root terminal container: bash + tmux/herdr + kubectl/helm/istioctl/velero/k9s/stern/... + the full netshoot-equivalent network toolset, all `apt`/pinned-binary installed on `ubuntu:24.04`. | [`k8s-shell/`](k8s-shell) |
| **k8s-gui-shell** | The same tool/dotfile bundle, layered onto [linuxserver/webtop](https://docs.linuxserver.io/images/docker-webtop/)'s Ubuntu+XFCE desktop-in-a-browser, for when you want a full GUI (multiple terminals, a browser, file manager, ...) instead of just a shell. | [`k8s-gui-shell/`](k8s-gui-shell) |

See each image's own README for its full tool list, usage examples
(Docker/Kubernetes), and what's specific to that image.

## Why no netshoot/Alpine

Both images used to build `FROM nicolaka/netshoot`, an Alpine-based image,
purely to inherit its network-troubleshooting toolset for free. That made
the base OS, and a good chunk of the dependency footprint, dictated entirely
by an upstream project that pins almost nothing itself. Both images now
build from plain Ubuntu instead, and every tool netshoot used to supply is
installed explicitly - via `apt` where Ubuntu has a package, via a pinned
(checksum-verified) binary download where it doesn't. See
[`_common/README.md`](_common/README.md) for exactly how.

## Repo structure

```
.
├── _common/            # shared install scripts + dotfiles - see _common/README.md
│   ├── versions.env     # every pinned tool version + checksum, one source of truth
│   ├── lib.sh            # shared bash helpers
│   ├── fetch-binaries.sh # downloads pinned binaries with no apt equivalent
│   ├── install-*.sh      # one script per install concern (base/network/shell/k8s tools)
│   ├── install-dotfiles.sh
│   └── dotfiles/         # the .bashrc/.vimrc/tmux.conf/... bundle both images bake in
├── k8s-shell/           # terminal image - its own Dockerfile/Taskfile/k8s manifests/README
├── k8s-gui-shell/       # GUI desktop image - same shape as k8s-shell
├── Taskfile.yml         # this file - aggregates both images' tasks (see below)
└── .github/workflows/   # one workflow per image, each triggered by its own dir or _common/
```

Each image keeps its own `Dockerfile`, `Taskfile.yml`, `k8s/` manifests, and
GitHub Actions workflow - only `_common/` is shared. More images can be
added the same way: a new top-level directory with its own
`packaging/Dockerfile` that installs `_common`'s scripts, plus a workflow
that triggers on that directory or `_common/`.

## Building and testing

Requires [go-task](https://taskfile.dev). Every task can be run for a single
image (`task -d k8s-shell build`, or `task k8s-shell:build` from the repo
root) or for all images at once from the repo root:

```bash
task all:build     # build every image for your native platform, load into Docker
task all:smoke     # build + sanity-check every bundled tool in every image actually runs
task all:push      # build linux/amd64+linux/arm64 and push every image to its registry
task all:publish   # alias for all:push, used by CI
```

`task --list` shows every task, namespaced per image
(`k8s-shell:build`, `k8s-gui-shell:smoke`, ...) plus the `all:*` aggregates
above.

There's no separate unit-test suite - "testing" here means `smoke`: building
the image and exec-ing into it to confirm every bundled CLI tool actually
runs (`--version`/equivalent for each one). See each image's `Taskfile.yml`
for the exact list. `k8s-gui-shell`'s `smoke` bypasses webtop's `s6-overlay`
entrypoint to check tools without booting the whole desktop - verifying the
desktop/browser UI itself still needs a manual `docker run` + open-the-URL
check.

## Contributing

- **Bumping a tool version**: edit the `VERSION`/`SHA256_AMD64`/
  `SHA256_ARM64` lines for that tool in
  [`_common/versions.env`](_common/versions.env) - see that file's header
  comment for how to get a fresh checksum. Nothing else needs to change.
- **Adding a new tool**: apt-installable tools go in the relevant
  `_common/install-*.sh` script (network/shell-experience/k8s-tools); tools
  with no apt package get a pinned entry in `versions.env` plus a fetch
  step in `_common/fetch-binaries.sh`. Either way, run `task all:smoke`
  afterwards, and add the new tool to both images' `Taskfile.yml` `smoke`
  task so CI actually checks it.
- **Changing shared behavior** (dotfiles, an install script): a change
  under `_common/` affects both images - run `task all:build && task
  all:smoke` before pushing, since both images' CI workflows trigger on
  `_common/` changes and will fail together if something's broken.
- **Adding a new image**: copy the shape of `k8s-shell/` or
  `k8s-gui-shell/` (`packaging/Dockerfile` that installs `_common`'s
  scripts via the named `common` build context, `Taskfile.yml`, optionally
  `k8s/` manifests), add it to this root `Taskfile.yml`'s `includes:` and
  `all:*` tasks, and give it its own `.github/workflows/<name>-main.yml`
  path-filtered to that directory and `_common/`.
- Keep `README.md` files (this one and each image's own) in sync with
  actual behavior - they're the first thing referenced when something looks
  wrong.
