# bashrc

My personal configuration for the [Bourne-again Shell](https://tiswww.case.edu/php/chet/bash/bashtop.html)
I will do my best to comment the configuration file. Feel free to crib/steal this for your own personal use.

## Usage

Run `./install.sh` to link the configuration files to the proper location

## Shell startup

The configuration loader uses Bash's built-in filename operations to avoid extra processes.
The fallback prompt queries Git before rendering and shows either the branch or the detached commit.
Redraws reuse the prepared label without running Git again.
Starship still controls the prompt when it is installed.

The shared completion libraries load when a command first needs them.
That first request includes the loading cost, but does not require an extra Tab press.
Bash completion loads before fzf completion so their handlers work together.
Fzf key bindings, AWS completion, and the custom Git completion are available immediately.
The fzf Alt+C directory picker fuzzy-matches the full path.
It hides dot-directories except `.config` and `.dotfiles`.
Directories named `Hoth` and their contents are excluded from traversal.
Within `~/Library`, only `Application Support` and its immediate child directories are listed.
Other Library contents and deeper application data are not traversed.
This limit also applies when starting inside Library or following symlinks to it or its descendants.
It also skips `node_modules`, `__pycache__`, and directories named `cache` or `caches` (case-insensitive).
The filter prunes these directories and their contents without changing Ctrl+T or Ctrl+R.

`customizations/worktree.bash` loads the AI installer's `~/.local/share/ai-config/bash/wt.bash` fragment in new shells.
It sources the fragment only when it is readable and `~/.local/bin/wt` is executable.
The loader uses Bash built-ins and does not run WT during startup.
Missing files are silently ignored, and existing command behavior stays unchanged.
The fragment supplies both `wt` and `worktree` functions for directory switching.
The AI installer owns the fragment link, while this repository owns the startup loader.
Login shells load it through the existing `.bash_profile` → `.bashrc` path.
Existing shells need to source the fragment after installation to enable the functions.

Run shell regression tests with Bash, including `bash tests/test_startup.sh` for startup order and the guarded WT loader.
Run `python3 tests/test_completions.py` for the interactive completion tests, including both editing modes.
Run `python3 tests/test_fzf.py` for Alt+C directory filtering.
The tests that use installed completion packages are skipped when those optional packages are absent.

## Word of the Day cache

Shell startup does not display a Word of the Day card.
Run `wotd` manually to display it.

`wotd` saves the complete card in `${TMPDIR:-/tmp}/wotd-$UID/YYYY-MM-DD-feed.txt`.
When `DICTIONARY_API_TOKEN` is set, it uses a separate `YYYY-MM-DD-dictionary.txt` file.
Repeated calls read the saved card without network requests or formatting.
The date follows the local calendar day, so the first call on a new day fetches a new card.

The cache directory is private to your user, and files are published only after the card is complete.
If the cache is unavailable, `wotd` still fetches and prints the card.
Failed feed requests and incomplete feed entries are not cached.
If only the dictionary request fails, the card from the feed is cached for that day.

Delete the day's cache file to force a fresh request.
Temporary files can be removed by the operating system; the next call recreates the cache.
