# ------------------------------------------------------------------------------
# Zsh config — order: PATH → config root → history → keybindings → functions
# To add shared features: add a .zsh file in zsh_functions/ (sourced in order).
# To add machine-only config: create zsh_functions/local.zsh (gitignored).
# ------------------------------------------------------------------------------

# PATH — ~/.local/bin first, then Homebrew (Apple Silicon, Intel, Linux)
export PATH="$HOME/.local/bin:$PATH"
if [[ -z "$HOMEBREW_PREFIX" ]]; then
  for _brew_prefix in /opt/homebrew /usr/local /home/linuxbrew/.linuxbrew; do
    if [[ -x "$_brew_prefix/bin/brew" ]]; then
      eval "$("$_brew_prefix/bin/brew" shellenv)"
      break
    fi
  done
  unset _brew_prefix
fi

# Config root — derived from this file's real path (works via source or symlink)
HISTSIZE=1000
SAVEHIST=$HISTSIZE
: "${SHARED_ZSH_ROOT:=${0:A:h}}"
export SHARED_ZSH_ROOT
# History in user home — we never copy or override it
HISTFILE="${HISTFILE:-$HOME/.zsh_history}"
ZSH_FUNCTION_DIR="${SHARED_ZSH_ROOT}/zsh_functions"

# History options
setopt BANG_HIST              # Treat the '!' character specially during expansion.
setopt EXTENDED_HISTORY       # Write the history file in the ':start:elapsed;command' format.
setopt INC_APPEND_HISTORY     # Write to the history file immediately, not when the shell exits.
setopt HIST_EXPIRE_DUPS_FIRST # Expire a duplicate event first when trimming history.
setopt HIST_IGNORE_DUPS       # Do not record an event that was just recorded again.
setopt HIST_REDUCE_BLANKS     # Remove superfluous blanks before saving
setopt HIST_IGNORE_ALL_DUPS   # Delete an old recorded event if a new event is a duplicate.
setopt HIST_FIND_NO_DUPS      # Do not display a previously found event.
setopt HIST_IGNORE_SPACE      # Do not record an event starting with a space.
setopt HIST_SAVE_NO_DUPS      # Do not write a duplicate event to the history file.
setopt HIST_VERIFY            # Do not execute immediately upon history expansion.
setopt HIST_BEEP              # Beep when accessing non-existent history.
setopt SHARE_HISTORY          # Share history across all sessions

# Keybindings — up/down search history by prefix
#bindkey '\e[A' history-search-backward
#bindkey '\e[B' history-search-forward
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

# MAC Up key
bindkey "^[[A" up-line-or-beginning-search
# Linux Up key
bindkey "${terminfo[kcuu1]}" up-line-or-beginning-search
# MAC Down key
bindkey "^[[B" down-line-or-beginning-search
# Linux Down key
bindkey "${terminfo[kcud1]}" down-line-or-beginning-search

# Plugins and helpers (each .zsh in zsh_functions/ is sourced in name order)
if [[ -d "$ZSH_FUNCTION_DIR" ]]; then
  for file in "$ZSH_FUNCTION_DIR"/*.zsh(N); do
    [[ "$file" == *"/local.zsh" ]] && continue
    source "$file"
  done
fi

# Local overrides — create zsh_functions/local.zsh for machine-only config (gitignored)
[[ -f "$ZSH_FUNCTION_DIR/local.zsh" ]] && source "$ZSH_FUNCTION_DIR/local.zsh"

# Initialize compinit and register tool completions
autoload -Uz compinit
compinit

# Register tool completions only for installed tools
command -v nvm &>/dev/null && compdef _nvm_zsh_complete nvm
command -v pyenv &>/dev/null && compdef _pyenv_zsh_complete pyenv
command -v uv &>/dev/null && compdef _uv_zsh_complete uv
command -v uvx &>/dev/null && compdef _uvx_zsh_complete uvx
command -v uv &>/dev/null && compdef _uv_python_complete uv python
command -v uv &>/dev/null && compdef _uv_tool_complete uv tool
command -v uv &>/dev/null && compdef _uv_pip_complete uv pip
command -v uv &>/dev/null && compdef _uv_cache_complete uv cache
