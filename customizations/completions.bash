#!/usr/bin/env bash

if [ "$(uname)" = "Linux" ]; then
  [[ $PS1 && -f /usr/share/bash-completion/bash_completion ]] && . /usr/share/bash-completion/bash_completion
# Sourcing this is really slow, commenting out to see if I really use it
elif [ "$(uname)" = "Darwin" ]; then
  if hash brew 2>/dev/null; then
    # $(brew --prefix) is slow, hard-coding /opt/homebrew instead.
    [[ $PS1 && -f "/opt/homebrew/etc/profile.d/bash_completion.sh" ]] && . "/opt/homebrew/etc/profile.d/bash_completion.sh"
  fi
fi

# AWS completion
if hash aws_completer 2>/dev/null; then
  AWS_COMPLETER_PATH="$(\which aws_completer)"
  complete -C "${AWS_COMPLETER_PATH}" aws
  complete -C "${AWS_COMPLETER_PATH}" awsl
  complete -C "${AWS_COMPLETER_PATH}" awslocal
fi

# Only if the shell is interactive
if [[ $- == *i* ]]; then
  # Case-insensitive completions
  bind "set completion-ignore-case on"

  # Treat - and _ as equivalent for completions
  bind "set completion-map-case on"

  # Show ambiguous matches with single tab instead of double
  bind "set show-all-if-ambiguous on"
fi
