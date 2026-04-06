# zsh_unplugged
# from: https://github.com/mattmc3/zsh_unplugged

# $EPOCHSECONDS is a zsh builtin — no date(1) forks needed
zmodload zsh/datetime 2>/dev/null

# State tracking for auto-update
ZPLUGIN_UPDATE_DAYS=${ZPLUGIN_UPDATE_DAYS:-14}
_zplugin_state_dir="${SHARED_ZSH_ROOT:-$HOME/.config/zsh}/.state"
_zplugin_upgrade_file="$_zplugin_state_dir/last_plugins_upgrade.log"
[[ -d "$_zplugin_state_dir" ]] || mkdir -p "$_zplugin_state_dir"

_zplugin_needs_update=1
_zplugin_update_ok=1
if [[ -f "$_zplugin_upgrade_file" ]]; then
  _zplugin_last=$(<"$_zplugin_upgrade_file")
  # Gracefully handles old YYYY-MM-DD format: non-integer → triggers update
  if [[ "$_zplugin_last" == <-> ]] \
    && (( EPOCHSECONDS - _zplugin_last < ZPLUGIN_UPDATE_DAYS * 86400 )); then
    _zplugin_needs_update=0
  fi
  unset _zplugin_last
fi
(( _zplugin_needs_update )) && echo "It's been a while — let's check for zsh plugin updates."

plugins=(
  # prompt — loaded first, synchronously
  sindresorhus/pure

  # interactive helpers — synchronous
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-history-substring-search

  # deferred plugins — loaded async after prompt renders
  romkatv/zsh-defer
  rupa/z
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-completions
)

: ${ZPLUGINDIR:=${SHARED_ZSH_ROOT:-${ZDOTDIR:-$HOME/.config/zsh}}/plugins}

# Prune plugin dirs that are no longer in the plugins list
(( _zplugin_needs_update )) && () {
  local plugdir name expected=()
  for repo in $plugins; do expected+=(${repo:t}); done
  for plugdir in "$ZPLUGINDIR"/*(N/); do
    name=${plugdir:t}
    if [[ -d "$plugdir/.git" ]] && (( ! ${expected[(Ie)$name]} )); then
      echo "Removing unlisted plugin: $name"
      rm -rf "$plugdir"
    fi
  done
}

## Clone a plugin, identify its init file, source it, and add it to fpath.
function plugin-load {
  local repo plugdir initfile
  local -a initfiles

  for repo in "$@"; do
    plugdir=$ZPLUGINDIR/${repo:t}
    initfile=$plugdir/${repo:t}.plugin.zsh

    if [[ ! -d $plugdir ]]; then
      echo "Cloning $repo..."
      if ! git clone -q --depth 1 --recursive --shallow-submodules \
        https://github.com/$repo "$plugdir"; then
        echo >&2 "Failed to clone $repo"
        _zplugin_update_ok=0
        continue
      fi
    elif (( _zplugin_needs_update )) && [[ -d "$plugdir/.git" ]]; then
      if ! git -C "$plugdir" fetch -q 2>/dev/null; then
        echo >&2 "Failed to fetch updates for $repo"
        _zplugin_update_ok=0
      elif git -C "$plugdir" rev-parse --verify '@{u}' &>/dev/null; then
        if ! git -C "$plugdir" diff --quiet HEAD '@{u}' 2>/dev/null; then
          echo "Upgrading $repo..."
          if ! git -C "$plugdir" merge -q '@{u}' 2>/dev/null; then
            echo >&2 "Failed to upgrade $repo"
            _zplugin_update_ok=0
          fi
        else
          echo "$repo is already up to date."
        fi
      fi
    fi

    if [[ ! -e $initfile ]]; then
      initfiles=("$plugdir"/*.{plugin.zsh,zsh-theme,zsh,sh}(N))
      (( $#initfiles )) || { echo >&2 "No init file found '$repo'." && continue }
      ln -sf "$initfiles[1]" "$initfile"
    fi

    (( ${fpath[(Ie)$plugdir]} )) || fpath+=("$plugdir")
    (( $+functions[zsh-defer] )) && zsh-defer . "$initfile" || . "$initfile"
  done
}

plugin-load $plugins

(( _zplugin_needs_update && _zplugin_update_ok )) && echo "$EPOCHSECONDS" > "$_zplugin_upgrade_file"

unset _zplugin_state_dir _zplugin_upgrade_file _zplugin_needs_update _zplugin_update_ok
