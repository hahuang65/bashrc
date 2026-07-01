MARKPATH=$HOME/.marks

function _mark_exists {
  if [ ! -d "$MARKPATH/$1" ]; then
    echo "No such mark: $1" >&2
    return 1
  fi
}

function jump {
  _mark_exists "$1" || return 1
  cd -P "$MARKPATH/$1" || return
}

function jump_in {
  _mark_exists "$1" || return 1
  cd "$MARKPATH/$1/$(find -L "$MARKPATH/$1" -mindepth 1 -maxdepth 1 -type d ! -name '.*' -exec basename {} \; | pick)" || return
}

function mark {
  mkdir -p "$MARKPATH"
  ln -s "$(pwd)" "$MARKPATH/$1"
}

function unmark {
  _mark_exists "$1" || return 1
  rm -i "$MARKPATH/$1"
}

function marks {
  for link in "$MARKPATH"/*; do
    [ -L "$link" ] || continue
    printf '%s -> %s\n' "$(basename "$link")" "$(readlink "$link")"
  done
}

alias j="jump"
alias jj="jump_in"

_completemarks() {
  local curw=${COMP_WORDS[COMP_CWORD]}
  local marknames
  mapfile -t marknames < <(find "$MARKPATH" -type l -exec basename {} \;)
  mapfile -t COMPREPLY < <(compgen -W "${marknames[*]}" -- "$curw")
  return 0
}

complete -F _completemarks jump jump_in unmark j jj
