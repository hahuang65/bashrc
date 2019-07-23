function diff {
  git diff --no-index --color "$@" | diff-so-fancy | bat
}
