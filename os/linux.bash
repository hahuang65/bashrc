#!/usr/bin/env bash

if [ -z "$DISPLAY" ] && [ "$(tty)" == "/dev/tty1" ]; then
  if command -v sway >/dev/null 2>&1; then
    if pacman -Qi nvidia >/dev/null; then
      exec "$HOME/.dotfiles/sway/launch-nvidia-sway"
    else
      exec sway
    fi
  else
    echo "No configured WM/DMs installed"
  fi
fi

if command -v pkgfile >/dev/null 2>&1; then
  source /usr/share/doc/pkgfile/command-not-found.bash
fi

# Removing, in favor of using 1Password's ssh agent
# eval $(keychain --eval --noask --quiet id_ed25519 id_rsa)
export SSH_AUTH_SOCK=~/.1password/agent.sock

alias open="xdg-open"

export BROWSER=vivaldi
export PATH="$HOME/.local/bin:$PATH"
