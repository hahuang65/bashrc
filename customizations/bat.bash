if hash bat 2> /dev/null; then
  alias cat="bat"

  if hash batman 2> /dev/null; then
    alias man="batman"
  else
    export MANPAGER="sh -c 'col -bx | bat --language man --plain --pager=\"less --raw-control-chars\"'"
  fi

  if hash batgrep 2> /dev/null; then
    alias rg="batgrep"
  fi
fi
