#!/usr/bin/env bash

export FZF_CTRL_T_OPTS="
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"

export FZF_CTRL_R_OPTS="
  --preview 'echo {}' --preview-window up:3:hidden:wrap
  --bind 'ctrl-/:toggle-preview'
  --color header:italic"

export FZF_ALT_C_OPTS="--preview 'tree -C {}'"

if [ "$(uname)" = "Linux" ]; then
  source "/usr/share/fzf/completion.bash"
  source "/usr/share/fzf/key-bindings.bash"
elif [ "$(uname)" = "Darwin" ]; then
  if hash brew 2>/dev/null; then
    # $(brew --prefix) is slow, hard-coding /opt/homebrew instead.
    source "/opt/homebrew/opt/fzf/shell/completion.bash"
    source "/opt/homebrew/opt/fzf/shell/key-bindings.bash"
  fi
fi
