#!/usr/bin/env bash

# A5 paths
export PATH="$PATH:$HOME/Projects/a5/toolbox"

# Homebrew paths
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:/opt/homebrew/opt/findutils/libexec/gnubin:/opt/homebrew/sbin:/opt/homebrew/bin:$PATH"

# Use 1Password's ssh agent
export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock

# Fix weechat stuck on "downloading list of scripts"
# https://github.com/weechat/weechat/issues/1723#issuecomment-1349115378
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
