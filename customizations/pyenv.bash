if hash pyenv 2>/dev/null; then
  eval "$(pyenv init -)"
fi

# If installing Python gives trouble regarding SSL libs on MacOS
# BEWARE: $(brew --prefix) is slow, hard-code the directory where possible.
# export CFLAGS="-I$(xcrun --show-sdk-path)/usr/include"
# export CFLAGS="-I$(brew --prefix readline)/include $CFLAGS"
# export LDFLAGS="-L$(brew --prefix readline)/lib $LDFLAGS"
# export CFLAGS="-I$(brew --prefix openssl)/include $CFLAGS"
# export LDFLAGS="-L$(brew --prefix openssl)/lib $LDFLAGS"
# export CFLAGS="-I$(brew --prefix sqlite)/include $CFLAGS"
# export LDFLAGS="-L$(brew --prefix sqlite)/lib $LDFLAGS"
