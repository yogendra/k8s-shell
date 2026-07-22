# HOME may be stale (baked in for the `shell` user) if this shell was reached
# via `docker exec`/`kubectl exec --user root` on an already-running
# container, which never re-runs the entrypoint's own HOME fix. Re-resolve it
# here too so shell and root always land on their own, correct home dir.
if REAL_HOME="$(getent passwd "$(id -u)" 2>/dev/null | cut -d: -f6)" && [ -n "$REAL_HOME" ] && [ "$REAL_HOME" != "$HOME" ]; then
  export HOME="$REAL_HOME"
  cd "$HOME" || true
fi

# krew: the Docker-image ENV PATH addition doesn't survive a login shell -
# Alpine's /etc/profile unconditionally resets PATH before .bashrc ever runs.
[ -d /usr/local/krew/bin ] && [[ ":$PATH:" != *":/usr/local/krew/bin:"* ]] && \
  export PATH="/usr/local/krew/bin:$PATH"

source <(kubectl completion bash)
command -v helm >/dev/null 2>&1 && source <(helm completion bash)
command -v istioctl >/dev/null 2>&1 && source <(istioctl completion bash)

alias k="kubectl"

# get
alias kg="k get"
alias kgp="k get pods"
alias kgpa="k get pods --all-namespaces"
alias kgpw="k get pods -o wide"
alias kgd="k get deploy"
alias kgs="k get svc"
alias kgn="k get nodes"
alias kgns="k get namespaces"
alias kge="k get events --sort-by='.metadata.creationTimestamp' | tail -8"

# describe
alias kd="k describe"
alias kdp="k describe pod"
alias kdd="k describe deploy"
alias kds="k describe svc"

# logs / exec / apply / delete
alias kl="k logs"
alias klf="k logs -f"
alias kex="k exec -it"
alias kaf="k apply -f"
alias kdel="k delete"

# context / config
alias kctx="k config current-context"
alias kcuc="k config use-context"
alias kcgc="k config get-contexts"

# switch (or print) the namespace on the current context, kubens-style
kn() {
  if [ -z "${1:-}" ]; then
    kubectl config view --minify -o jsonpath='{..namespace}'; echo
  else
    kubectl config set-context --current --namespace="$1"
  fi
}

# tab-completion for every alias above, not just `k`/`kubectl`
complete -F __start_kubectl k kg kgp kgpa kgpw kgd kgs kgn kgns kge \
  kd kdp kdd kds kl klf kex kaf kdel kctx kcuc kcgc kn

export nks="-n kube-system"
export ETCDCTL_API=3
export k8s="https://k8s.io/examples"
function vaml()
{
vim -R -c 'set syntax=yaml' -;
}

# eza - modern ls replacement
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons'
  alias l='eza -lbF --git --icons'
  alias ll='eza -lbGF --git --icons'
  alias llm='eza -lbGd --git --sort=modified --icons'
  alias la='eza -lbhHigUmuSa --time-style=long-iso --git --color-scale --icons'
  alias lx='eza -lbhHigUmuSa@ --time-style=long-iso --git --color-scale --icons'
  alias lS='eza -1'
  alias lt='eza --tree --level=2'
  alias l.="eza -a | grep -E '^\.'"
fi

# bat - better cat
command -v bat >/dev/null 2>&1 && alias cat='bat --paging=never'

# fzf - fuzzy finder (Ctrl-R history, Ctrl-T files, Alt-C cd), fd + bat powered
if command -v fzf >/dev/null 2>&1; then
  export FZF_DEFAULT_OPTS="--height=40% --layout=reverse --border --padding=1 \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"

  if command -v fd >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  fi

  command -v bat >/dev/null 2>&1 && \
    export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range :500 {}'"

  # Ctrl-R (history search): ctrl-y copies the selected command via OSC 52
  # (see /usr/local/bin/osc52-copy) instead of pbcopy, which doesn't exist
  # here. ctrl-/ and alt-t below are fzf's own default binds, not custom.
  export FZF_CTRL_R_OPTS="--bind 'ctrl-y:execute-silent(echo -n {2..} | osc52-copy)+abort' \
--bind '?:toggle-preview' --nth=2.. \
--preview 'echo {}' \
--preview-window down:50%:wrap:nohidden \
--preview-label='| Preview |' \
--header 'ctrl-y: copy to clipboard | ?: toggle preview | alt-t: change view | ctrl-/: toggle wrap' \
--color header:italic"

  eval "$(fzf --bash)"
fi

# fzf-tab-completion - pipes ANY command's tab-completion candidates (kubectl
# resources, git branches, file paths, ...) through fzf, not just fzf's own
# Ctrl-R/Ctrl-T/Alt-C bindings above
if [ -f /usr/local/share/fzf-tab-completion/bash/fzf-bash-completion.sh ]; then
  source /usr/local/share/fzf-tab-completion/bash/fzf-bash-completion.sh
  bind -x '"\t": fzf_bash_completion'
fi

# direnv - per-directory env loading
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook bash)"

# starship - shell prompt
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi

# tmux - drop into a persistent session automatically on interactive shells.
# PS1 is not a reliable interactive check by itself - Alpine's /etc/profile
# sets a default PS1 even for non-interactive login shells (e.g.
# `bash -lc '...'`, as used by CI/task smoke), which would otherwise exec
# straight into tmux and hard-fail with "not a terminal" when there's no tty.
# `$-` reflects bash's real -i flag; pair it with an actual tty check too.
if [[ $- == *i* ]] && [ -t 0 ] && [ -t 1 ] && [ -z "$TMUX" ] && command -v tmux >/dev/null 2>&1; then
  exec tmux new-session -A -s main
fi
