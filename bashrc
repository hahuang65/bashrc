#!/usr/bin/env bash

export GOPATH="$HOME/.go"
export PATH="$HOME/.scripts:$HOME/.local/bin:$GOPATH/bin:$PATH"

source_file() {
  if [[ $BENCHMARK == 1 ]]; then
    TIMEFORMAT="$(basename "$(dirname "$1")")/$(basename "$1"): %Rs"
    time . "$1"
    unset TIMEFORMAT
  else
    . "$1"
  fi
}

source_dir() {
  for i in $1; do
    source_file "$i"
  done
  unset i
}

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
fi

# Remove duplicate entries in PATH
PATH=$(printf "%s" "$PATH" | awk -v RS=':' '!a[$1]++ { if (NR > 1) printf RS; printf $1 }')

if [[ $BENCHMARK == 1 ]]; then
  exit 0
fi
