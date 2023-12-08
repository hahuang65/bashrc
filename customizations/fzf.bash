#!/usr/bin/env bash

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
