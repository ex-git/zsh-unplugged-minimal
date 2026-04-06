# pyenv (Python Version Manager) — lazy-loaded for fast startup.
# First `pyenv` command will fully initialize pyenv.

export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"

# Auto-install pyenv if not present
if [[ ! -d "$PYENV_ROOT" ]]; then
  echo "Installing pyenv to $PYENV_ROOT..."
  git clone --depth=1 https://github.com/pyenv/pyenv.git "$PYENV_ROOT"
fi

# Ensure pyenv-virtualenv is present even if pyenv already existed.
if [[ -d "$PYENV_ROOT" ]] && [[ ! -d "$PYENV_ROOT/plugins/pyenv-virtualenv" ]]; then
  echo "Installing pyenv-virtualenv to $PYENV_ROOT/plugins/pyenv-virtualenv..."
  mkdir -p "$PYENV_ROOT/plugins"
  git clone --depth=1 https://github.com/pyenv/pyenv-virtualenv.git "$PYENV_ROOT/plugins/pyenv-virtualenv"
fi

# Eagerly add pyenv's bin dir to PATH so the pyenv executable is available
if [[ -d "$PYENV_ROOT/bin" ]]; then
  export PATH="$PYENV_ROOT/bin:$PATH"
fi

# Eagerly add default python to PATH if available
if ! command -v python &>/dev/null; then
  _pyenv_default_bin=""
  if [[ -s "$PYENV_ROOT/version" ]]; then
    for _pyenv_ver in "${(@f)$(<"$PYENV_ROOT/version")}"; do
      _pyenv_match=("$PYENV_ROOT"/versions/${_pyenv_ver}/bin(Nn))
      if (( ${#_pyenv_match} )); then
        _pyenv_default_bin="${_pyenv_match[-1]}"
        break
      fi
    done
  fi
  # Fallback: latest installed version
  if [[ -z "$_pyenv_default_bin" ]]; then
    _pyenv_match=("$PYENV_ROOT"/versions/*/bin(Nn))
    (( ${#_pyenv_match} )) && _pyenv_default_bin="${_pyenv_match[-1]}"
  fi
  [[ -d "$_pyenv_default_bin" ]] && export PATH="$_pyenv_default_bin:$PATH"
  unset _pyenv_ver _pyenv_match _pyenv_default_bin
fi

# Lazy-load pyenv itself (slow to initialize, only needed for pyenv use/install/etc.)
_pyenv_load() {
  unset -f pyenv 2>/dev/null
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
  if [[ -f "$PYENV_ROOT/plugins/pyenv-virtualenv/bin/pyenv-virtualenv" ]]; then
    eval "$(pyenv virtualenv-init -)"
  fi
}

pyenv() {
  _pyenv_load
  pyenv "$@"
}

# Zsh completion for pyenv
_pyenv_zsh_complete() {
  local -a commands
  commands=(
    'commands:List all pyenv commands'
    'completions:List completions for a shell'
    'exec:Execute an executable with the selected version'
    'global:Get or set the global Python version'
    'help:Show help message'
    'hooks:List hooks for a given command'
    'init:Initialize pyenv for shell'
    'install:Install a Python version'
    'latest:Print the latest installable version'
    'local:Get or set the local Python version'
    'prefix:Display prefix for a version'
    'rehash:Rehash pyenv shims'
    'root:Display pyenv root directory'
    'shell:Get or set the shell-specific Python version'
    'shims:List pyenv shims'
    'uninstall:Uninstall a Python version'
    'version:Display current version'
    'version-file:Detect and print version file'
    'version-file-read:Print version from file'
    'version-file-write:Write version to file'
    'version-name:Print current version name'
    'version-origin:Print which version originated'
    'versions:List all installed versions'
    'whence:List all Python versions that provide a command'
    'which:Display path for executable'
    'virtualenv:Create a virtualenv'
    'virtualenv-init:Initialize pyenv-virtualenv'
    'virtualenvs:List all virtualenvs'
  )

  _describe 'command' commands
}

# Register completion (silently fails if compinit not loaded yet)
compdef _pyenv_zsh_complete pyenv 2>/dev/null || true
