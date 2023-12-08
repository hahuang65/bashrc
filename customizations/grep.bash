#!/usr/bin/env bash

if [ "$(uname)" = "Linux" ]; then
  export GREP_COLOR='mt=1;32'
elif [ "$(uname)" = "Darwin" ]; then
  export GREP_COLOR='1;32'
fi

alias grep='grep --color=auto'
