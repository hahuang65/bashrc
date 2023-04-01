export GOPATH="$HOME/.go"
export PATH="$HOME/.scripts:$HOME/.local/bin:$GOPATH/bin:$PATH"

# Source  secret stuff
test -e "$HOME/.secrets.sh" && source "$HOME/.secrets.sh"

# Find the directory where .bashrc is symlinked to
BASHRC=$(readlink $HOME/.bashrc)
BASHRC_DIR=${BASHRC%/*}

# Source OS-specific stuff
OS=$(uname | tr '[:upper:]' '[:lower:]')
test -e "$BASHRC_DIR/os/$OS.sh" && source "$BASHRC_DIR/os/$OS.sh"

if test -e "$HOME/.dotfiles"; then
	source $BASHRC_DIR/aliases
	for file in "$BASHRC_DIR"/customizations/*.bash; do source $file; done
	for file in "$BASHRC_DIR"/functions/*.bash; do source $file; done
fi

# Remove duplicate entries in PATH
PATH=$(printf "%s" "$PATH" | awk -v RS=':' '!a[$1]++ { if (NR > 1) printf RS; printf $1 }')
