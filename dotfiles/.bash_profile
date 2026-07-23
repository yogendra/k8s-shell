# Login shells (bash -l, some SSH/terminal configs, ...) don't source
# .bashrc on their own - only /etc/profile, which resets PATH and drops
# everything in .bashrc (krew, aliases, fzf, starship, tmux, ...). Make sure
# it loads either way.
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi
