# Completes history expansion
# e.g. typing `!!<space>` will replace it with the last command
bind Space:magic-space

# Don't clobber history, just append to it
# To be clear, this only helps when using multiple shells in parallel
# Since history is written on shell exit and each shell is only aware of it's own history
shopt -s histappend

# Save multi-line commands as a single command
shopt -s cmdhist

# Larger history size
HISTSIZE=500000
HISTFILESIZE=100000

# Ignore duplicates in history
HISTCONTROL=ignoreboth:erasedups

# Don't record some commands in history
export HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear"
