#!/usr/bin/env bash

_setup_mise() {
  if exists mise; then
    if [ "$(uname)" = "Darwin" ]; then
      export MISE_ASDF_COMPAT=1
    fi

    eval "$(mise activate bash)"
  fi
}

_setup_mise
unset -f _setup_mise
