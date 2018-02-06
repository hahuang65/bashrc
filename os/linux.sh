if [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]]; then
  exec startx
fi

eval $(keychain --noask --eval --quiet id_rsa)

xset r rate 200 50
