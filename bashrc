export PATH="$HOME/.rbenv/shims:/usr/local/bin:/usr/local/sbin:$HOME/.scripts:$HOME/Documents/Projects/toolbox:$PATH"

export EDITOR="vim"
export VISUAL="vim"
export NODE_PATH="/usr/local/lib/node"

# Source  secret stuff
test -e "$HOME/.secrets.sh" && source "$HOME/.secrets.sh"
OS=`uname | tr '[:upper:]' '[:lower:]'`
test -e "$HOME/.$OS.sh" && source "$HOME/.$OS.sh"

source $HOME/.dotfiles/bash/aliases
for file in $HOME/.dotfiles/bash/customizations/*.bash; do source $file; done
for file in $HOME/.dotfiles/bash/functions/*.bash; do source $file; done
