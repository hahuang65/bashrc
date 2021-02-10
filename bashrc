export PATH="$HOME/.scripts:$HOME/.local/bin:$HOME/.emacs.d/bin:$PATH"
export GOPATH="$HOME/.go"

# Source  secret stuff
test -e "$HOME/.secrets.sh" && source "$HOME/.secrets.sh"

# Source OS-specific stuff
OS=$(uname | tr '[:upper:]' '[:lower:]')
test -e "$HOME/.dotfiles/bash/os/$OS.sh" && source "$HOME/.dotfiles/bash/os/$OS.sh"

if test -e "$HOME/.dotfiles"; then
  source $HOME/.dotfiles/bash/aliases
  for file in "$HOME"/.dotfiles/bash/customizations/*.bash; do source $file; done
  for file in "$HOME"/.dotfiles/bash/functions/*.bash; do source $file; done
fi

# Remove duplicate entries in PATH
PATH=$(printf "%s" "$PATH" | awk -v RS=':' '!a[$1]++ { if (NR > 1) printf RS; printf $1 }')
