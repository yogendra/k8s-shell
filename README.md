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

```bash
# Drop into the shell
docker run --rm -it ghcr.io/yogendra-avgo/k8s-shell

# Mount your kubeconfig so kubectl/helm/etc. can reach a real cluster
docker run --rm -it -v ~/.kube:/home/shell/.kube ghcr.io/yogendra-avgo/k8s-shell
```

## Usage - Kubernetes

One-shot pod:

```bash
kubectl run k8s-shell --restart=Never --rm -iqt \
  --image ghcr.io/yogendra-avgo/k8s-shell -- bash
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
kubectl exec -it deploy/k8s-shell -- bash
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
