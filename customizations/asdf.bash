if test -f /opt/asdf-vm/asdf.sh; then
  . /opt/asdf-vm/asdf.sh
elif test -f $(brew --prefix asdf)/asdf.sh; then
  . $(brew --prefix asdf)/asdf.sh
fi
