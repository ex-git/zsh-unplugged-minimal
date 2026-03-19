# UV (Python package manager) — integrated with zsh-unplugged-minimal
#
# Optional python wrapper behavior:
#   UV_WRAP_PYTHON=1  # Enable python/python3 wrappers (default)
#   UV_WRAP_PYTHON=0  # Disable wrappers, use system python directly

export UV_DIR="${UV_DIR:-$HOME/.local/share/uv}"
export UV_BIN_DIR="${UV_BIN_DIR:-$HOME/.local/bin}"

# Skip install if uv is already available (e.g. via Homebrew)
if ! command -v uv &>/dev/null; then
  if [[ ! -f "$UV_BIN_DIR/uv" ]]; then
    echo "Installing uv to $UV_BIN_DIR..."
    mkdir -p "$UV_BIN_DIR"
    curl -LsSf https://astral.sh/uv/install.sh | sh
  fi
  # Add the local bin to PATH only when uv isn't available system-wide
  if [[ -f "$UV_BIN_DIR/uv" ]]; then
    export PATH="$UV_BIN_DIR:$PATH"
  fi
fi

# Optionally wrap python/python3 to use uv-managed python.
# Set UV_WRAP_PYTHON=0 to disable and use system python directly.
# When enabled, `uv python pin` will be respected for all python calls.
if [[ "${UV_WRAP_PYTHON:-1}" == "1" ]] && command -v uv &>/dev/null; then
  python()  { command uv run python "$@" }
  python3() { command uv run python3 "$@" }
  pip()     { command uv pip "$@" }
fi

# Zsh completion for uv
_uv_zsh_complete() {
  local -a commands
  commands=(
    'auth:Manage authentication'
    'run:Run a command or script'
    'init:Initialize a new project'
    'add:Add dependencies to the project'
    'remove:Remove dependencies from the project'
    'version:Read or update the project version'
    'sync:Update the project environment'
    'lock:Update the project lockfile'
    'export:Export lockfile to alternate format'
    'tree:Display dependency tree'
    'format:Format Python code'
    'tool:Run and install tools'
    'python:Manage Python versions'
    'pip:Low-level pip interface'
    'venv:Create virtual environment'
    'build:Build Python packages'
    'publish:Upload distributions to index'
    'cache:Manage uv cache'
    'self:Manage uv executable'
    'help:Display command help'
  )

  _describe 'command' commands
}

compdef _uv_zsh_complete uv 2>/dev/null || true

# Zsh completion for uvx (also handles uv tool run)
_uvx_zsh_complete() {
  local -a commands
  commands=(
    'run:Run a command or tool'
    'from:Run a tool from a specific package'
    'help:Show help'
  )

  _describe 'command' commands
}

# Zsh completion for uv python
_uv_python_complete() {
  local -a commands
  commands=(
    'list:List available Python installations'
    'install:Download and install Python versions'
    'upgrade:Upgrade installed Python versions'
    'find:Search for a Python installation'
    'pin:Pin to a specific Python version'
    'dir:Show the uv Python installation directory'
    'uninstall:Uninstall Python versions'
    'update-shell:Update shell to include Python'
  )

  _describe 'command' commands
}

# Zsh completion for uv tool
_uv_tool_complete() {
  local -a commands
  commands=(
    'run:Run a tool in temporary environment'
    'install:Install a tool user-wide'
    'upgrade:Upgrade installed tools'
    'list:List installed tools'
    'uninstall:Uninstall a tool'
    'update-shell:Update shell for tool executables'
    'dir:Show the tool directory'
  )

  _describe 'command' commands
}

# Zsh completion for uv pip
_uv_pip_complete() {
  local -a commands
  commands=(
    'compile:Compile requirements to lockfile'
    'sync:Sync environment with requirements'
    'install:Install packages'
    'uninstall:Uninstall packages'
    'freeze:List installed packages'
    'list:List installed packages'
    'show:Show package information'
    'tree:Display dependency tree'
    'check:Verify package compatibility'
  )

  _describe 'command' commands
}

# Zsh completion for uv cache
_uv_cache_complete() {
  local -a commands
  commands=(
    'clean:Clear cache entries'
    'prune:Remove outdated cache entries'
    'dir:Show cache directory'
    'size:Show cache size'
  )

  _describe 'command' commands
}

compdef _uvx_zsh_complete uvx 2>/dev/null || true
