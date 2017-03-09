if [[ `uname` = "Darwin" ]]; then
  if [ -d $(brew --prefix)/etc/bash_completion.d ]; then
    for file in $(brew --prefix)/etc/bash_completion.d/*; do source $file; done
  fi
fi
