if hash emacsclient 2> /dev/null; then
  export ALTERNATE_EDITOR=""
  export EDITOR="emacsclient --tty"
  export VISUAL="emacsclient --tty --alternate-editor=emacs"
  alias emacs="emacsclient --tty --alternate-editor=emacs"
else
  export EDITOR="vim"
  export VISUAL="vim"
fi
