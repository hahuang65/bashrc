#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/../functions/wotd.bash"

_fetch_wotd_description() {
  cat <<'HTML'
<font>
  <p>Word of the Day</p>
  <p><strong>pundit</strong> &#149; \PUN-dit\&nbsp; &#149; <em>noun</em></p>
  <p>A pundit presents opinions via the media.</p>
</font>
HTML
}

assert_contains() {
  local -r output="$1"
  local -r expected="$2"

  if [[ $output != *"$expected"* ]]; then
    printf 'Expected output to contain: %s\n\nActual output:\n%s\n' \
      "$expected" "$output" >&2
    return 1
  fi
}

unset DICTIONARY_API_TOKEN
output="$(wotd)"

assert_contains "$output" 'Word: pundit'
assert_contains "$output" 'Pronunciation: \PUN-dit\'
assert_contains "$output" 'Part of speech: noun'

assert_card_width() {
  local line width
  while IFS= read -r line; do
    width=$(printf '%s' "$line" | wc -L)
    if ((width != 76)); then
      printf 'Expected a 76-column card line, got %s: %s\n' "$width" "$line" >&2
      return 1
    fi
  done <<<"$1"
}

assert_card_width "$output"
assert_contains "$output" '|                                                                          |'

card_wraps_long_definitions_and_removes_terminal_controls() (
  export DICTIONARY_API_TOKEN=test-token
  _define_word() {
    printf '%s' '[{"hwi":{"prs":[{"mw":"PUN-dit"}]},"shortdef":["\u001bA person who offers opinions about subjects in the news, including politics, economics, culture, science, and international affairs. Unicode: café 漢字 e\u0301.","abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz"]}]'
  }

  output="$(wotd)"
  assert_card_width "$output"
  assert_contains "$output" 'Definitions: A person who offers opinions'
  assert_contains "$output" 'international affairs.'
  assert_contains "$output" $'café 漢字 e\u0301'
  if [[ $output == *$'\e'* ]]; then
    printf 'The card must not contain terminal escape characters.\n' >&2
    return 1
  fi
)

card_is_not_printed_until_formatting_is_complete() (
  local output_directory
  output_directory=$(mktemp -d)
  trap 'rm -rf "$output_directory"' EXIT

  # Observe stdout while a width measurement is still in progress.
  wc() {
    if [[ -s $output_directory/card ]]; then
      printf 'Partial card was visible during formatting.\n' >>"$output_directory/partial"
    fi
    command wc "$@"
  }

  wotd >"$output_directory/card"
  if [[ -e $output_directory/partial ]]; then
    printf 'Expected the complete card to appear only after formatting.\n' >&2
    return 1
  fi
  [[ -s $output_directory/card ]]
)

card_wraps_long_definitions_and_removes_terminal_controls
card_is_not_printed_until_formatting_is_complete
