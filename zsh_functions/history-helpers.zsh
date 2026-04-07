# History helpers — single h command with flags
#
# Usage:
#   h -l [n]          — Show history with line numbers
#   h -s <pattern>    — Search history (case-insensitive)
#   h -r              — Remove the last command from history
#   h -r <n1> <n2> .. — Remove one or more entries by event number
#   h -r <pattern>    — Remove all entries matching pattern
#   h -r -n ...       — Dry-run: show what would be removed
#   h -h, --help      — Show help

_history_usage() {
  cat <<'EOF'
History helper

Usage:
  h -l [n]                        List history entries with line numbers
  h -s <pattern>                  Search history case-insensitively
  h -r                            Remove the most recent command from history
  h -r <n1> <n2> ..               Remove one or more entries by event number
  h -r <pattern>                  Remove all entries matching a pattern
  h -r -n [event_number...|text]  Preview what would be removed
  h -h | --help                   Show this help

Examples:
  h -l 10
  h -s docker
  h -r
  h -r 1234 1235
  h -r -n password
EOF
}

_history_list() {
  builtin history "$@"
}

# Remove entries from history
_history_remove() {
  # We intentionally DO NOT use 'emulate -L zsh' here because it sets HIST_LOCAL
  # which causes history modifications (like fc -p) to be undone when the function returns.

  local pattern event_num tmp cmd_text histfile dry_run=0
  local h_size="${HISTSIZE:-1000}"
  local s_size="${SAVEHIST:-1000}"
  local history_cleanup_regex='^(: [0-9]+:[0-9]+;)?h[[:space:]]+-r([[:space:]]+.*)?$'
  local -a targets_to_remove

  histfile="${HISTFILE:-$HOME/.zsh_history}"

  # Check for dry-run flag
  if [[ "$1" == "-n" ]]; then
    dry_run=1
    shift
  fi

  # 1. Determine what we are removing
  if [[ -z "$1" ]]; then
    # No argument: remove the most recent non-helper command.
    event_num=$HISTCMD
    while (( event_num >= 1 )); do
      cmd_text=$(fc -l "$event_num" "$event_num" 2>/dev/null | sed 's/^[[:space:]]*[0-9]*[*[:space:]]*//')
      if [[ -n "$cmd_text" && "$cmd_text" != h\ -r* ]]; then
        targets_to_remove+=("$cmd_text")
        break
      fi
      event_num=$((event_num - 1))
    done
    if (( ${#targets_to_remove[@]} == 0 )); then
      echo "History is empty" >&2
      return 1
    fi
  elif [[ "$1" == <-> ]]; then
    # Multiple numeric arguments: remove by event numbers
    local arg
    for arg in "$@"; do
      if [[ "$arg" == <-> ]]; then
        cmd_text=$(fc -l "$arg" "$arg" 2>/dev/null | sed 's/^[[:space:]]*[0-9]*[*[:space:]]*//')
        if [[ -n "$cmd_text" ]]; then
          targets_to_remove+=("$cmd_text")
        else
          echo "Warning: Event $arg not found" >&2
        fi
      else
        echo "Error: Mixed event numbers and patterns are not supported. Use one or the other." >&2
        return 1
      fi
    done
  else
    # Pattern argument
    pattern="$*"
  fi

  # 2. Dry-run feedback
  if (( dry_run )); then
    if [[ ${#targets_to_remove} -gt 0 ]]; then
      echo "Would remove:"
      printf '  %s\n' "${targets_to_remove[@]}"
    else
      echo "Would remove entries matching: $pattern"
    fi
    return 0
  fi

  # 3. Sync memory to file before editing
  # This writes the current session history (including this remove command) to the file.
  fc -W

  if [[ ! -f "$histfile" ]]; then
    echo "Error: History file not found: $histfile" >&2
    return 1
  fi

  tmp="${histfile}.tmp.$$"

  # 4. Perform removal in the file
  if [[ ${#targets_to_remove} -gt 0 ]]; then
    # Create a newline-separated list of exact commands to remove
    local target_list=$(printf '%s\n' "${targets_to_remove[@]}")

    # Use perl to remove specific commands AND any history-remove helper calls.
    # We use -0777 to read the whole file for multi-line support.
    EXPORT_TARGETS="$target_list" perl -0777 -pe '
      BEGIN {
        foreach (split(/\n/, $ENV{EXPORT_TARGETS})) {
          $targets{$_} = 1;
        }
      }
      # 1. Remove specifically targeted commands
      s/^(?:: \d+:\d+;)?(.*?)\n/ exists $targets{$1} ? "" : $& /gme;

      # 2. Always remove any history-remove helper calls to keep history clean
      s/^(?:: \d+:\d+;)?h\s+-r(?:\s+.*)?\n//gm;
    ' "$histfile" > "$tmp"
  else
    # Remove lines matching pattern, and also always filter out remove helper calls
    grep -v -E -- "$pattern|$history_cleanup_regex" "$histfile" > "$tmp"
  fi

  # 5. Swap files and reload
  if mv "$tmp" "$histfile"; then
    # Clear current history and reload from the edited file.
    # This pushes a new history context loaded from the file we just cleaned.
    fc -p "$histfile" "$h_size" "$s_size"

    if (( ${#targets_to_remove} == 1 )); then
      echo "Removed: ${targets_to_remove[1]}"
    elif (( ${#targets_to_remove} > 1 )); then
      echo "Removed ${#targets_to_remove} entries."
    elif [[ -n "$pattern" ]]; then
      echo "Removed entries matching: $pattern"
    fi
    return 0
  else
    rm -f "$tmp" 2>/dev/null
    echo "Error: Failed to update history file" >&2
    return 1
  fi
}

# Search history for pattern (case-insensitive)
_history_search() {
  local pattern
  if [[ $# -eq 0 ]]; then
    echo "Usage: h -s <pattern>" >&2
    return 1
  fi
  pattern="$*"
  # Search memory first, then file as fallback
  fc -li -m "*${pattern}*" 1 2>/dev/null || {
    grep -i -- "$pattern" "${HISTFILE:-$HOME/.zsh_history}" | sed 's/^: [0-9]*:[0-9]*;//'
  }
}

unalias h 2>/dev/null || true

h() {
  case "$1" in
    -l)
      shift
      _history_list "$@"
      ;;
    -s)
      shift
      _history_search "$@"
      ;;
    -r)
      shift
      _history_remove "$@"
      ;;
    -h|--help)
      _history_usage
      ;;
    "")
      _history_usage
      ;;
    *)
      echo "Unknown history option: $1" >&2
      _history_usage >&2
      return 1
      ;;
  esac
}

_history_recent_events() {
  fc -l -20 | sed -E 's/^[[:space:]]*([0-9]+)\*?[[:space:]]+(.*)$/\1:\2/'
}

_history_remove_completion() {
  local curcontext="$curcontext" state line
  typeset -A opt_args

  _arguments -C \
    '-n[Dry-run: show what would be removed]' \
    '*:history event or pattern:->events'

  if [[ "$state" == "events" ]]; then
    local -a history_list
    history_list=("${(@f)$(_history_recent_events)}")
    _describe -t history-events 'history event' history_list
  fi
}

# Autocompletion for history helper
_history_helpers_completion() {
  if (( CURRENT == 2 )); then
    _describe -t history-options 'history action' \
      '-l:show history with line numbers' \
      '-s:search history (case-insensitive)' \
      '-r:remove history entries' \
      '-h:show help' \
      '--help:show help'
    return
  fi

  case "${words[2]}" in
    -l)
      _message 'history count'
      ;;
    -s)
      _arguments '2:pattern:_history_complete_word'
      ;;
    -r)
      _history_remove_completion
      ;;
    -h|--help)
      ;;
    *)
      _message 'use: h {-l|-s|-r|-h}'
      ;;
  esac
}

compdef _history_helpers_completion h
