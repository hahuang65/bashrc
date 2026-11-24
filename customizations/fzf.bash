#!/usr/bin/env bash

export FZF_CTRL_T_OPTS="
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"

export FZF_CTRL_R_OPTS="
  --preview 'echo {}' --preview-window up:3:hidden:wrap
  --bind 'ctrl-/:toggle-preview'
  --color header:italic"

# Track physical targets so aliases cannot bypass the Library limits.
_bashrc_fzf_walk() {
  local path=$1 physical=$2 depth=$3 ancestors=$4 child target name
  [[ -d $path && -r $path && -x $path ]] || return 0
  name=${path##*/}
  case "$name" in
    .|.config|.dotfiles) ;;
    .*|Hoth|node_modules|__pycache__) return 0 ;;
    [cC][aA][cC][hH][eE]|[cC][aA][cC][hH][eE][sS]) return 0 ;;
  esac
  case "$physical/" in
    "$support/") (( depth == 0 )) || depth=1 ;;
    "$support/"*)
      [[ ${physical#"$support/"} != */* ]] || return 0
      depth=0 ;;
    "$library/") ;;
    "$library/"*) return 0 ;;
  esac
  case "$ancestors" in *"$newline$physical$newline"*) return 0 ;; esac
  [[ $path == . ]] || printf '%s\n' "$path"
  (( depth == 0 )) && return 0
  ancestors+="$physical$newline"
  if [[ $physical == "$library" ]]; then
    _bashrc_fzf_walk "$path/Application Support" "$support" 1 "$ancestors"
  else
    for child in "$path"/*; do
      [[ -d $child ]] || continue
      target="${physical%/}/${child##*/}"
      if [[ -L $child ]]; then
        target=$(CDPATH= cd -- "$child" 2>/dev/null && pwd -P) || continue
      fi
      _bashrc_fzf_walk "$child" "$target" "$((depth - 1))" "$ancestors"
    done
  fi
  return 0
}

_bashrc_fzf_directory_candidates() (
  shopt -s dotglob nullglob
  local library support newline=$'\n'
  # A non-directory sentinel keeps absent Library paths from matching candidates.
  library=$(CDPATH= cd -- "$HOME/Library" 2>/dev/null && pwd -P) || library=/dev/null
  support=$(CDPATH= cd -- "$HOME/Library/Application Support" 2>/dev/null && pwd -P) || support=/dev/null
  _bashrc_fzf_walk . "$(pwd -P)" -1 "$newline"
)
export -f _bashrc_fzf_walk _bashrc_fzf_directory_candidates
export FZF_ALT_C_COMMAND='bash -c _bashrc_fzf_directory_candidates'
export FZF_ALT_C_OPTS="--preview 'tree -C {}'"

if [[ $OSTYPE == linux-gnu* ]]; then
  _bashrc_fzf_completion_file=/usr/share/fzf/completion.bash
  source "/usr/share/fzf/key-bindings.bash"
elif [[ $OSTYPE == darwin* ]]; then
  if exists brew; then
    _bashrc_fzf_completion_file=/opt/homebrew/opt/fzf/shell/completion.bash
    source "/opt/homebrew/opt/fzf/shell/key-bindings.bash"
  fi
fi
