#!/usr/bin/env bash

# https://github.com/asdf-vm/asdf/issues/1115#issuecomment-1100806590
unset ASDF_DIR

if test -f /opt/asdf-vm/asdf.sh; then
  . /opt/asdf-vm/asdf.sh
elif hash brew 2>/dev/null; then
  if test -f "$(brew --prefix)/opt/asdf/asdf.sh"; then
    . "$(brew --prefix)/opt/asdf/asdf.sh"
  elif test -f "$(brew --prefix)/opt/asdf/libexec/asdf.sh"; then
    . "$(brew --prefix)/opt/asdf/libexec/asdf.sh"
  fi
fi
