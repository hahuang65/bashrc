if [ -z $DISPLAY ] && [ "$(tty)" == "/dev/tty1" ]; then
  exec sway
fi

eval $(keychain --eval --quiet id_rsa)

export BROWSER=chromium
export QT_AUTO_SCREEN_SCALE_FACTOR=0
export PATH="$HOME/.local/bin:$PATH"
export TERMINAL=alacritty
