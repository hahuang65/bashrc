#!/usr/bin/env bash

if [[ $OSTYPE == linux-gnu* ]]; then
  open() { xdg-open "$@"; }
  export -f open
fi
