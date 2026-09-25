#!/usr/bin/env bash

set -euo pipefail

prompt_source="$(dirname "$0")/../customizations/prompt.bash"

assert_contains() {
  [[ $1 == *"$2"* ]] || {
    printf 'Expected %q to contain %q\n' "$1" "$2" >&2
    return 1
  }
}

setup_prompt_test() {
  PROMPT_COMMAND='existing_hook'
  exists() { return 1; }
  git() {
    case "$*" in
      'symbolic-ref --short -q HEAD')
        [[ -n ${test_branch:-} ]] || return 1
        printf '%s\n' "$test_branch"
        ;;
      'rev-parse --short HEAD')
        [[ -n ${test_commit:-} ]] || return 128
        printf '%s\n' "$test_commit"
        ;;
      *) return 1 ;;
    esac
  }
  source "$prompt_source"
}

an_attached_branch_is_shown_without_git_aliases() {
  test_branch=hh/example
  prompt_command
  assert_contains "${PS1@P}" '[ hh/example] '
}

a_detached_head_shows_the_short_commit() {
  test_commit=abc1234
  prompt_command
  assert_contains "${PS1@P}" '[ abc1234] '
}

outside_git_the_prompt_has_no_branch_label() {
  prompt_command
  [[ ${PS1@P} != *''* ]]
}

the_prompt_updates_when_the_branch_changes() {
  test_branch=first
  prompt_command
  assert_contains "${PS1@P}" '[ first] '
  test_branch=second
  prompt_command
  assert_contains "${PS1@P}" '[ second] '
}

redrawing_the_prompt_does_not_repeat_git_queries() {
  test_branch=first
  prompt_command
  # A redraw must reuse the prepared label, not execute commands inside PS1.
  git() { printf 'unexpected-query\n'; }
  assert_contains "${PS1@P}" '[ first] '
}

branch_text_is_not_executed_as_shell_code() {
  test_branch='$(printf${IFS}INJECTED)'
  prompt_command
  assert_contains "${PS1@P}" '[ $(printf${IFS}INJECTED)] '
}

the_previous_exit_status_controls_the_prompt_color() {
  set +e
  false
  prompt_command
  set -e
  assert_contains "$PS1" "$red"
  true
  prompt_command
  assert_contains "$PS1" "$green"
}

existing_prompt_hooks_are_preserved_without_duplicates() {
  source "$prompt_source"
  [[ $PROMPT_COMMAND == 'prompt_command;existing_hook' ]]
}

starship_remains_responsible_for_its_own_prompt() {
  exists() { [[ $1 == starship ]]; }
  starship() { printf "PS1='starship prompt'\n"; }
  source "$prompt_source"
  [[ $PS1 == 'starship prompt' ]]
}

run_test() (
  setup_prompt_test
  "$1"
)

run_test an_attached_branch_is_shown_without_git_aliases
run_test a_detached_head_shows_the_short_commit
run_test outside_git_the_prompt_has_no_branch_label
run_test the_prompt_updates_when_the_branch_changes
run_test redrawing_the_prompt_does_not_repeat_git_queries
run_test branch_text_is_not_executed_as_shell_code
run_test the_previous_exit_status_controls_the_prompt_color
run_test existing_prompt_hooks_are_preserved_without_duplicates
run_test starship_remains_responsible_for_its_own_prompt
