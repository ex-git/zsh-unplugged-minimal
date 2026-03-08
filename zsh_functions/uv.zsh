# UV (Python package manager) — integrated with zsh-unplugged-minimal

export UV_DIR="${UV_DIR:-$HOME/.local/share/uv}"
export UV_BIN_DIR="${UV_BIN_DIR:-$HOME/.local/bin}"

# Install uv if not present
if [[ ! -f "$UV_BIN_DIR/uv" ]]; then
  echo "Installing uv to $UV_BIN_DIR..."
  # Create bin directory if it doesn't exist
  mkdir -p "$UV_BIN_DIR"
  # Install uv using the official installer
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# Add uv to PATH if it exists
if [[ -f "$UV_BIN_DIR/uv" ]]; then
  export PATH="$UV_BIN_DIR:$PATH"
fi

# Lazy-load uv for faster startup (uv can be slow to initialize)
_uv_load() {
  unset -f uv 2>/dev/null
  # Re-source to ensure uv is in PATH
  export PATH="$UV_BIN_DIR:$PATH"
}

uv() {
  _uv_load
  command uv "$@"
}

# Also handle uvx (run tools without installing)
_uvx_load() {
  unset -f uvx 2>/dev/null
  export PATH="$UV_BIN_DIR:$PATH"
}

uvx() {
  _uvx_load
  command uvx "$@"
}
