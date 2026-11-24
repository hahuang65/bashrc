#!/usr/bin/env bash

export FZF_CTRL_T_OPTS="
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"

export FZF_CTRL_R_OPTS="
  --preview 'echo {}' --preview-window up:3:hidden:wrap
  --bind 'ctrl-/:toggle-preview'
  --color header:italic"

# Keep .config searchable, but do not descend into other hidden directories or clutter.
export FZF_ALT_C_COMMAND="find -L . -type d \( \
  -name '.*' ! -name . ! -name .config -o \
  -name node_modules -o -name __pycache__ -o -iname cache -o -iname caches \
  \) -prune -o -type d ! -name . -print 2>/dev/null"
export FZF_ALT_C_OPTS="--preview 'tree -C {}'"

if [[ $OSTYPE == linux-gnu* ]]; then
  _bashrc_fzf_completion_file=/usr/share/fzf/completion.bash
  source "/usr/share/fzf/key-bindings.bash"
elif [[ $OSTYPE == darwin* ]]; then
  if exists brew; then
    _bashrc_fzf_completion_file=/opt/homebrew/opt/fzf/shell/completion.bash
    source "/opt/homebrew/opt/fzf/shell/key-bindings.bash"
  fi
fi
