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
