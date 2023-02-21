if [ -z "$DISPLAY" ] && [ "$(tty)" == "/dev/tty1" ]; then
	if command -v sway; then
		exec "$HOME/.dotfiles/sway/launch-sway"
	elif command -v Hyprland; then
		exec "$HOME/.dotfiles/hyprland/launch-hyprland"
	else
		echo "No configured WM/DMs installed"
	fi
fi

# Removing, in favor of using 1Password's ssh agent
# eval $(keychain --eval --noask --quiet id_ed25519 id_rsa)
export SSH_AUTH_SOCK=~/.1password/agent.sock

alias open="xdg-open"

# export BROWSER=google-chrome-stable
export BROWSER=google-chrome-stable
export PATH="$HOME/.local/bin:$PATH"
