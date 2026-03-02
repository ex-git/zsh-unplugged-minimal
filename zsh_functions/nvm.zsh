# NVM (Node Version Manager) — lazy-loaded for fast zsh startup
# Loads nvm only when you first run nvm, node, npm, or npx.

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

# Install nvm if missing (no-op if already there)
if [[ ! -d "$NVM_DIR" ]]; then
  echo "Installing nvm to $NVM_DIR..."
  git clone --depth=1 https://github.com/nvm-sh/nvm.git "$NVM_DIR"
fi

if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
  return 0
fi

# Load nvm on first use
_nvm_load() {
  unset -f nvm node npm npx 2>/dev/null
  . "$NVM_DIR/nvm.sh"
  [[ -s "$NVM_DIR/bash_completion" ]] && . "$NVM_DIR/bash_completion"
  nvm use default 2>/dev/null || true
}

nvm() {
  _nvm_load
  nvm "$@"
}

# Only add shims if node isn't already on PATH (e.g. from nvm already loaded)
if ! command -v node &>/dev/null; then
  node() {
    _nvm_load
    command node "$@"
  }
  npm() {
    _nvm_load
    command npm "$@"
  }
  npx() {
    _nvm_load
    command npx "$@"
  }
fi
