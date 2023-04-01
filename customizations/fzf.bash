if [ "$(uname)" = "Linux" ]; then
	source "/usr/share/fzf/completion.bash"
	source "/usr/share/fzf/key-bindings.bash"
elif [ "$(uname)" = "Darwin" ]; then
	if hash brew 2>/dev/null; then
		source "$(brew --prefix)/opt/fzf/shell/completion.bash"
		source "$(brew --prefix)/opt/fzf/shell/key-bindings.bash"
	fi
fi
