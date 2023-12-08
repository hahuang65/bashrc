#!/usr/bin/env bash

if [ ! -z "$VIM" ]; then
  # Emacs mode in vim/nvim because vi-mode in vim/nvim terminal has issues.
  # Otherwise, .inputrc sets vi-mode.
  set -o emacs
fi

if hash nvim 2>/dev/null; then
  export EDITOR="nvim"
  export VISUAL="nvim"
  alias vim=nvim
elif hash emacsclient 2>/dev/null; then
  export ALTERNATE_EDITOR=""
  export EDITOR="emacsclient --create-frame"
  export VISUAL="emacsclient --create-frame --alternate-editor=emacs"
  alias emacs="emacsclient --create-frame --alternate-editor=emacs"
else
  export EDITOR="vim"
  export VISUAL="vim"
fi
