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

  _print_wotd_card() {
    local -n entry="$1"
    local -r content_width=72
    local border raw_line line line_width padding

    printf -v border '%*s' "$((content_width + 2))" ''
    border=${border// /-}

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

    printf '+%s+\n' "$border"

    for raw_line in "${lines[@]}"; do
      raw_line="$(
        printf '%s' "$raw_line" |
          LC_ALL=C tr -d '\000-\037\177'
      )"

      while IFS= read -r line; do
        line_width=$(printf '%s' "$line" | wc -L)
        padding=$((content_width - line_width))
        ((padding < 0)) && padding=0

        printf '| %s%*s |\n' "$line" "$padding" ''
      done < <(printf '%s\n' "$raw_line" | fold -s -w "$content_width")
    done

    printf '+%s+\n' "$border"
  }

  wotd() {
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
    )"

    gloss="$(
      _extract_wotd_paragraph "$gloss_paragraph_number" <<<"$description"
    )"

    IFS="$metadata_separators" read -r word pronunciation part_of_speech <<<"$metadata"

    declare -A item=(
      [word]="$(_trim "$word")"
      [pronunciation]="$(_trim "$pronunciation")"
      [part_of_speech]="$(_trim "$part_of_speech")"
      [gloss]="$gloss"
    )

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
}

_setup_wotd
unset -f _setup_wotd
