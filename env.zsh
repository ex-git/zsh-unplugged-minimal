# ------------------------------------------------------------------------------
# Portable environment variables — safe to source from bash or zsh
# This file should be sourced first to set up PATH and basic env before
# sourcing the full zshrc which contains zsh-specific commands.
# Note: SHARED_ZSH_ROOT must be set by the caller (zshrc) before sourcing this.
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

# History settings (portable - works in both bash and zsh)
export HISTFILE="${HISTFILE:-$HOME/.zsh_history}"
export HISTSIZE=1000
export HISTFILESIZE=2000
export SAVEHIST=1000
# Append to history rather than overwriting (both bash and zsh)
shopt -s histappend

# NVM (Node Version Manager) - portable setup for bash compatibility
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
# Source nvm.sh for bash (zsh uses lazy-loading via nvm.zsh)
if [[ -s "$NVM_DIR/nvm.sh" ]] && [[ -n "$BASH_VERSION" ]]; then
  . "$NVM_DIR/nvm.sh"
fi
