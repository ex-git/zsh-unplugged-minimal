# zsh-unplugged-minimal

Minimal, expandable Zsh config built on [zsh_unplugged](https://github.com/mattmc3/zsh_unplugged)–style plugin loading. Small by default; extend by adding scripts in `zsh_functions/` or dropping in a `local.zsh`. Portable, one-liner install, works on macOS and Linux.

## Features

- **Unplugged plugin loading** – [zsh_unplugged](https://github.com/mattmc3/zsh_unplugged)–style: clone plugins on demand, no framework (Pure prompt, autosuggestions, syntax highlighting, completions, etc.)
- **Minimal & expandable** – Small default set; add any `*.zsh` in `zsh_functions/` or use `local.zsh` for your own config (never overwritten on upgrade).
- **History** – Shared history across sessions, no duplicates, history search with arrow keys
- **Paths** – Homebrew (Apple Silicon, Intel, Linux via `brew shellenv`), `~/.local/bin`
- **Node & Python version managers** – nvm and pyenv are included by default, with `pyenv-virtualenv` support
- **pyenv build dependencies** – setup can optionally install the recommended Python build packages for common platforms
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

If you select `pyenv`, `setup.sh` can also optionally install the suggested build dependencies used by `pyenv install` on common platforms like macOS/Homebrew, Debian/Ubuntu, Fedora, Arch, Alpine, and others.

## pyenv / pyenv-virtualenv usage

Because `pyenv-virtualenv` is installed and initialized automatically, you can use both `pyenv` and virtualenv commands directly:

```zsh
# install a Python version
pyenv install 3.12.11
pyenv global 3.12.11

# create a virtualenv from that version
pyenv virtualenv 3.12.11 my-project-3.12

# use it in the current directory
pyenv local my-project-3.12
python --version

# optionally activate/deactivate manually
pyenv activate my-project-3.12
pyenv deactivate
```

> `pyenv install` compiles Python locally. If builds fail, rerun `setup.sh` and choose to install pyenv build dependencies, or follow pyenv's suggested build environment guide: <https://github.com/pyenv/pyenv/wiki#suggested-build-environment>

## Project structure

After `./setup.sh`, the active config lives under `~/.config/zsh` (or your `INSTALL_DIR`):

```
~/.config/zsh/
├── zshrc               # Main config (sourced from ~/.zshrc)
└── zsh_functions/      # Sourced automatically
    ├── unplugged.zsh   # Plugin loader (Pure, autosuggestions, etc.)
    ├── history-helpers.zsh  # History management (h -l/-s/-r)
    ├── nvm.zsh         # NVM / Node
    ├── pyenv.zsh       # pyenv / Python + pyenv-virtualenv
    └── local.zsh       # Optional machine-only overrides (create yourself)
```

The repo you cloned only needs to exist while you run `setup.sh`; it is copied into the folder above.

## History Helpers

History is managed through a single `h` command with flags.

| Command | Description |
|---------|-------------|
| `h -l [n]` | Show history with line numbers |
| `h -s <pattern>` | Search history for pattern (case-insensitive) |
| `h -r` | Remove the last command from history |
| `h -r <n1> <n2> ..` | Remove one or more entries by event number |
| `h -r <pattern>` | Remove all entries matching pattern |
| `h -r -n ...` | Dry-run: show what would be removed |
| `h -h`, `h --help` | Show help |

### Examples

**Show history:**
```zsh
% h -l 5
  1234  some-command
  1235  another-command
  1236  secret password oops!
  1237  wrong-command
  1238  h -l 5
```

**Remove last command (most common):**
```zsh
% my-command --password secret123  # oops, password in history!
% h -r
Removed: my-command --password secret123
```

**Preview before removing (dry-run):**
```zsh
% h -r -n
Would remove:
  git push origin main
```

**Remove by event number (multiple supported):**
```zsh
% h -l 5
  1234  some-command
  1235  another-command
  1236  secret password oops!
  1237  wrong-command
  1238  h -l 5
% h -r 1236 1237
Removed 2 entries.
```

> **Note:** `h -r` is automatically omitted from your history.

**Remove by pattern:**
```zsh
% h -r password
Removed entries matching: password

% h -r -n password    # dry-run first
Would remove entries matching: password
```

**Search history:**
```zsh
% h -s docker
1234: docker ps -a
1240: docker-compose up -d
1255: docker logs container-name
```

## Customization

- **History file** – Uses `~/.zsh_history` (user home). Setup never copies or overwrites it. Override with `HISTFILE` in `zsh_functions/local.zsh` if you want a different path.
- **Plugins** – Edit the `plugins` array in `~/.config/zsh/zsh_functions/unplugged.zsh`. Plugins are cloned into `~/.config/zsh/plugins`.
- **Local overrides** – Create `~/.config/zsh/zsh_functions/local.zsh` for machine-only aliases and options (it is not overwritten by setup).

### Configuration Options

- **Lazy-loading** – NVM and pyenv are lazy-loaded for faster shell startup:
  - Default node/python versions are added to PATH eagerly
  - The `nvm` and `pyenv` commands initialize on first use
  - `pyenv-virtualenv` is initialized automatically when available
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