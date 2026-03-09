PYENV_ROOT="${SHARED_ZSH_ROOT:-$HOME/.config/zsh}/pyenv"

if [[ ! -f "$PYENV_ROOT/bin/pyenv" ]]; then
  git clone --depth=1 https://github.com/pyenv/pyenv.git "$PYENV_ROOT"
  #git clone --depth=1 https://github.com/pyenv/pyenv-virtualenv.git "$PYENV_ROOT/plugins/pyenv-virtualenv"
fi
if [[ ! -f ${ZDOTDIR:-${HOME}}/.pyenv/bin/pyenv ]]; then
  command git clone --depth=1 https://github.com/pyenv/pyenv.git ${ZDOTDIR:-~}/.pyenv
  command git clone --depth=1 https://github.com/pyenv/pyenv-virtualenv.git ${ZDOTDIR:-~}/.pyenv/plugins/pyenv-virtualenv
fi

export PYENV_ROOT
export PATH="$PYENV_ROOT/bin:$PATH"

if command -v pyenv >/dev/null; then
  eval "$(pyenv init -)"
  #eval "$(pyenv virtualenv-init -)"
fi

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
  )

  _describe 'command' commands
}

compdef _pyenv_zsh_complete pyenv 2>/dev/null || true
