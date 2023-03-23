if [ "$(uname)" = "Linux" ]; then
	source "/usr/share/fzf/completion.bash"
	source "/usr/share/fzf/key-bindings.bash"
elif [ "$(uname)" = "Darwin" ]; then
	source "/usr/local/opt/fzf/shell/completion.bash"
	source "/usr/local/opt/fzf/shell/key-bindings.bash"
fi
