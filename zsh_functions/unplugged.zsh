# zsh_unplugged
# from: https://github.com/mattmc3/zsh_unplugged

# Paths for state (under config root so they follow INSTALL_DIR)
STATE_DIR="${SHARED_ZSH_ROOT:-$HOME/.config/zsh}/.state"
LAST_UPGRADE_DATE_FILE="$STATE_DIR/last_plugins_upgrade.log"


# List of the Zsh plugins
plugins=(
  # plugins that you want loaded first
  sindresorhus/pure

  # plugins you want loaded last
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-history-substring-search

  # load these at hypersonic load speeds with zsh-defer
  romkatv/zsh-defer
  rupa/z
  MichaelAquilina/zsh-you-should-use
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-completions
)


# Ensure the directory exists
mkdir -p "$STATE_DIR"

# Function to check if the update should be run
function should_update() {
  local current_date last_upgrade_date days_since_last_run day_word

  # Determine OS-specific date formatting
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    get_date_epoch() {
      date -d "$1" +%s
    }
    current_date=$(date +%Y-%m-%d)
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    get_date_epoch() {
      date -j -f "%Y-%m-%d" "$1" +%s
    }
    current_date=$(date -j -f "%Y-%m-%d" "$(date +%Y-%m-%d)" "+%Y-%m-%d")
  else
    echo "Unsupported OS"
    return 0  # Assume update needed
  fi

  # Check if last upgrade file exists
  if [[ -f "$LAST_UPGRADE_DATE_FILE" ]]; then
    last_upgrade_date=$(<"$LAST_UPGRADE_DATE_FILE")

    # Calculate days since last run
    days_since_last_run=$(( ( $(get_date_epoch "$current_date") - $(get_date_epoch "$last_upgrade_date") ) / 86400 ))

    if (( days_since_last_run < 14 )); then
      day_word=$(( days_since_last_run == 1 )) && day_word="day" || day_word="days"
      echo "The last Zsh plugin update check was performed $days_since_last_run $day_word ago."
      return 1  # No update needed
    fi
  fi

  # Save current date
  echo "$current_date" > "$LAST_UPGRADE_DATE_FILE"
  return 0  # Update needed
}

# Call should_run_update and capture its result
if should_update; then
  update_is_needed=true
else
  update_is_needed=false
fi

## Clone a plugin, identify its init file, source it, and add it to your fpath.
function plugin-load {
  local repo plugdir initfile initfiles=()
  : ${ZPLUGINDIR:=${SHARED_ZSH_ROOT:-${ZDOTDIR:-$HOME/.config/zsh}}/plugins}
  for repo in $@; do
    plugdir=$ZPLUGINDIR/${repo:t}
    initfile=$plugdir/${repo:t}.plugin.zsh
    if [[ ! -d $plugdir ]]; then
      echo "Cloning $repo..."
      git clone -q --depth 1 --recursive --shallow-submodules \
        https://github.com/$repo $plugdir
    else
      # update the plugin
      if [ -d "$plugdir/.git" ] && $update_is_needed; then 
        echo "Updating $repo..."
        (git -C "$plugdir" pull > /dev/null 2>&1 &)
      fi
    fi
    if [[ ! -e $initfile ]]; then
      initfiles=($plugdir/*.{plugin.zsh,zsh-theme,zsh,sh}(N))
      (( $#initfiles )) || { echo >&2 "No init file found '$repo'." && continue }
      ln -sf $initfiles[1] $initfile
    fi
    fpath+=$plugdir
    (( $+functions[zsh-defer] )) && zsh-defer . $initfile || . $initfile
  done
}

# load lugins
plugin-load $plugins
