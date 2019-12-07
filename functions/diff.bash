function diff {
  command diff -u "$@" | diff-so-fancy | less --tabs=4 -RFX
}
