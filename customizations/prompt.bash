bash_prompt() {
  if [ "$?" == "0" ]; then
    echo -e '\e[0;32m$\033[0m '
  else
    echo -e '\e[0;31m$\033[0m '
  fi
}

export PROMPT_COMMAND='PS1=$(bash_prompt)'
