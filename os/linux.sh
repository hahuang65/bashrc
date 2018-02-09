if [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]]; then
  exec startx
fi

eval $(keychain --eval --quiet id_rsa)

xset r rate 200 50

export BROWSER=google-chrome-stable
