#!/bin/sh

ln -sf "${PWD}/bashrc" "${HOME}/.bashrc"
ln -sf "${PWD}/bash_profile" "${HOME}/.bash_profile"

# This just sets up some default Python packages to be installed with asdf-python (https://github.com/danhper/asdf-python)
ln -sf "${PWD}/customizations/asdf-python-packages" "${HOME}/.default-python-packages"
