#!/bin/bash
# Install or upgrade zsh config: copy files into user's home and link ~/.zshrc.
# Safe to run again to get the latest version (upgrade). Does not overwrite local.zsh.
# Run from repo:  ./setup.sh
# Run from URL:   sh -c "$(curl -fsSL https://raw.githubusercontent.com/ex-git/zsh-unplugged-minimal/main/setup.sh)"
# Override install location: INSTALL_DIR=~/.zsh ./setup.sh
# Override repo (for URL install): REPO_RAW_URL=https://raw.githubusercontent.com/ex-git/zsh-unplugged-minimal/main ./setup.sh
set -e

INSTALL_DIR="${INSTALL_DIR:-$HOME/.config/zsh}"
# When running via curl, script fetches files from this URL. Change when you fork.
REPO_RAW_URL="${REPO_RAW_URL:-https://raw.githubusercontent.com/ex-git/zsh-unplugged-minimal/main}"

# Files to install (relative to repo root). local.zsh is never overwritten.
FILES=(zshrc zsh_functions/unplugged.zsh zsh_functions/nvm.zsh zsh_functions/pyenv.zsh zsh_functions/github.zsh)

# Detect upgrade (config already installed)
is_upgrade=false
[[ -f "$INSTALL_DIR/zshrc" ]] && is_upgrade=true

install_from_local() {
  local repo_dir="$1"
  mkdir -p "$INSTALL_DIR/zsh_functions"
  cp "$repo_dir/zshrc" "$INSTALL_DIR/zshrc"
  for f in "$repo_dir"/zsh_functions/*.zsh; do
    [[ -f "$f" ]] && [[ "$f" != *"/local.zsh" ]] && cp "$f" "$INSTALL_DIR/zsh_functions/"
  done
}

install_from_url() {
  local url_base="$1"
  mkdir -p "$INSTALL_DIR/zsh_functions"
  for path in "${FILES[@]}"; do
    dest="$INSTALL_DIR/$path"
    echo "Fetching $path ..."
    if ! curl -fsSL "$url_base/$path" -o "$dest" 2>/dev/null; then
      echo "Skipping $path (not found or network error)" >&2
      rm -f "$dest"
    fi
  done
}

if "$is_upgrade"; then
  echo "Upgrading zsh config in $INSTALL_DIR ..."
else
  echo "Installing zsh config to $INSTALL_DIR ..."
fi

# Prefer local repo if this script is in one (e.g. ./setup.sh or bash setup.sh)
SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
if [[ -f "$SCRIPT_PATH" ]]; then
  REPO_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
  if [[ -f "$REPO_DIR/zshrc" ]]; then
    install_from_local "$REPO_DIR"
  else
    install_from_url "$REPO_RAW_URL"
  fi
else
  install_from_url "$REPO_RAW_URL"
fi

# Link ~/.zshrc to the installed zshrc (backup only if it's a regular file, not our symlink)
if [[ -f "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
  echo "Backing up existing ~/.zshrc to ~/.zshrc.bak"
  mv "$HOME/.zshrc" "$HOME/.zshrc.bak"
fi
rm -f "$HOME/.zshrc"
ln -s "$INSTALL_DIR/zshrc" "$HOME/.zshrc"

# Success summary
echo ""
if "$is_upgrade"; then
  echo "✓ Upgrade complete."
else
  echo "✓ Install complete."
fi
echo "  Config: $INSTALL_DIR"
echo "  Linked: ~/.zshrc → $INSTALL_DIR/zshrc"
echo ""
echo "Next: start a new shell or run  source ~/.zshrc"
echo ""
exit 0
