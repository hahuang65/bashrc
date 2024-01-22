#!/usr/bin/env bash

if hash mise 2>/dev/null; then
  export MISE_ASDF_COMPAT=1
  eval "$(mise activate bash)"
fi
