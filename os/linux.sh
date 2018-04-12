if [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]]; then
  exec startx
fi

eval $(keychain --eval --quiet id_rsa)

export BROWSER=chromium
export QT_AUTO_SCREEN_SCALE_FACTOR=0
