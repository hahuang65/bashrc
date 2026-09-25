#!/usr/bin/env bash

if [[ $- == *i* && -t 1 ]]; then
  _deferred_wotd() {
    local previous_status=$?
    local current_tty

    # Later prompts must not fetch or print another card.
    _deferred_wotd() { return "$?"; }
    current_tty=$(tty 2>/dev/null)
    if [[ -n $current_tty && ${WOTD_SHOWN_TTY:-} != "$current_tty" ]]; then
      export WOTD_SHOWN_TTY="$current_tty"
      wotd
    fi
    return "$previous_status"
  }

  _setup_wotd_prompt() {
    local hook
    for hook in "${PROMPT_COMMAND[@]-}"; do
      hook=${hook//$'\n'/;}
      [[ ";$hook;" == *";_deferred_wotd;"* ]] && return 0
    done

    # Print after all other startup work, immediately before the first prompt.
    # This avoids leaving a trailing empty row exposed to window resize/reflow.
    if [[ $(declare -p PROMPT_COMMAND 2>/dev/null) == 'declare -a'* ]]; then
      PROMPT_COMMAND+=(_deferred_wotd)
    else
      PROMPT_COMMAND=${PROMPT_COMMAND:-}
      PROMPT_COMMAND+=$'\n_deferred_wotd'
    fi
  }

  _setup_wotd_prompt
  unset -f _setup_wotd_prompt
fi
