#!/bin/bash
# Install or upgrade zsh config: adds a source line to ~/.zshrc (preserves existing content).
# Safe to run again to get the latest version (upgrade). Does not overwrite local.zsh.
# Run from repo:  ./setup.sh
# Run from URL:   bash -c "$(curl -fsSL https://raw.githubusercontent.com/ex-git/zsh-unplugged-minimal/main/setup.sh)"
# Override install location: INSTALL_DIR=~/.zsh ./setup.sh
# Override repo (for URL install): REPO_RAW_URL=https://raw.githubusercontent.com/ex-git/zsh-unplugged-minimal/main ./setup.sh
set -e

# Re-exec under bash if invoked via sh/dash (e.g. sh -c "$(curl ...)")
if [ -z "$BASH_VERSION" ]; then
  exec bash "$0" "$@" 2>/dev/null || exec bash -c "$(cat "$0")" "$@"
fi

INSTALL_DIR="${INSTALL_DIR:-$HOME/.config/zsh}"
# When running via curl, script fetches files from this URL. Change when you fork.
REPO_RAW_URL="${REPO_RAW_URL:-https://raw.githubusercontent.com/ex-git/zsh-unplugged-minimal/main}"

# Base files to always install (local.zsh is never overwritten)
BASE_FILES=(zshrc zsh_functions/unplugged.zsh)

# Optional tools that users can select (uses a function instead of
# associative array for bash 3.2 compatibility on macOS)
AVAILABLE_TOOLS="nvm pyenv uv"
tool_file() {
  case "$1" in
    nvm)   echo "zsh_functions/nvm.zsh" ;;
    pyenv) echo "zsh_functions/pyenv.zsh" ;;
    uv)    echo "zsh_functions/uv.zsh" ;;
  esac
}

# Detect upgrade (config already installed)
is_upgrade=false
[[ -f "$INSTALL_DIR/zshrc" ]] && is_upgrade=true

# Build FILES array based on selection
build_files_array() {
  FILES=("${BASE_FILES[@]}")
  if [[ ${#SELECTED_FILES[@]} -gt 0 ]]; then
    FILES+=("${SELECTED_FILES[@]}")
  fi
}

install_from_local() {
  local repo_dir="$1"
  mkdir -p "$INSTALL_DIR/zsh_functions"
  cp "$repo_dir/zshrc" "$INSTALL_DIR/zshrc"
  for f in "${FILES[@]}"; do
    # Only copy files from zsh_functions directory (not zshrc)
    if [[ "$f" == zsh_functions/* ]] && [[ -f "$repo_dir/$f" ]]; then
      cp "$repo_dir/$f" "$INSTALL_DIR/$f"
    fi
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

# Map tool .zsh files to the git directories they clone
tool_data_dirs() {
  case "$1" in
    nvm.zsh)   echo "$HOME/.nvm" ;;
    pyenv.zsh) echo "$INSTALL_DIR/pyenv $HOME/.pyenv" ;;
  esac
}

# Remove zsh_functions/*.zsh that are no longer in FILES (never touch local.zsh)
prune_obsolete_functions() {
  local fn_dir="$INSTALL_DIR/zsh_functions"
  [[ ! -d "$fn_dir" ]] && return
  local path base keep
  for path in "$fn_dir"/*.zsh; do
    [[ -f "$path" ]] || continue
    base="${path##*/}"
    [[ "$base" == "local.zsh" ]] && continue
    keep=0
    for p in "${FILES[@]}"; do
      if [[ "$p" == zsh_functions/"$base" ]]; then keep=1; break; fi
    done
    if (( keep == 0 )); then
      rm -f "$path"
      echo "Removed obsolete: zsh_functions/$base"
      for dir in $(tool_data_dirs "$base"); do
        if [[ -d "$dir" ]]; then
          echo -n "Remove $dir? [y/N]: "
          read -r confirm
          if [[ "$confirm" =~ ^[Yy]$ ]]; then
            rm -rf "$dir"
            echo "Removed: $dir"
          else
            echo "Kept: $dir"
          fi
        fi
      done
    fi
  done
}

# Save selected tools for future upgrades
save_selection() {
  local marker_file="$INSTALL_DIR/.selected_tools"
  > "$marker_file"
  for f in "${SELECTED_FILES[@]}"; do
    local tool_name="${f##*/}"
    tool_name="${tool_name%.zsh}"
    echo "$tool_name" >> "$marker_file"
  done
}

if "$is_upgrade"; then
  echo "Upgrading zsh config in $INSTALL_DIR ..."
else
  echo "Installing zsh config to $INSTALL_DIR ..."
fi

# Prompt for tool selection (always show for both new install and upgrade)
echo ""
echo "Available tools:"
echo "  nvm   - Node Version Manager"
echo "  pyenv - Python Version Manager"
echo "  uv    - Fast Python Package Manager"
echo ""
echo "Select optional tools to install:"
echo ""
echo -n "Use default tools (nvm, uv)? [Y/n]: "
read -r yn

if [[ "$yn" =~ ^[Nn]$ ]]; then
  # User wants to customize - ask for each tool
  SELECTED_FILES=()
  tool_names=()

  # nvm
  echo -n "  nvm (Node Version Manager)? [y/N]: "
  read -r yn
  if [[ "$yn" =~ ^[Yy]$ ]]; then
    SELECTED_FILES+=("$(tool_file nvm)")
    tool_names+=("nvm")
  fi

  # pyenv
  echo -n "  pyenv (Python Version Manager)? [y/N]: "
  read -r yn
  if [[ "$yn" =~ ^[Yy]$ ]]; then
    SELECTED_FILES+=("$(tool_file pyenv)")
    tool_names+=("pyenv")
  fi

  # uv
  echo -n "  uv (Python Package Manager)? [y/N]: "
  read -r yn
  if [[ "$yn" =~ ^[Yy]$ ]]; then
    SELECTED_FILES+=("$(tool_file uv)")
    tool_names+=("uv")
  fi
else
  # Use default: nvm and uv
  SELECTED_FILES=("$(tool_file nvm)" "$(tool_file uv)")
  tool_names=("nvm" "uv")
fi

if [[ ${#tool_names[@]} -gt 0 ]]; then
  echo ""
  echo "Selected: ${tool_names[*]}"
else
  echo ""
  echo "No optional tools will be installed."
fi

# Build FILES array
build_files_array

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

prune_obsolete_functions

# Save selection for future runs
save_selection

MARKER="# --- zsh-unplugged-minimal ---"
SOURCE_LINE="source \"$INSTALL_DIR/zshrc\""
INJECT_BLOCK="${MARKER}
${SOURCE_LINE}"

# Migrate from old symlink-based install
if [[ -L "$HOME/.zshrc" ]]; then
  rm -f "$HOME/.zshrc"
  # Restore backup from previous install if available
  if [[ -f "$HOME/.zshrc.bak" ]]; then
    mv "$HOME/.zshrc.bak" "$HOME/.zshrc"
    echo "Restored ~/.zshrc from backup"
  fi
fi

# Ensure ~/.zshrc exists
touch "$HOME/.zshrc"

# Prepend the source line if not already present (idempotent)
if ! grep -qF "$MARKER" "$HOME/.zshrc" 2>/dev/null; then
  existing="$(cat "$HOME/.zshrc")"
  printf '%s\n' "$INJECT_BLOCK" "" "$existing" > "$HOME/.zshrc"
  echo "Added source line to ~/.zshrc"
else
  # Marker exists — update the source path in case INSTALL_DIR changed
  tmp="$(mktemp)"
  while IFS= read -r line; do
    if [[ "$line" == "$MARKER" ]]; then
      printf '%s\n' "$line"
      IFS= read -r _old_source  # skip old source line
      printf '%s\n' "$SOURCE_LINE"
    else
      printf '%s\n' "$line"
    fi
  done < "$HOME/.zshrc" > "$tmp"
  mv "$tmp" "$HOME/.zshrc"
fi

# Success summary
echo ""
if "$is_upgrade"; then
  echo "✓ Upgrade complete."
else
  echo "✓ Install complete."
fi
echo "  Config: $INSTALL_DIR"
echo "  ~/.zshrc sources $INSTALL_DIR/zshrc"
if [[ ${#SELECTED_FILES[@]} -gt 0 ]]; then
  echo "  Optional tools: ${SELECTED_FILES[*]#zsh_functions/}"
fi
echo ""
echo "Next: start a new shell or run  source ~/.zshrc"
echo ""
exit 0
