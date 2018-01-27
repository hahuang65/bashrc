if [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]]; then
  exec startx
fi

eval $(keychain --eval --quiet id_rsa)
