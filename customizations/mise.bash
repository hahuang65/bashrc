#!/usr/bin/env bash

if hash mise 2>/dev/null; then
  if [ "$(uname)" = "Darwin" ]; then
    export MISE_ASDF_COMPAT=1
  fi

  eval "$(mise activate bash)"
fi
