export PATH="$PATH:$HOME/Documents/Projects/a5/toolbox:$HOME/Documents/Projects/a5/dockerfiles/scripts"

if hash brew 2>/dev/null; then
	export PATH="$(brew --prefix)/opt/coreutils/libexec/gnubin:$(brew --prefix)/opt/findutils/libexec/gnubin:$PATH:$(brew --prefix)/sbin:$(brew --prefix)/bin"
fi

alias restart_bt='sudo pkill bluetoothd'

# Use 1Password's ssh agent
export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
