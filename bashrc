export PATH="$HOME/.rbenv/shims:/usr/local/bin:$PATH:$HOME/.scripts:$HOME/Documents/Projects/toolbox"

# Source  secret stuff
test -e "$HOME/.secrets.sh" && source "$HOME/.secrets.sh"

# Source OS-specific stuff
OS=`uname | tr '[:upper:]' '[:lower:]'`
test -e "$HOME/.dotfiles/bash/os/$OS.sh" && source "$HOME/.dotfiles/bash/os/$OS.sh"

source $HOME/.dotfiles/bash/aliases
for file in $HOME/.dotfiles/bash/customizations/*.bash; do source $file; done
for file in $HOME/.dotfiles/bash/functions/*.bash; do source $file; done
