# OS-X installation with Homebrew
[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"

# Case-insensitive completions
bind "set completion-ignore-case on"

# Treat - and _ as equivalent for completions
bind "set completion-map-case on"

# Show ambiguous matches with single tab instead of double
bind "set show-all-if-ambiguous on"
