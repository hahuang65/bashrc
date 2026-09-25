#!/usr/bin/env bash

_setup_prompt() {
  if exists starship; then
    eval "$(starship init bash)"
  else
    # Colors
    blue="\[\e[0;34m\]"
    green="\[\e[1;32m\]"
    red="\[\e[1;31m\]"
    reset="\[\e[m\]"

    _git_prompt() {
      local reference
      reference=$(git symbolic-ref --short -q HEAD 2>/dev/null ||
        git rev-parse --short HEAD 2>/dev/null) || return 0
      printf '[ %s] ' "$reference"
    }

    prompt_command() {
      local status="$?"
      local status_color=""
      if [ $status != 0 ]; then
        status_color=$red
      else
        status_color=$green
      fi
      # Finish Git queries before Readline renders or redraws the prompt.
      _bashrc_git_prompt_label=$(_git_prompt)
      # Variable expansion displays the label without executing its contents.
      PS1="${blue}\${_bashrc_git_prompt_label}${reset}${status_color}\$${reset} "
      export PS1
    }

    if [[ ! ";${PROMPT_COMMAND};" == *";prompt_command;"* ]]; then
      export PROMPT_COMMAND="prompt_command;${PROMPT_COMMAND}"
    fi
  fi
}

_setup_prompt
unset -f _setup_prompt
