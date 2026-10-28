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
  cp "${bashrc_source%/*}/customizations/worktree.bash" "$configuration_directory/customizations/"
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

install_wt_fixture() {
  mkdir -p "$HOME/.local/bin" "$HOME/.local/share/ai-config/bash"
  printf '%s\n' '#!/bin/sh' 'printf "wt-process\\n" >>"$STARTUP_EVENTS"; exit 1' \
    >"$HOME/.local/bin/wt"
  chmod +x "$HOME/.local/bin/wt"
  printf '%s\n' \
    'wt() { printf "installed wt\\n"; }' \
    'worktree() { printf "installed worktree\\n"; }' \
    >"$HOME/.local/share/ai-config/bash/wt.bash"
}

new_shell_loads_the_installer_owned_wt_fragment() {
  install_wt_fixture
  local output
  output=$(BENCHMARK=0 BASH_ENV= ENV= bash --noprofile --norc -c '
    source "$HOME/.bashrc"
    if ! declare -F wt >/dev/null || ! declare -F worktree >/dev/null; then
      printf "Expected WT functions from the installed fragment\\n" >&2
      exit 1
    fi
    wt
    worktree
  ' 2>"$test_directory/stderr") || {
    printf '%s\n' "$(<"$test_directory/stderr")" >&2
    return 1
  }
  [[ $output == $'installed wt\ninstalled worktree' ]]
  [[ ! -s "$test_directory/stderr" ]]
  assert_load_order
}

assert_existing_wt_behavior() {
  local output
  output=$(BENCHMARK=0 BASH_ENV= ENV= bash --noprofile --norc -c '
    wt() { printf "existing wt\\n"; }
    worktree() { printf "existing worktree\\n"; }
    source "$HOME/.bashrc"
    wt
    worktree
  ' 2>"$test_directory/stderr")
  [[ $output == $'existing wt\nexisting worktree' ]]
  [[ ! -s "$test_directory/stderr" ]]
  assert_load_order
}

missing_fragment_preserves_existing_commands_quietly() {
  install_wt_fixture
  rm "$HOME/.local/share/ai-config/bash/wt.bash"
  assert_existing_wt_behavior
}

missing_executable_preserves_existing_commands_quietly() {
  install_wt_fixture
  rm "$HOME/.local/bin/wt"
  assert_existing_wt_behavior
}

nonexecutable_wt_preserves_existing_commands_quietly() {
  install_wt_fixture
  chmod -x "$HOME/.local/bin/wt"
  assert_existing_wt_behavior
}

unreadable_fragment_preserves_existing_commands_quietly() {
  install_wt_fixture
  chmod 000 "$HOME/.local/share/ai-config/bash/wt.bash"
  if [[ -r "$HOME/.local/share/ai-config/bash/wt.bash" ]]; then
    printf 'SKIP: this user can read a mode-000 fragment\n' >&2
    return
  fi
  assert_existing_wt_behavior
}

login_shell_loads_the_fragment_through_bash_profile() {
  install_wt_fixture
  cp "${bashrc_source%/*}/bash_profile" "$HOME/.bash_profile"
  local output
  output=$(BENCHMARK=0 BASH_ENV= ENV= bash --login -c '
    shopt -q login_shell || exit 1
    if ! declare -F wt >/dev/null || ! declare -F worktree >/dev/null; then
      printf "Expected WT functions through .bash_profile\\n" >&2
      exit 1
    fi
    wt
    worktree
  ' 2>"$test_directory/stderr") || {
    printf '%s\n' "$(<"$test_directory/stderr")" >&2
    return 1
  }
  [[ $output == $'installed wt\ninstalled worktree' ]]
  [[ ! -s "$test_directory/stderr" ]]
  assert_load_order
}

run_test() (
  setup_startup_test
  "$1"
)

run_test startup_loads_helpers_first_and_direnv_last
run_test exclusion_does_not_require_the_basename_command
run_test benchmark_mode_preserves_the_same_load_order
run_test new_shell_loads_the_installer_owned_wt_fragment
run_test missing_fragment_preserves_existing_commands_quietly
run_test missing_executable_preserves_existing_commands_quietly
run_test nonexecutable_wt_preserves_existing_commands_quietly
run_test unreadable_fragment_preserves_existing_commands_quietly
run_test login_shell_loads_the_fragment_through_bash_profile
