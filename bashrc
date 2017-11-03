export PATH="/usr/local/opt/coreutils/libexec/gnubin:/usr/local/bin:/usr/local/sbin:$HOME/.scripts:$HOME/.scripts/Fontpatcher:$HOME/.scripts/Geektool:$HOME/Documents/Projects/toolbox:$HOME/.rvm/bin:$PATH"

export EDITOR="vim"
export VISUAL="vim"
export NODE_PATH="/usr/local/lib/node"

# Source  secret stuff
test -e "$HOME/.secrets.sh" && source "$HOME/.secrets.sh"

source $HOME/.dotfiles/bash/aliases
for file in $HOME/.dotfiles/sh/functions/*.sh; do source $file; done
for file in $HOME/.dotfiles/sh/customizations/*.sh; do source $file; done
for file in $HOME/.dotfiles/bash/customizations/*.bash; do source $file; done
for file in $HOME/.dotfiles/bash/functions/*.bash; do source $file; done
