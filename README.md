# Kubernetes Shell

This is a project to quickly setup client/workstation shell to work with kubernetes.
It can setup:

1. bashrc
1. vimrc
1. tmux config

## Usage - Docker

```bash
# For .bashrc
docker run --rm -it ghcr.io/yogendra/k8s-shell

# For .bashrc
docker run --rm -it ghcr.io/yogendra/k8s-shell .bashrc

# For help
docker run --rm -it ghcr.io/yogendra/k8s-shell help

```

- **--rm**: Remove container after running
- **-i**: Allow input (stdin)
- **-t**: Assign TTY. Get output from container


## Usage - Kubectl

```bash
# For .bashrc
kubectl run k8s-shell --restart=Never --rm -iqt --image ghcr.io/yogendra/k8s-shell

# For .bashrc
kubectl run k8s-shell --restart=Never --rm -iqt --image ghcr.io/yogendra/k8s-shell -- .bashrc

# For help
kubectl run k8s-shell --restart=Never --rm -iqt --image ghcr.io/yogendra/k8s-shell -- help

```

- **--restart=Never**: Create pod instead of deployment
- **--rm**: Remove pod afeter completion
- **-q**: Quiet, no output of events ("pod deleted")
- **-i**: Allow input. Required for `-t` option
- **-t**: Create TTY for the run. Required to get output

