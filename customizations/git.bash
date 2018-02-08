# Makes git auto completion faster favouring for local completions
__git_files () {
  _wanted files expl 'local files' _files
}

# If `hub` is installed, use that over vanilla `git`
if [ -x "$(command -v hub)" ]; then
  alias git=hub
fi
