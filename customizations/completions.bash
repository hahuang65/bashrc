if [ "$(uname)" = "Linux" ]; then
  [[ $PS1 && -f /usr/share/bash-completion/bash_completion ]] && . /usr/share/bash-completion/bash_completion
elif [ "$(uname)" = "Darwin" ]; then
  if hash brew 2>/dev/null; then
    # $(brew --prefix) is slow, hard-coding /opt/homebrew instead.
    [[ $PS1 && -f "opt/homebrew/etc/bash_completion" ]] && . "opt/homebrew/etc/bash_completion"
  fi
fi

# AWS completion
if hash aws_completer 2>/dev/null; then
  complete -C "$(\which aws_completer)" aws
  complete -C "$(\which aws_completer)" awsl
  complete -C "$(\which aws_completer)" awslocal
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
