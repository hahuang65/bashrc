#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/support/wotd.bash"

repeated_calls_reuse_the_complete_card_without_fetching_or_formatting() {
  local first second
  first=$(wotd)
  assert_contains "$first" 'Word: pundit'

  _fetch_wotd_description() {
    printf 'Unexpected feed request\n' >>"$test_directory/unexpected"
    return 1
  }
  wc() {
    printf 'Unexpected formatting\n' >>"$test_directory/unexpected"
    command wc "$@"
  }

  second=$(wotd)
  assert_equal "$first" "$second"
  [[ ! -e $test_directory/unexpected ]]
}

a_new_shell_reuses_the_card() {
  local first second
  first=$(wotd)
  second=$(bash --noprofile --norc -c '
    source "$1"
    _fetch_wotd_description() { return 1; }
    wotd
  ' bash "$wotd_source")
  assert_equal "$first" "$second"
}

an_old_day_is_not_reused() {
  wotd >/dev/null
  mv "$cache_file" "$cache_directory/1900-01-01-feed.txt"
  assert_contains "$(wotd)" 'Word: pundit'
  assert_equal $'feed\nfeed' "$(<"$test_directory/requests")"
}

an_empty_cache_is_refetched() {
  mkdir -m 700 "$cache_directory"
  : >"$cache_file"
  assert_contains "$(wotd)" 'Word: pundit'
  [[ -s $cache_file ]]
}

a_failed_fetch_does_not_prevent_a_later_retry() {
  (
    _fetch_wotd_description() { return 1; }
    assert_equal '' "$(wotd)"
    [[ ! -e $cache_file ]]
  )
  assert_contains "$(wotd)" 'Word: pundit'
}

an_invalid_feed_is_not_cached() {
  (
    _fetch_wotd_description() { printf '<font><p>Incomplete feed</p></font>'; }
    assert_equal '' "$(wotd)"
    [[ ! -e $cache_file ]]
  )
  assert_contains "$(wotd)" 'Word: pundit'
}

dictionary_enrichment_has_a_separate_reusable_cache() {
  wotd >/dev/null
  export DICTIONARY_API_TOKEN=test-token
  _define_word() {
    printf 'dictionary\n' >>"$test_directory/dictionary_requests"
    printf '%s' '[{"hwi":{"prs":[{"mw":"PUN-dit"}]},"shortdef":["An expert."]}]'
  }

  local first second
  first=$(wotd)
  second=$(wotd)
  assert_contains "$first" 'Definitions: An expert.'
  assert_equal "$first" "$second"
  assert_equal dictionary "$(<"$test_directory/dictionary_requests")"
}

a_dictionary_failure_still_caches_the_feed_card() {
  export DICTIONARY_API_TOKEN=test-token
  _define_word() {
    printf 'dictionary\n' >>"$test_directory/dictionary_requests"
    return 1
  }
  local first second
  first=$(wotd)
  second=$(wotd)
  assert_contains "$first" 'Word: pundit'
  assert_equal "$first" "$second"
  assert_equal dictionary "$(<"$test_directory/dictionary_requests")"
}

an_unavailable_cache_does_not_suppress_the_card() {
  printf 'Not a directory\n' >"$cache_directory"
  assert_contains "$(wotd)" 'Word: pundit'
  assert_equal 'Not a directory' "$(<"$cache_directory")"
}

a_symlinked_directory_is_not_used() {
  mkdir "$test_directory/elsewhere"
  printf 'Untrusted card\n' >"$test_directory/elsewhere/${cache_file##*/}"
  ln -s "$test_directory/elsewhere" "$cache_directory"
  assert_contains "$(wotd)" 'Word: pundit'
  assert_equal 'Untrusted card' "$(<"$test_directory/elsewhere/${cache_file##*/}")"
}

a_symlinked_file_is_not_read_or_overwritten() {
  mkdir -m 700 "$cache_directory"
  printf 'Do not change\n' >"$test_directory/target"
  ln -s "$test_directory/target" "$cache_file"
  assert_contains "$(wotd)" 'Word: pundit'
  assert_equal 'Do not change' "$(<"$test_directory/target")"
}

cache_files_are_private_and_published_complete() {
  local -a leftovers
  mv() {
    [[ ! -e $cache_file ]] || return 1
    assert_contains "$(<"${@: -2:1}")" 'Word: pundit' || return 1
    command mv "$@"
  }
  umask 000
  wotd >"$test_directory/output"
  cmp "$test_directory/output" "$cache_file"
  # POSIX find permission checks work on both macOS and Linux.
  assert_equal '' "$(find "$cache_directory" -perm -004 -o -perm -040)"
  assert_equal '' "$(find "$cache_directory" -perm -002 -o -perm -020)"
  shopt -s nullglob
  leftovers=("$cache_directory"/.card.*)
  assert_equal 0 "${#leftovers[@]}"
}

a_failed_cache_write_does_not_suppress_the_card() {
  local -a leftovers
  mv() { return 1; }
  assert_contains "$(wotd)" 'Word: pundit'
  [[ ! -e $cache_file ]]
  shopt -s nullglob
  leftovers=("$cache_directory"/.card.*)
  assert_equal 0 "${#leftovers[@]}"
}

a_failed_temporary_file_allocation_does_not_suppress_the_card() {
  mktemp() { return 1; }
  assert_contains "$(wotd)" 'Word: pundit'
  [[ ! -e $cache_file ]]
}

the_cache_works_with_the_shells_noclobber_setting() {
  source "$(dirname "$wotd_source")/../customizations/redirection.bash"

  {
    wotd >"$test_directory/first"
    wotd >"$test_directory/second"
  } 2>"$test_directory/errors"

  assert_equal '' "$(<"$test_directory/errors")"
  assert_contains "$(<"$test_directory/first")" 'Word: pundit'
  cmp "$test_directory/first" "$cache_file"
  cmp "$test_directory/first" "$test_directory/second"
  assert_equal feed "$(<"$test_directory/requests")"
  [[ -o noclobber ]]
}

simultaneous_calls_publish_complete_cards() {
  local first_process second_process
  wotd >"$test_directory/first" &
  first_process=$!
  wotd >"$test_directory/second" &
  second_process=$!
  wait "$first_process"
  wait "$second_process"
  cmp "$test_directory/first" "$test_directory/second"
  cmp "$test_directory/first" "$cache_file"
}

run_test() (
  setup_wotd_test
  local cache_day cache_directory cache_file
  printf -v cache_day '%(%F)T' -1
  cache_directory="$TMPDIR/wotd-$UID"
  cache_file="$cache_directory/$cache_day-feed.txt"
  "$1"
)

run_test repeated_calls_reuse_the_complete_card_without_fetching_or_formatting
run_test a_new_shell_reuses_the_card
run_test an_old_day_is_not_reused
run_test an_empty_cache_is_refetched
run_test a_failed_fetch_does_not_prevent_a_later_retry
run_test an_invalid_feed_is_not_cached
run_test dictionary_enrichment_has_a_separate_reusable_cache
run_test a_dictionary_failure_still_caches_the_feed_card
run_test an_unavailable_cache_does_not_suppress_the_card
run_test a_symlinked_directory_is_not_used
run_test a_symlinked_file_is_not_read_or_overwritten
run_test cache_files_are_private_and_published_complete
run_test a_failed_cache_write_does_not_suppress_the_card
run_test a_failed_temporary_file_allocation_does_not_suppress_the_card
run_test simultaneous_calls_publish_complete_cards
run_test the_cache_works_with_the_shells_noclobber_setting
