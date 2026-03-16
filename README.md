# zsh-unplugged-minimal

Minimal, expandable Zsh config built on [zsh_unplugged](https://github.com/mattmc3/zsh_unplugged)–style plugin loading. Small by default; extend by adding scripts in `zsh_functions/` or dropping in a `local.zsh`. Portable, one-liner install, works on macOS and Linux.

## Features

- **Unplugged plugin loading** – [zsh_unplugged](https://github.com/mattmc3/zsh_unplugged)–style: clone plugins on demand, no framework (Pure prompt, autosuggestions, syntax highlighting, completions, etc.)
- **Minimal & expandable** – Small default set; add any `*.zsh` in `zsh_functions/` or use `local.zsh` for your own config (never overwritten on upgrade).
- **History** – Shared history across sessions, no duplicates, history search with arrow keys
- **Paths** – Homebrew (Apple Silicon, Intel, Linux via `brew shellenv`), `~/.local/bin`
- **Optional** – pyenv (auto-installed to `~/.config/zsh/pyenv` if used), Docker/Podman wrapper
- **Platform** – macOS and Linux aliases/helpers

## Prerequisites

- Zsh
- Git (for plugins and setup)
- (Optional) [Homebrew](https://brew.sh) for macOS/Linux

## Installation

**Option A — run from GitHub (no clone):**

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ex-git/zsh-unplugged-minimal/main/setup.sh)"
```

The script downloads the config into `~/.config/zsh` and adds a source line to `~/.zshrc` (your existing content is preserved).

**Option B — clone then run:**

```bash
git clone https://github.com/ex-git/zsh-unplugged-minimal.git /tmp/zsh-unplugged-minimal && cd /tmp/zsh-unplugged-minimal
./setup.sh
```

Start a new shell or run `source ~/.zshrc`. With Option B you can delete the repo folder after — the config lives in `~/.config/zsh`.

**Overrides:** `INSTALL_DIR=~/.zsh ./setup.sh` to install elsewhere. When using the URL install from a fork, set the repo: `REPO_RAW_URL=https://raw.githubusercontent.com/ex-git/zsh-unplugged-minimal/main bash -c "$(curl -fsSL .../setup.sh)"`.

**Upgrade:** Run the same install command again (from repo or URL). The script overwrites the config files in `~/.config/zsh` with the latest version and never touches `zsh_functions/local.zsh`.

## Project structure

After `./setup.sh`, the active config lives under `~/.config/zsh` (or your `INSTALL_DIR`):

```
~/.config/zsh/
├── zshrc               # Main config (sourced from ~/.zshrc)
└── zsh_functions/      # Sourced automatically
    ├── unplugged.zsh   # Plugin loader (Pure, autosuggestions, etc.)
    ├── history-helpers.zsh  # History management shortcuts (hr, hs, h)
    ├── nvm.zsh         # NVM / Node
    ├── pyenv.zsh       # Optional pyenv
    └── local.zsh       # Optional machine-only overrides (create yourself)
```

The repo you cloned only needs to exist while you run `setup.sh`; it is copied into the folder above.

## History Helpers

Quick shortcuts for managing history:

| Command | Description |
|---------|-------------|
| `hr` | Remove the last command from history |
| `hr <n1> <n2> ..` | Remove one or more entries by event number |
| `hr <pattern>` | Remove all entries matching pattern |
| `hr -n ...` | Dry-run: show what would be removed |
| `hs <pattern>` | Search history for pattern (case-insensitive) |
| `h` | Show history with line numbers (alias for `history`) |

### Examples

**Remove last command (most common):**
```zsh
% my-command --password secret123  # oops, password in history!
% hr
Removed: my-command --password secret123
```

**Preview before removing (dry-run):**
```zsh
% hr -n
Would remove:
  git push origin main
```

**Remove by event number (multiple supported):**
```zsh
% h 5              # show last 5 entries with line numbers
  1234  some-command
  1235  another-command
  1236  secret password oops!
  1237  wrong-command
  1238  h 5
% hr 1236 1237
Removed 2 entries.
```

> **Note:** `hr` itself is automatically omitted from your history.

**Remove by pattern:**
```zsh
% hr password
Removed entries matching: password

% hr -n password    # dry-run first
Would remove 1 matching entry:
  1236: secret password oops!
```

**Search history:**
```zsh
% hs docker
1234: docker ps -a
1240: docker-compose up -d
1255: docker logs container-name
```

## Customization

- **History file** – Uses `~/.zsh_history` (user home). Setup never copies or overwrites it. Override with `HISTFILE` in `zsh_functions/local.zsh` if you want a different path.
- **Plugins** – Edit the `plugins` array in `~/.config/zsh/zsh_functions/unplugged.zsh`. Plugins are cloned into `~/.config/zsh/plugins`.
- **Local overrides** – Create `~/.config/zsh/zsh_functions/local.zsh` for machine-only aliases and options (it is not overwritten by setup).

### Configuration Options

- **UV_WRAP_PYTHON** – Control whether `python`/`python3` commands are wrapped to use `uv`:
  - `UV_WRAP_PYTHON=1` (default) – Python commands use uv-managed Python, respecting `uv python pin`
  - `UV_WRAP_PYTHON=0` – Use system Python directly
  - Set in `zsh_functions/local.zsh` or your environment

- **Lazy-loading** – NVM and pyenv are lazy-loaded for faster shell startup:
  - Default node/python versions are added to PATH eagerly
  - The `nvm` and `pyenv` commands initialize on first use
  - This significantly reduces shell startup time compared to eager loading

## Uninstall

Remove the source line from `~/.zshrc` and (optionally) the installed config:

```bash
# Remove the two-line block added by setup.sh (marker + source line)
sed -i.bak '/^# --- zsh-unplugged-minimal ---$/,+1d' ~/.zshrc

# Remove installed config:
# rm -rf ~/.config/zsh
```

## License

MIT (or your chosen license).