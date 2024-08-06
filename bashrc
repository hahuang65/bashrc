#!/usr/bin/env bash

source_file() {
  if [[ $BENCHMARK == 1 ]]; then
    time {
      . "$1"
      TIMEFORMAT="$1: %Rs"
    }
  else
    . "$1"
  fi
}

source_dir() {
  for i in $1; do
    source_file "$i"
  done
}

initialize() {
  export GOPATH="$HOME/.go"
  export PATH="$HOME/.scripts:$HOME/.local/bin:$GOPATH/bin:$PATH"

  # Source  secret stuff
  test -e "$HOME/.secrets.sh" && source_file "$HOME/.secrets.sh"

  # Find the directory where .bashrc is symlinked to
  BASHRC=$(readlink "$HOME"/.bashrc)
  BASHRC_DIR=${BASHRC%/*}

  # Source OS-specific stuff
  OS=$(uname | tr '[:upper:]' '[:lower:]')
  test -e "$BASHRC_DIR/os/$OS.bash" && source_file "$BASHRC_DIR/os/$OS.bash"

  if test -e "$HOME/.dotfiles"; then
    source_file "$BASHRC_DIR"/aliases
    source_dir "$BASHRC_DIR/customizations/*.bash"
    source_dir "$BASHRC_DIR/functions/*.bash"
    source_file "$BASHRC_DIR/customizations/direnv.bash" # Has to happen after all other prompt manipulations
  fi

  # Remove duplicate entries in PATH
  PATH=$(printf "%s" "$PATH" | awk -v RS=':' '!a[$1]++ { if (NR > 1) printf RS; printf $1 }')
}

if [[ $BENCHMARK == 1 ]]; then
  time {
    initialize
    TIMEFORMAT="Total: %Rs"
  }
  exit 0
else
  initialize
fi
