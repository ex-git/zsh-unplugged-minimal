# uv (Astral) — prefer an existing uv on PATH; otherwise install cleanly.
# Auto-installs uv into $UV_INSTALL_DIR without modifying shell profiles.

export UV_INSTALL_DIR="${UV_INSTALL_DIR:-$HOME/.local/bin}"
UV_INSTALLER_URL="${UV_INSTALLER_URL:-https://astral.sh/uv/install.sh}"

# Prefer an existing uv already on PATH (e.g. Homebrew/system package manager).
# Otherwise, expose the managed install dir and install there if needed.
if ! command -v uv &>/dev/null; then
  case ":$PATH:" in
    *":$UV_INSTALL_DIR:"*) ;;
    *) export PATH="$UV_INSTALL_DIR:$PATH" ;;
  esac

  if [[ ! -x "$UV_INSTALL_DIR/uv" ]] || [[ ! -x "$UV_INSTALL_DIR/uvx" ]]; then
    echo "Installing uv to $UV_INSTALL_DIR..."
    if command -v curl &>/dev/null; then
      if ! curl -LsSf "$UV_INSTALLER_URL" | env UV_INSTALL_DIR="$UV_INSTALL_DIR" UV_NO_MODIFY_PATH=1 sh; then
        echo "Warning: Failed to install uv." >&2
        return 0
      fi
    elif command -v wget &>/dev/null; then
      if ! wget -qO- "$UV_INSTALLER_URL" | env UV_INSTALL_DIR="$UV_INSTALL_DIR" UV_NO_MODIFY_PATH=1 sh; then
        echo "Warning: Failed to install uv." >&2
        return 0
      fi
    else
      echo "Warning: curl or wget is required to install uv automatically." >&2
      return 0
    fi
    hash -r 2>/dev/null || true
  fi
fi

# Best-effort completion from uv itself.
if command -v uv &>/dev/null && (( $+functions[compdef] )); then
  eval "$(uv generate-shell-completion zsh 2>/dev/null)" 2>/dev/null || true
  if command -v uvx &>/dev/null; then
    eval "$(uvx --generate-shell-completion zsh 2>/dev/null)" 2>/dev/null || true
  fi
fi
