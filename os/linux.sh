if [ -z $DISPLAY ] && [ "$(tty)" == "/dev/tty1" ]; then
  exec sway
fi

eval $(keychain --eval --noask --quiet id_rsa)

alias open="xdg-open"

export BROWSER=google-chrome-stable
export PATH="$HOME/.local/bin:$PATH"
