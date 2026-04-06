# NVM (Node Version Manager) — default node added to PATH eagerly,
# nvm command itself lazy-loaded for fast startup.

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

if [[ ! -d "$NVM_DIR" ]]; then
  echo "Installing nvm to $NVM_DIR..."
  git clone --depth=1 https://github.com/nvm-sh/nvm.git "$NVM_DIR"
fi

if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
  return 0
fi

# Eagerly add default node to PATH so scripts can find node/npm/npx
if ! command -v node &>/dev/null; then
  _nvm_default_bin=""
  if [[ -s "$NVM_DIR/alias/default" ]]; then
    _nvm_ver="$(<"$NVM_DIR/alias/default")"
    # Resolve lts aliases (e.g. lts/* -> lts/jod -> 22.x.x)
    [[ "$_nvm_ver" == lts/* && -s "$NVM_DIR/alias/$_nvm_ver" ]] \
      && _nvm_ver="$(<"$NVM_DIR/alias/$_nvm_ver")"
    _nvm_match=("$NVM_DIR"/versions/node/v${_nvm_ver##v}*(Nn))
    (( ${#_nvm_match} )) && _nvm_default_bin="${_nvm_match[-1]}/bin"
  fi
  # Fallback: latest installed version
  if [[ -z "$_nvm_default_bin" ]]; then
    _nvm_match=("$NVM_DIR"/versions/node/*(Nn))
    (( ${#_nvm_match} )) && _nvm_default_bin="${_nvm_match[-1]}/bin"
  fi
  [[ -d "$_nvm_default_bin" ]] && export PATH="$_nvm_default_bin:$PATH"
  unset _nvm_ver _nvm_match _nvm_default_bin
fi

# Lazy-load nvm itself (slow to source, only needed for nvm use/install/...)
_nvm_load() {
  unset -f nvm 2>/dev/null
  . "$NVM_DIR/nvm.sh"
  [[ -s "$NVM_DIR/bash_completion" ]] && . "$NVM_DIR/bash_completion"
}

nvm() {
  _nvm_load
  nvm "$@"
}

# Zsh completion for nvm
_nvm_zsh_complete() {
  local -a commands
  commands=(
    'install:Install a specific Node.js version'
    'use:Switch to use a specific version'
    'run:Run a command with a specific Node version'
    'exec:Execute a command with a specific Node version'
    'current:Show the currently active version'
    'ls:List installed versions'
    'list:List installed versions'
    'list-remote:List available versions to install'
    'ls-remote:List available versions to install'
    'install-latest-npm:Install latest npm for current node'
    'reinstall-packages:Reinstall global packages'
    'uninstall:Uninstall a specific version'
    'alias:Manage version aliases'
    'unalias:Remove a version alias'
    'load:NVM load'
    'unload:NVM unload'
    'shutdown:Shutdown NVM and clear environment'
    'reset:Clear NVM directory'
    'version:Show NVM version'
    'version-remote:Show remote version'
    'help:Show help'
  )

  _describe 'command' commands
}

# Register completion (silently fails if compinit not loaded yet)
compdef _nvm_zsh_complete nvm 2>/dev/null || true
