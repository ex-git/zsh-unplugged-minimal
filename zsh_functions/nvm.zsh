# NVM (Node Version Manager) — ensures node is on PATH
# Uses official nvm (nvm-sh/nvm). Loaded from zsh_functions so it's separate from unplugged plugins.

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

if [[ ! -d "$NVM_DIR" ]]; then
  echo "Installing nvm to $NVM_DIR..."
  git clone --depth=1 https://github.com/nvm-sh/nvm.git "$NVM_DIR"
fi

if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  . "$NVM_DIR/nvm.sh"
  # Activate default node so PATH includes the active node/npm (nvm.sh updates PATH when a version is in use)
  nvm use default 2>/dev/null || true
fi

if [[ -s "$NVM_DIR/bash_completion" ]]; then
  . "$NVM_DIR/bash_completion"
fi
