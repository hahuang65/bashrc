#!/usr/bin/env bash

export MISE_ASDF_COMPAT=1
# Add shims to the path so non-interactive processes (such as `nvim`)
# can fallback on shims, while interactive ttys enjoy the speed bonus
# of not using shims.
export PATH="$HOME/.local/share/mise/shims:$PATH"
eval "$(mise activate bash)"
