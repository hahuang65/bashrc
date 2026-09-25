#!/usr/bin/env bash

set -euo pipefail

bashrc_source="$(dirname "$0")/../bashrc"

write_fixture() {
  local -r relative_path="$1" label="$2"
  printf 'printf "%%s\\n" %q >>"$STARTUP_EVENTS"\n' "$label" \
    >"$configuration_directory/$relative_path"
}

setup_startup_test() {
  test_directory=$(mktemp -d)
  trap 'rm -rf "$test_directory"' EXIT
  export HOME="$test_directory/home"
  export STARTUP_EVENTS="$test_directory/events"
  configuration_directory="$HOME/.dotfiles/bashrc"
  mkdir -p "$configuration_directory/functions" "$configuration_directory/customizations"
  cp "$bashrc_source" "$configuration_directory/bashrc"
  ln -s "$configuration_directory/bashrc" "$HOME/.bashrc"
  : >"$STARTUP_EVENTS"

  write_fixture functions/_helper.bash helper
  write_fixture functions/command.bash command
  write_fixture aliases aliases
  write_fixture customizations/10-first.bash first
  write_fixture customizations/20-direnv.bash similar-name
  write_fixture customizations/direnv.bash direnv
  write_fixture customizations/z-last.bash last
}

assert_load_order() {
  local -r expected=$'helper\ncommand\naliases\nfirst\nsimilar-name\nlast\ndirenv'
  local actual
  actual=$(<"$STARTUP_EVENTS")
  if [[ $actual != "$expected" ]]; then
    printf 'Expected load order:\n%s\nActual:\n%s\n' "$expected" "$actual" >&2
    return 1
  fi
}

startup_loads_helpers_first_and_direnv_last() {
  BENCHMARK=0 bash --noprofile --norc "$HOME/.bashrc"
  assert_load_order
}

exclusion_does_not_require_the_basename_command() {
  BENCHMARK=0 bash --noprofile --norc -c '
    basename() { return 1; }
    source "$1"
  ' bash "$HOME/.bashrc"
  assert_load_order
}

benchmark_mode_preserves_the_same_load_order() {
  BENCHMARK=1 bash --noprofile --norc "$HOME/.bashrc" 2>"$test_directory/timings"
  assert_load_order
  [[ $(<"$test_directory/timings") == *'Total: '* ]]
}

run_test() (
  setup_startup_test
  "$1"
)

run_test startup_loads_helpers_first_and_direnv_last
run_test exclusion_does_not_require_the_basename_command
run_test benchmark_mode_preserves_the_same_load_order
