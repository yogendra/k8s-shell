# Kubernetes Shell

A batteries-included, non-root container for working with Kubernetes clusters.
It's built on [nicolaka/netshoot](https://github.com/nicolaka/netshoot) and adds:

- **Cluster tools**: kubectl (completion + `k` alias wired up), helm, istioctl,
  velero, k9s, stern, yq, govc
- **Image tools**: dive
- **Shell**: bash, tmux (with [tpm](https://github.com/tmux-plugins/tpm) and
  tmux-sensible/resurrect/continuum vendored in, ready to go), fzf, starship,
  eza, bat, fd, tree, direnv, vim, git, jq
- **herdr** (AI agent terminal multiplexer)

Dotfiles live in [`src/`](src) and are baked into the image at
`~/.bashrc`, `.vimrc`, `.tmux.conf`, `.config/starship.toml` - for both the
default non-root user and root (see below), so the experience is the same
either way. `ls`/`l`/`ll`/`la`/`lt`/... are aliased to eza, `cat` to bat, and
fzf's file/history search is fd + bat powered, mirroring a typical local
zsh setup. The starship prompt (Catppuccin, kubernetes context always shown)
needs a [Nerd Font](https://www.nerdfonts.com) in *your* terminal to render
its icons correctly - that's a client-side setting the container can't
provide.

The image runs as a non-root user (`shell`, uid 1000) by default. Netshoot's
raw-socket tools (`tcpdump`, `nmap` SYN scans, ...) need root/`CAP_NET_RAW` -
run with `--user root` (Docker) or add the capability in your pod's
`securityContext` if you need those; root gets the identical dotfiles/prompt/
tmux setup too.

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

## Network debugging in a restricted Kubernetes environment

Clusters that enforce the `restricted`/`baseline` [Pod Security
Standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
at the namespace level block the raw sockets `tshark`/`tcpdump` need.
`kubectl debug` can attach this image to a running pod as an ephemeral
container sharing another container's network namespace (`--target`), but
only once the namespace is temporarily loosened to `privileged`.

```bash
NS=your-namespace
POD=your-pod

# 1. Force the namespace security profile to Privileged to allow raw network sniffing
kubectl label --overwrite ns "$NS" pod-security.kubernetes.io/enforce=privileged

# 2. Spin up the debug container named 'k8s-shell' using this image
kubectl debug -it -n "$NS" pods/"$POD" \
  --image=ghcr.io/yogendra-avgo/k8s-shell \
  --container=k8s-shell \
  --target=istio-proxy \
  --profile=netadmin \
  --custom=<(echo '{"securityContext":{"runAsNonRoot":false,"runAsUser":0}}') \
  -- tshark -i any -f "tcp port 8091" -w /tmp/outbound_8091.pcapng
```

Stop the capture with `Ctrl-C`, then from your local terminal:

```bash
# 3. Download the raw pcap file to your current working directory
kubectl cp "${NS}/${POD}":/tmp/outbound_8091.pcapng ./outbound_8091.pcapng -c k8s-shell

# 4. Restore the namespace's security boundary
kubectl label --overwrite ns "$NS" pod-security.kubernetes.io/enforce=baseline
```

**Don't rely on remembering step 4.** While the namespace is at
`privileged`, that relaxation applies to *any* pod scheduled into it, not
just this debug container - and if your session drops (SSH disconnect,
laptop sleep, a second `Ctrl-C`) between steps 1 and 4, it's left there
until someone notices. Wrap the whole thing in a trap so the label is
restored no matter how the session ends, and so it's restored to whatever
level the namespace actually had before - not a hardcoded guess:

```bash
#!/usr/bin/env bash
set -euo pipefail

NS=your-namespace
POD=your-pod

PREVIOUS_LEVEL=$(kubectl get ns "$NS" -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}')
PREVIOUS_LEVEL=${PREVIOUS_LEVEL:-baseline}

cleanup() {
  echo "Restoring ${NS} to pod-security.kubernetes.io/enforce=${PREVIOUS_LEVEL}"
  kubectl label --overwrite ns "$NS" "pod-security.kubernetes.io/enforce=${PREVIOUS_LEVEL}"
}
trap cleanup EXIT

kubectl label --overwrite ns "$NS" pod-security.kubernetes.io/enforce=privileged

kubectl debug -it -n "$NS" pods/"$POD" \
  --image=ghcr.io/yogendra-avgo/k8s-shell \
  --container=k8s-shell \
  --target=istio-proxy \
  --profile=netadmin \
  --custom=<(echo '{"securityContext":{"runAsNonRoot":false,"runAsUser":0}}') \
  -- tshark -i any -f "tcp port 8091" -w /tmp/outbound_8091.pcapng

kubectl cp "${NS}/${POD}":/tmp/outbound_8091.pcapng ./outbound_8091.pcapng -c k8s-shell
```

`trap cleanup EXIT` fires on normal exit, `Ctrl-C`, and a dropped
connection alike.

## Using curl

Grab just the dotfiles onto your own host, no Docker required:

```bash
curl -sSL https://raw.githubusercontent.com/yogendra-avgo/k8s-shell/main/src/.bashrc >> ~/.bashrc

curl -sSL https://raw.githubusercontent.com/yogendra-avgo/k8s-shell/main/src/.vimrc >> ~/.vimrc

curl -sSL https://raw.githubusercontent.com/yogendra-avgo/k8s-shell/main/src/.tmux.conf >> ~/.tmux.conf

curl -sSL https://raw.githubusercontent.com/yogendra-avgo/k8s-shell/main/src/starship.toml -o ~/.config/starship.toml
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

## Acknowledgements

Built on top of [nicolaka/netshoot](https://github.com/nicolaka/netshoot)
by [@nicolaka](https://github.com/nicolaka) - the base image that provides
most of the network debugging toolset (`tshark`, `tcpdump`, `nmap`, `iproute2`,
...) this image builds on.
