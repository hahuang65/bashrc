if hash bat 2> /dev/null; then
  export BAT_PAGER="less --raw-control-chars"
  alias cat="bat"

  function tail {
    command tail "$@" | bat --paging=never --language log
  }

  if hash batman 2> /dev/null; then
    alias man="batman"
  else
    export MANPAGER="sh -c 'col --no-backspaces --spaces | bat --language man --plain'"
  fi

  if hash batgrep 2> /dev/null; then
    alias rg="batgrep"
  fi
fi
