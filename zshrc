# ------------------------------------------------------------------------------
# Zsh config — order: PATH → config root → history → keybindings → functions
# To add shared features: add a .zsh file in zsh_functions/ (sourced in order).
# To add machine-only config: create zsh_functions/local.zsh (gitignored).
# ------------------------------------------------------------------------------

# Source portable environment variables first (safe for bash compatibility)
: "${SHARED_ZSH_ROOT:=${0:A:h}}"
if [[ -f "${SHARED_ZSH_ROOT}/env.zsh" ]]; then
  source "${SHARED_ZSH_ROOT}/env.zsh"
fi

# Config root — derived from this file's real path (works via source or symlink)
export SHARED_ZSH_ROOT
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

# Initialize completions
autoload -Uz compinit
compinit

# Plugins and helpers (each .zsh in zsh_functions/ is sourced in name order)
# Note: tool files register their own completions after compinit
if [[ -d "$ZSH_FUNCTION_DIR" ]]; then
  for file in "$ZSH_FUNCTION_DIR"/*.zsh(N); do
    [[ "$file" == *"/local.zsh" ]] && continue
    source "$file"
  done
fi

# Local overrides — create zsh_functions/local.zsh for machine-only config (gitignored)
[[ -f "$ZSH_FUNCTION_DIR/local.zsh" ]] && source "$ZSH_FUNCTION_DIR/local.zsh"
