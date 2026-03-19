# Install or upgrade zsh config: adds a source line to ~/.zshrc (preserves existing content).
# Safe to run again to get the latest version (upgrade). Does not overwrite local.zsh.
# Run from repo:  ./setup.sh
# Run from URL:   bash -c "$(curl -fsSL https://raw.githubusercontent.com/ex-git/zsh-unplugged-minimal/main/setup.sh)"
# Override install location: INSTALL_DIR=~/.zsh ./setup.sh
# Override repo (for URL install): REPO_RAW_URL=https://raw.githubusercontent.com/ex-git/zsh-unplugged-minimal/main ./setup.sh
set -e

# Re-exec under bash if invoked via sh/dash (e.g. sh -c "$(curl ...)")
if [ -z "$BASH_VERSION" ]; then
  if command -v bash &>/dev/null; then
    exec bash "$0" "$@"
  else
    echo "Error: bash is required but not found." >&2
    exit 1
  fi
fi

# Check for required tools
check_dependencies() {
  local missing=()

  if ! command -v git &>/dev/null; then
    missing+=("git")
  fi

  # curl is only needed for URL-based installs
  if [[ ! -f "$0" ]] && ! command -v curl &>/dev/null; then
    missing+=("curl")
  fi

  if (( ${#missing[@]} > 0 )); then
    echo "Error: Missing required tools: ${missing[*]}" >&2
    echo "Please install them and try again." >&2
    exit 1
  fi
}

check_dependencies

INSTALL_DIR="${INSTALL_DIR:-$HOME/.config/zsh}"
# When running via curl, script fetches files from this URL. Change when you fork.
REPO_RAW_URL="${REPO_RAW_URL:-https://raw.githubusercontent.com/ex-git/zsh-unplugged-minimal/main}"

# Base files to always install (local.zsh is never overwritten)
BASE_FILES=(env.zsh zshrc zsh_functions/unplugged.zsh zsh_functions/history-helpers.zsh)

# Optional tools that users can select (uses a function instead of
# associative array for bash 3.2 compatibility on macOS)
AVAILABLE_TOOLS="nvm pyenv"
tool_file() {
  case "$1" in
    nvm)   echo "zsh_functions/nvm.zsh" ;;
    pyenv) echo "zsh_functions/pyenv.zsh" ;;
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

has_selected_tool() {
  local tool="$1"
  local file
  for file in "${SELECTED_FILES[@]}"; do
    [[ "$file" == "$(tool_file "$tool")" ]] && return 0
  done
  return 1
}

install_pyenv_build_deps() {
  local install_cmd=""
  local tk_pkg="tk-devel"
  local fedora_ver=""

  if [[ "$OSTYPE" == darwin* ]]; then
    if ! xcode-select -p &>/dev/null; then
      echo "Xcode Command Line Tools are required to build Python with pyenv."
      echo "Starting installer..."
      xcode-select --install || true
      echo "Finish the Xcode Command Line Tools install, then rerun setup.sh to install pyenv build dependencies."
      return 1
    fi

    if command -v brew &>/dev/null; then
      install_cmd='brew install openssl readline sqlite3 xz tcl-tk@8 libb2 zstd zlib pkgconfig'
    elif command -v port &>/dev/null; then
      install_cmd='sudo port install pkgconfig openssl xz gdbm tcl tk +quartz sqlite3 sqlite3-tcl zstd'
    else
      echo "Warning: No supported macOS package manager found (Homebrew or MacPorts)." >&2
      echo "See https://github.com/pyenv/pyenv/wiki#suggested-build-environment" >&2
      return 1
    fi
  elif command -v apt-get &>/dev/null; then
    install_cmd='sudo apt update && sudo apt install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev curl git libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev libzstd-dev'
  elif command -v dnf &>/dev/null; then
    if command -v rpm &>/dev/null; then
      fedora_ver="$(rpm -E %fedora 2>/dev/null || true)"
      if [[ "$fedora_ver" =~ ^[0-9]+$ ]] && (( fedora_ver >= 42 )); then
        tk_pkg="tk8-devel"
      fi
    fi
    install_cmd="sudo dnf install -y make gcc patch zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel ${tk_pkg} libffi-devel xz-devel libuuid-devel gdbm-libs libnsl2 libzstd-devel"
  elif command -v yum &>/dev/null; then
    if [[ -f /etc/system-release ]] && grep -qi 'Amazon Linux release 2' /etc/system-release; then
      install_cmd='sudo yum install -y gcc make patch zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl11-devel tk-devel libffi-devel xz-devel zstd-devel'
    else
      install_cmd='sudo yum install -y gcc make patch zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel tk-devel libffi-devel xz-devel zstd-devel'
    fi
  elif command -v zypper &>/dev/null; then
    install_cmd='sudo zypper install -y gcc automake bzip2 libbz2-devel xz xz-devel openssl-devel ncurses-devel readline-devel zlib-devel tk-devel libffi-devel sqlite3-devel gdbm-devel make findutils patch libzstd-devel'
  elif command -v pacman &>/dev/null; then
    install_cmd='sudo pacman -S --needed base-devel openssl zlib xz tk zstd'
  elif command -v apk &>/dev/null; then
    install_cmd='sudo apk add --no-cache git bash build-base libffi-dev openssl-dev bzip2-dev zlib-dev xz-dev readline-dev sqlite-dev tk-dev zstd-dev'
  elif command -v xbps-install &>/dev/null; then
    install_cmd='sudo xbps-install -Sy base-devel libffi-devel bzip2-devel openssl openssl-devel readline readline-devel sqlite-devel xz liblzma-devel zlib zlib-devel libzstd-devel'
  else
    echo "Warning: No supported package manager detected for pyenv build dependencies." >&2
    echo "See https://github.com/pyenv/pyenv/wiki#suggested-build-environment" >&2
    return 1
  fi

  echo "Installing pyenv build dependencies..."
  echo "Running: $install_cmd"
  if ! eval "$install_cmd"; then
    echo "Warning: Failed to install pyenv build dependencies. You can continue and install them later." >&2
    return 1
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
      echo "Warning: Failed to fetch $path" >&2
      rm -f "$dest"
    elif [[ ! -s "$dest" ]]; then
      echo "Warning: Fetched $path is empty" >&2
      rm -f "$dest"
    fi
  done

  # Verify critical files were downloaded
  for path in "${BASE_FILES[@]}"; do
    if [[ ! -f "$INSTALL_DIR/$path" ]]; then
      echo "Error: Failed to download required file: $path" >&2
      exit 1
    fi
  done
}

# Map tool .zsh files to the git directories they clone
tool_data_dirs() {
  case "$1" in
    nvm.zsh)   echo "$HOME/.nvm" ;;
    pyenv.zsh) echo "$HOME/.pyenv" ;;
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
      for item in $(tool_data_dirs "$base"); do
        if [[ -e "$item" ]]; then
          echo -n "Remove $item? [y/N]: "
          read -r confirm < /dev/tty
          if [[ "$confirm" =~ ^[Yy]$ ]]; then
            rm -rf "$item"
            echo "Removed: $item"
          else
            echo "Kept: $item"
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

# Setup bash compatibility - share zsh environment with bash
setup_bash_compatibility() {
  local bashrc="$HOME/.bashrc"
  local marker="# --- zsh-unplugged-minimal (bash compat) ---"
  local inject_block="${marker}
if [ -f \"$INSTALL_DIR/env.zsh\" ]; then
  source \"$INSTALL_DIR/env.zsh\"
fi"

  # Ensure ~/.bashrc exists
  touch "$bashrc"

  # Remove any existing entry (handles both old format and duplicates)
  if grep -qF "$marker" "$bashrc" 2>/dev/null; then
    grep -vF "$marker" "$bashrc" | grep -v '\.zshrc' | grep -v '^$' > "${bashrc}.tmp" 2>/dev/null || true
    mv "${bashrc}.tmp" "$bashrc"
  fi

  # Prepend the new source line
  existing="$(cat "$bashrc")"
  printf '%s\n' "$inject_block" "" "$existing" > "$bashrc"
  echo "Added zsh source line to ~/.bashrc for bash compatibility"
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
echo "  pyenv - Python Version Manager + virtualenv support"
echo ""
echo "Select optional tools to install:"
echo ""
echo -n "Use default tools (nvm, pyenv)? [Y/n]: "
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
  echo -n "  pyenv (Python Version Manager + virtualenv support)? [y/N]: "
  read -r yn
  if [[ "$yn" =~ ^[Yy]$ ]]; then
    SELECTED_FILES+=("$(tool_file pyenv)")
    tool_names+=("pyenv")
  fi
else
  # Use default: nvm and pyenv
  SELECTED_FILES=("$(tool_file nvm)" "$(tool_file pyenv)")
  tool_names=("nvm" "pyenv")
fi

if [[ ${#tool_names[@]} -gt 0 ]]; then
  echo ""
  echo "Selected: ${tool_names[*]}"
else
  echo ""
  echo "No optional tools will be installed."
fi

# Optionally install pyenv build dependencies for compiling Python versions
if has_selected_tool pyenv; then
  echo ""
  echo -n "Install pyenv build dependencies now? [Y/n]: "
  read -r install_pyenv_deps
  if [[ "$install_pyenv_deps" =~ ^[Nn]$ ]]; then
    install_pyenv_deps=false
  else
    install_pyenv_deps=true
  fi
else
  install_pyenv_deps=false
fi

# Option to share zsh environment with bash
echo ""
echo -n "Share zsh environment with bash? (adds source line to ~/.bashrc) [Y/n]: "
read -r share_with_bash
if [[ "$share_with_bash" =~ ^[Nn]$ ]]; then
  share_with_bash=false
else
  share_with_bash=true
fi

# Build FILES array
build_files_array

if "$install_pyenv_deps"; then
  echo ""
  install_pyenv_build_deps || true
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

# Setup bash compatibility if requested
if "$share_with_bash"; then
  setup_bash_compatibility
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
if "$share_with_bash"; then
  echo "  Bash compatibility: enabled (~/.bashrc sources env.zsh)"
fi
echo ""
echo "Next: start a new shell or run  source ~/.zshrc"
echo ""
exit 0
