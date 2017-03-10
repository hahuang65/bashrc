export PATH="/usr/local/opt/coreutils/libexec/gnubin:/usr/local/bin:/usr/local/sbin:$HOME/.scripts:$HOME/.scripts/Fontpatcher:$HOME/.scripts/Geektool:$HOME/Documents/Projects/toolbox:$HOME/.rvm/bin:$PATH"

export EDITOR="nvim"
export VISUAL="nvim"
export NODE_PATH="/usr/local/lib/node"

# Homebrew Cask
export HOMEBREW_CASK_OPTS="--caskroom=/usr/local/Caskroom"

# Source  secret stuff
test -e "$HOME/.dotfiles/shell/secrets.sh" && source "$HOME/.dotfiles/shell/secrets.sh"

source $HOME/.dotfiles/shell/bash/aliases
for file in $HOME/.dotfiles/shell/sh/functions/*.sh; do source $file; done
for file in $HOME/.dotfiles/shell/sh/customizations/*.sh; do source $file; done
for file in $HOME/.dotfiles/shell/bash/customizations/*.bash; do source $file; done
for file in $HOME/.dotfiles/shell/bash/functions/*.bash; do source $file; done
