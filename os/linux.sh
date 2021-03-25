if [ -z $DISPLAY ] && [ "$(tty)" == "/dev/tty1" ]; then
  exec sway
fi

eval $(keychain --eval --noask --quiet id_rsa)

export BROWSER=firefox
export PATH="$HOME/.local/bin:$PATH"
