if [[ `uname` = "Darwin" ]]; then
  if [ -d $(brew --prefix)/etc/bash_completion.d ]; then
    for file in $(brew --prefix)/etc/bash_completion.d/*; do source $file; done
  fi
fi

# Case-insensitive completions
bind "set completion-ignore-case on"

# Treat - and _ as equivalent for completions
bind "set completion-map-case on"

# Show ambiguous matches with single tab instead of double
bind "set show-all-if-ambiguous on"
