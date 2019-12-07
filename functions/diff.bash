function diff {
  git diff --no-index --color "$@" | diff-so-fancy | less --tabs=4 -RFX
}
