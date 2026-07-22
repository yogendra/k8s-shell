# Kubernetes Shell

A batteries-included, non-root container for working with Kubernetes clusters.
It's built on [nicolaka/netshoot](https://github.com/nicolaka/netshoot) and adds:

- **Cluster tools**: kubectl, helm, istioctl, velero, k9s, stern, yq, govc
- **Image tools**: dive
- **Shell**: bash, tmux (with [tpm](https://github.com/tmux-plugins/tpm) and
  tmux-sensible/resurrect/continuum vendored in, ready to go), fzf, starship,
  vim, git, jq
- **herdr** (AI agent terminal multiplexer)

Dotfiles live in [`src/`](src) and are baked into the image at
`/home/shell/.bashrc`, `.vimrc`, `.tmux.conf`.

The image runs as a non-root user (`shell`, uid 1000) by default. Netshoot's
raw-socket tools (`tcpdump`, `nmap` SYN scans, ...) need root/`CAP_NET_RAW` -
run with `--user root` (Docker) or add the capability in your pod's
`securityContext` if you need those.

## Usage - Docker

The image's `ENTRYPOINT` is tmux itself: with no command override it
creates (or re-attaches to) a `main` tmux session, so you always land back
in the same place.

```bash
# One-shot: attach straight into tmux, container dies when you detach/exit
docker run --rm -it -v ~/.kube:/home/shell/.kube ghcr.io/yogendra-avgo/k8s-shell

# Long-running: start it once, hop in and out over time without losing state
docker run -d --name k8s-shell -v ~/.kube:/home/shell/.kube ghcr.io/yogendra-avgo/k8s-shell
docker exec -it k8s-shell tmux attach -t main
# <prefix>-d to detach - the container (and your session) keeps running
```

Passing an explicit command bypasses tmux entirely, e.g.
`docker run --rm ghcr.io/yogendra-avgo/k8s-shell kubectl version --client`.

## Usage - Kubernetes

One-shot pod:

```bash
kubectl run k8s-shell --restart=Never --rm -iqt \
  --image ghcr.io/yogendra-avgo/k8s-shell
```

- **--restart=Never**: Create a pod instead of a deployment
- **--rm**: Remove the pod after the run
- **-q**: Quiet, no event output ("pod deleted")
- **-i**: Allow input, required for `-t`
- **-t**: Allocate a TTY

Standing deployment you can `exec` into whenever you need it, running fully
non-privileged (non-root, no capabilities, read-only root filesystem -
see [`k8s/deployment.yaml`](k8s/deployment.yaml) for details):

```bash
kubectl apply -f k8s/deployment.yaml
kubectl exec -it deploy/k8s-shell -- tmux attach -t main
```

## Using curl

Grab just the dotfiles onto your own host, no Docker required:

```bash
curl -sSL https://raw.githubusercontent.com/yogendra-avgo/k8s-shell/main/src/.bashrc >> ~/.bashrc

curl -sSL https://raw.githubusercontent.com/yogendra-avgo/k8s-shell/main/src/.vimrc >> ~/.vimrc

curl -sSL https://raw.githubusercontent.com/yogendra-avgo/k8s-shell/main/src/.tmux.conf >> ~/.tmux.conf
```

## Building locally

Tasks are defined in [`Taskfile.yml`](Taskfile.yml) (requires
[go-task](https://taskfile.dev)):

```bash
task build   # build for your native platform and load it into Docker
task smoke   # build + sanity-check every bundled tool actually runs
task push    # build linux/amd64+linux/arm64 and push to the registry
```

## CI/CD

`.github/workflows/main.yml` builds and smoke-tests every push/PR, and on
pushes to `main` (or a `v*` tag) publishes multi-arch images to
`ghcr.io/yogendra-avgo/k8s-shell` tagged `:latest` and `:sha-<commit>`.
