#!/usr/bin/env bash

# Run as a function to make sure functions/_*.bash are loaded first
_setup_wotd() {

  _fetch_wotd_url() {
    local -r url="$1"
    local -r connect_timeout_seconds=2
    local -r request_timeout_seconds=5

    \curl --fail --silent --location --compressed \
      --connect-timeout "$connect_timeout_seconds" \
      --max-time "$request_timeout_seconds" \
      "$url" 2>/dev/null
  }

  _fetch_wotd_description() {
    local -r feed_url="https://www.merriam-webster.com/wotd/feed/rss2"

    _fetch_wotd_url "$feed_url" |
      xmllint --xpath 'string((//item)[1]/description)' - 2>/dev/null
  }

  _extract_wotd_paragraph() {
    local -r paragraph_number="$1"

    xmllint --html --recover \
      --xpath "normalize-space((//p)[$paragraph_number])" - 2>/dev/null
  }

  _extract_dictionary_fields() {
    jq -r '
       def trim_whitespace:
         gsub("^\\s+|\\s+$"; "");

       .[0] |
       [
         (
           [.hwi.prs[]?.mw?]
           | map(select(type == "string") | trim_whitespace)
           | join(", ")
         ),
         (
           [.shortdef[]?]
           | map(select(type == "string") | trim_whitespace)
           | join("; ")
         )
       ] |
       @tsv
     ' 2>/dev/null
  }

  _define_word() {
    local -r dictionary_api_url="https://dictionaryapi.com/api/v3/references/collegiate/json"
    _fetch_wotd_url "$dictionary_api_url/${1}?key=${DICTIONARY_API_TOKEN}"
  }

  _trim() {
    local value=${1//$'\u00a0'/ }
    value=${value#"${value%%[![:space:]]*}"}
    value=${value%"${value##*[![:space:]]}"}
    printf '%s' "$value"
  }

  _print_wotd_lines() {
    local -r content_width="$1"
    local -r control_characters=$'[\001-\037\177]'
    local -a lines=("${@:2}") wrapped_lines
    local border line line_width padding card formatted_line

    # Strip controls in Bash, then wrap all lines with one fold process.
    mapfile -t wrapped_lines < <(
      printf '%s\n' "${lines[@]//$control_characters/}" |
        fold -s -w "$content_width"
    )

    printf -v border '%*s' "$((content_width + 2))" ''
    border=${border// /-}
    printf -v card '+%s+\n' "$border"

    for line in "${wrapped_lines[@]}"; do
      # Character counts alone do not give terminal widths for Unicode.
      line_width=$(wc -L <<<"$line")
      padding=$((content_width - line_width))
      ((padding < 0)) && padding=0
      printf -v formatted_line '| %s%*s |\n' "$line" "$padding" ''
      card+=$formatted_line
    done

    printf -v formatted_line '+%s+\n' "$border"
    card+=$formatted_line
    printf '%s' "$card"
  }

  _print_wotd_card() {
    local -n entry="$1"
    local -r content_width=72
    local -a lines=(
      '__        __      ____       _______      _____'
      '\ \      / /     / __ \     |__   __|    |  __ \'
      ' \ \ /\ / /     | |  | |       | |       | |  | |'
      '  \ V  V /      | |__| |       | |       | |__| |'
      '   \_/\_/        \____/        |_|       |_____/'
      ''
      "🌟 Word: ${entry[word]}"
      "🔊 Pronunciation: ${entry[pronunciation]}"
      "📚 Part of speech: ${entry[part_of_speech]}"
      "📖 Gloss: ${entry[gloss]}"
    )

    if [[ -n ${entry[definition]:-} ]]; then
      lines+=("📖 Definitions: ${entry[definition]}")
    fi

    _print_wotd_lines "$content_width" "${lines[@]}"
  }

  _render_wotd() {
    local -r metadata_paragraph_number=2
    local -r gloss_paragraph_number=3
    local -r metadata_separators=$'\u0095•'
    local description metadata gloss dictionary_response
    local word pronunciation part_of_speech
    local dictionary_pronunciations definitions

    if ! description="$(_fetch_wotd_description)" || [[ -z $description ]]; then
      return 0
    fi

    metadata="$(
      _extract_wotd_paragraph "$metadata_paragraph_number" <<<"$description"
    )" || return 0

    gloss="$(
      _extract_wotd_paragraph "$gloss_paragraph_number" <<<"$description"
    )" || return 0

    IFS="$metadata_separators" read -r word pronunciation part_of_speech <<<"$metadata"

    declare -A item=(
      [word]="$(_trim "$word")"
      [pronunciation]="$(_trim "$pronunciation")"
      [part_of_speech]="$(_trim "$part_of_speech")"
      [gloss]="$gloss"
    )
    [[ -n ${item[word]} && -n $gloss ]] || return 0

    if [[ -n ${DICTIONARY_API_TOKEN:-} ]] &&
      dictionary_response="$(_define_word "${item[word]}")" &&
      [[ -n $dictionary_response ]] &&
      IFS=$'\t' read -r dictionary_pronunciations definitions < <(
        _extract_dictionary_fields <<<"$dictionary_response"
      )
    then
      [[ -n $dictionary_pronunciations ]] &&
        item[pronunciation]="$dictionary_pronunciations"

      item[definition]="$definitions"
    fi

    _print_wotd_card item
  }

  _prepare_wotd_cache() {
    local -r directory="$1"

    [[ $directory == /* && ! -L $directory ]] || return 1
    if [[ ! -e $directory ]]; then
      mkdir -m 700 -- "$directory" 2>/dev/null || :
    fi
    [[ -d $directory && -O $directory && ! -L $directory ]] || return 1
    chmod 700 -- "$directory" 2>/dev/null
  }

  _save_wotd_cache() {
    local -r cache_file="$1" card="$2"
    local temporary_file

    [[ ! -L $cache_file && ! -d $cache_file ]] || return 1
    temporary_file=$(mktemp "${cache_file%/*}/.card.XXXXXX" 2>/dev/null) || return 1
    # mktemp already created this private file; allow this one overwrite.
    if ! printf '%s\n' "$card" >|"$temporary_file" ||
      ! mv -f -- "$temporary_file" "$cache_file" 2>/dev/null; then
      rm -f -- "$temporary_file"
      return 1
    fi
  }

  wotd() {
    local -r cache_directory="${TMPDIR:-/tmp}/wotd-$UID"
    local cache_day cache_file card
    local dictionary_mode=feed
    [[ -n ${DICTIONARY_API_TOKEN:-} ]] && dictionary_mode=dictionary
    printf -v cache_day '%(%F)T' -1
    cache_file="$cache_directory/$cache_day-$dictionary_mode.txt"

    if ! _prepare_wotd_cache "$cache_directory"; then
      _render_wotd
      return
    fi

    if [[ -f $cache_file && -O $cache_file && ! -L $cache_file ]] &&
      { card=$(<"$cache_file"); } 2>/dev/null && [[ -n $card ]]; then
      printf '%s\n' "$card"
      return
    fi

    if ! card=$(_render_wotd) || [[ -z $card ]]; then
      return 0
    fi
    _save_wotd_cache "$cache_file" "$card" || :
    printf '%s\n' "$card"
  }
}

_setup_wotd
unset -f _setup_wotd
