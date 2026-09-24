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
