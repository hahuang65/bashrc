# bashrc

My personal configuration for the [Bourne-again Shell](https://tiswww.case.edu/php/chet/bash/bashtop.html)
I will do my best to comment the configuration file. Feel free to crib/steal this for your own personal use.

## Usage

Run `./install.sh` to link the configuration files to the proper location

## Word of the Day cache

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
