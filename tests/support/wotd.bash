#!/usr/bin/env bash

wotd_source="$(dirname "${BASH_SOURCE[0]}")/../../functions/wotd.bash"
source "$wotd_source"

setup_wotd_test() {
  test_directory=$(mktemp -d)
  trap 'rm -rf "$test_directory"' EXIT
  export TMPDIR="$test_directory"
  unset DICTIONARY_API_TOKEN
}

_fetch_wotd_description() {
  printf 'feed\n' >>"$test_directory/requests"
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

assert_equal() {
  if [[ $1 != "$2" ]]; then
    printf 'Expected:\n%s\nActual:\n%s\n' "$1" "$2" >&2
    return 1
  fi
}
