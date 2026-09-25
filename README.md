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

Run shell regression tests with Bash.
Run `python3 tests/test_completions.py` for the interactive completion tests, including both editing modes.
The tests that use installed completion packages are skipped when those optional packages are absent.

## Word of the Day cache

On a new terminal, the card prints after the other startup and prompt hooks, immediately before the first prompt.
This avoids leaving an empty row after the card while the terminal window is still resizing.
The card still appears only once per terminal; manual `wotd` calls are unchanged.

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
