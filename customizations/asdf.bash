# https://github.com/asdf-vm/asdf/issues/1115#issuecomment-1100806590
unset ASDF_DIR

if test -f /opt/asdf-vm/asdf.sh; then
  . /opt/asdf-vm/asdf.sh
elif test -f /usr/local/opt/asdf/asdf.sh; then
  . /usr/local/opt/asdf/asdf.sh
elif test -f /usr/local/opt/asdf/libexec/asdf.sh; then
  . /usr/local/opt/asdf/libexec/asdf.sh
fi
