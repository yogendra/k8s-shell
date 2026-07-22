source <(kubectl completion bash)
complete -F __start_kubectl k
alias k="kubectl"
alias kgd="k get deploy"
alias kgp="k get pods"
alias kgn="k get nodes"
alias kgs="k get svc"
alias kge="k get events — sort-by='.metadata.creationTimestamp' |tail -8"
export nks="-n kube-system"
export ETCDCTL_API=3
export k8s="https://k8s.io/examples"
function vaml()
{
vim -R -c 'set syntax=yaml' -;
}

# fzf - fuzzy finder (Ctrl-R history, Ctrl-T files, Alt-C cd)
if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --bash)"
fi

# starship - shell prompt
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi

# tmux - drop into a persistent session automatically on interactive shells
if [[ -z "$TMUX" && -n "$PS1" ]] && command -v tmux >/dev/null 2>&1; then
  exec tmux new-session -A -s main
fi
