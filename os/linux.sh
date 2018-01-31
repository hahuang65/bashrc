if [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]]; then
  exec startx
fi

if [[ -z ${NO_KEYCHAIN+x} ]]; then
  eval $(keychain --eval --quiet id_rsa)
fi

xset r rate 200 50
