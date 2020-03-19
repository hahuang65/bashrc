if hash diff-so-fancy 2> /dev/null; then
  function diff {
    command diff -u "$@" | diff-so-fancy | less --tabs=4 -RFX
  }
fi
