#!/usr/bin/env bash

if [[ -x "$HOME/.local/bin/wt" &&
      -r "$HOME/.local/share/ai-config/bash/wt.bash" ]]; then
  source "$HOME/.local/share/ai-config/bash/wt.bash"
fi
