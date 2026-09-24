#!/usr/bin/env bash

if [[ $- == *i* && -t 1 ]]; then
  current_tty=$(tty 2>/dev/null)

  if [[ -n $current_tty &&
    ${WOTD_SHOWN_TTY:-} != "$current_tty" ]]; then
    export WOTD_SHOWN_TTY="$current_tty"
    wotd
  fi

  unset current_tty
fi
