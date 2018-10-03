export PATH="$HOME/.rbenv/shims:$PATH:$HOME/.scripts:$HOME/Documents/Projects/a5/toolbox"

if hash pyenv 2> /dev/null; then
  eval "$(pyenv init -)"
fi

# Source  secret stuff
test -e "$HOME/.secrets.sh" && source "$HOME/.secrets.sh"

# Source OS-specific stuff
OS=`uname | tr '[:upper:]' '[:lower:]'`
test -e "$HOME/.dotfiles/bash/os/$OS.sh" && source "$HOME/.dotfiles/bash/os/$OS.sh"

source $HOME/.dotfiles/bash/aliases
for file in $HOME/.dotfiles/bash/customizations/*.bash; do source $file; done
for file in $HOME/.dotfiles/bash/functions/*.bash; do source $file; done

# Remove duplicate entries in PATH
PATH=$(printf "%s" "$PATH" | awk -v RS=':' '!a[$1]++ { if (NR > 1) printf RS; printf $1 }')
