if [ -z $DISPLAY ] && [ "$(tty)" == "/dev/tty1" ]; then
  exec sway
fi

# Removing, in favor of using 1Password's ssh agent
# eval $(keychain --eval --noask --quiet id_ed25519 id_rsa)
export SSH_AUTH_SOCK=~/.1password/agent.sock

alias open="xdg-open"

# export BROWSER=google-chrome-stable
export BROWSER=firefox
export PATH="$HOME/.local/bin:$PATH"
