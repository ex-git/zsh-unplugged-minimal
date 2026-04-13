# History helpers — convenient shortcuts for managing zsh history
#
# Usage:
#   hr              — Remove the last command from history
#   hr <n1> <n2> .. — Remove one or more entries by event number
#   hr <pattern>    — Remove all entries matching pattern
#   hr -n ...       — Dry-run: show what would be removed
#   hs <pattern>    — Search history for pattern (case-insensitive)
#   h               — Show history with line numbers (alias for history)

# Remove entries from history
hr() {
  # We intentionally DO NOT use 'emulate -L zsh' here because it sets HIST_LOCAL
  # which causes history modifications (like fc -p) to be undone when the function returns.

  local pattern event_num tmp cmd_text histfile dry_run=0
  local h_size="${HISTSIZE:-1000}"
  local s_size="${SAVEHIST:-1000}"
  local -a targets_to_remove

  histfile="${HISTFILE:-$HOME/.zsh_history}"

  # Check for dry-run flag
  if [[ "$1" == "-n" ]]; then
    dry_run=1
    shift
  fi

  # 1. Determine what we are removing
  if [[ -z "$1" ]]; then
    # No argument: remove last command
    event_num=$((HISTCMD - 1))
    if (( event_num < 1 )); then
      echo "History is empty" >&2
      return 1
    fi
    cmd_text=$(fc -l "$event_num" "$event_num" 2>/dev/null | sed 's/^[[:space:]]*[0-9]*[*[:space:]]*//')
    [[ -n "$cmd_text" ]] && targets_to_remove+=("$cmd_text")
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
    if [[ ${#targets_to_remove} -eq 0 ]]; then
      echo "No valid history entries found for the given event number(s)." >&2
      return 1
    fi
  else
    # Pattern argument
    pattern="$1"
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
  # This writes the current session history (including this 'hr' call) to the file.
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

    # Use perl to remove specific commands AND any 'hr' command calls.
    # We use -0777 to read the whole file for multi-line support.
    EXPORT_TARGETS="$target_list" perl -0777 -pe '
      BEGIN {
        foreach (split(/\n/, $ENV{EXPORT_TARGETS})) {
          $targets{$_} = 1;
        }
      }
      # 1. Remove specifically targeted commands
      s/^(?:: \d+:\d+;)?(.*?)\n/ exists $targets{$1} ? "" : $& /gme;

      # 2. Always remove any "hr" command calls to keep history clean
      s/^(?:: \d+:\d+;)?hr(?:\s+.*)?\n//gm;
    ' "$histfile" > "$tmp"
  else
    # Remove lines matching pattern, and also always filter out 'hr' calls
    grep -v -E "$pattern|^(: [0-9]+:[0-9]+;)?hr(\s+.*)?$" "$histfile" > "$tmp"
  fi

  # 5. Swap files and reload
  if mv "$tmp" "$histfile"; then
    # Clear current history and reload from the edited file.
    # This pushes a new history context loaded from the file we just cleaned.
    fc -p "$histfile" "$h_size" "$s_size"

    if [[ ${#targets_to_remove} -gt 0 ]]; then
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
hs() {
  local pattern
  if [[ -z "$1" ]]; then
    echo "Usage: hs <pattern>"
    return 1
  fi
  pattern="$1"
  # Search memory first, then file as fallback
  fc -li -m "*${pattern}*" 1 2>/dev/null || {
    grep -i -- "$pattern" "${HISTFILE:-$HOME/.zsh_history}" | sed 's/^: [0-9]*:[0-9]*;//'
  }
}

# Quick history view
alias h='history'

# Autocompletion for history helpers
_history_helpers_completion() {
  local curcontext="$curcontext" state line
  typeset -A opt_args

  case "$service" in
    hr)
      _arguments -C \
        '-n[Dry-run: show what would be removed]' \
        '*:history events:->events'

      if [[ "$state" == "events" ]]; then
        local -a history_list
        # Get last 20 history items for completion, formatted as "num:cmd"
        history_list=("${(@f)$(fc -l -20 | sed -E 's/^[[:space:]]*([0-9]+)\*?[[:space:]]+(.*)$/\1:\2/')}")
        _describe -t history-events 'history event' history_list
      fi
      ;;
    hs)
      _arguments '1:pattern:_history_complete_word'
      ;;
  esac
}

compdef _history_helpers_completion hr hs
