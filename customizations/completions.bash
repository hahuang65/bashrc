if [ "$(uname)" = "Linux" ]; then
	[[ $PS1 && -f /usr/share/bash-completion/bash_completion ]] && . /usr/share/bash-completion/bash_completion
elif [ "$(uname)" = "Darwin" ]; then
	[[ $PS1 && -f /usr/local/etc/bash_completion ]] && . /usr/local/etc/bash_completion
fi

# Only if the shell is interactive
if [[ $- == *i* ]]; then
	# Case-insensitive completions
	bind "set completion-ignore-case on"

	# Treat - and _ as equivalent for completions
	bind "set completion-map-case on"

	# Show ambiguous matches with single tab instead of double
	bind "set show-all-if-ambiguous on"
fi
