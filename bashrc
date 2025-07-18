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
  local pattern="$1"
  local exclude=""

  # Check if --exclude is provided
  if [[ "$2" == "--exclude" ]]; then
    exclude="$3"
  fi

  for i in $pattern; do
    # Skip if file matches exclusion
    if [[ -n "$exclude" && "$(basename "$i")" == "$exclude" ]]; then
      continue
    fi
    source_file "$i"
  done
}

initialize() {
  export PATH="$HOME/.scripts:$HOME/.local/bin:$GOPATH/bin:$PATH"

  # Source  secret stuff
  test -e "$HOME/.secrets.sh" && source_file "$HOME/.secrets.sh"

  # Find the directory where .bashrc is symlinked to
  BASHRC=$(readlink "$HOME"/.bashrc)
  BASHRC_DIR=${BASHRC%/*}

  if test -e "$HOME/.dotfiles"; then
    source_dir "$BASHRC_DIR/functions/*.bash" # Load first so helper functions (_*.bash files) are already loaded
    source_file "$BASHRC_DIR/aliases"
    source_dir "$BASHRC_DIR/customizations/*.bash" --exclude "direnv.bash"
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
