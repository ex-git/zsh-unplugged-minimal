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
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ex-git/zsh-unplugged-minimal/main/setup.sh)"
```

The script downloads the config into `~/.config/zsh` and adds a source line to `~/.zshrc` (your existing content is preserved).

**Option B — clone then run:**

```bash
git clone https://github.com/ex-git/zsh-unplugged-minimal.git /tmp/zsh-unplugged-minimal && cd /tmp/zsh-unplugged-minimal
./setup.sh
```

Start a new shell or run `source ~/.zshrc`. With Option B you can delete the repo folder after — the config lives in `~/.config/zsh`.

**Overrides:** `INSTALL_DIR=~/.zsh ./setup.sh` to install elsewhere. When using the URL install from a fork, set the repo: `REPO_RAW_URL=https://raw.githubusercontent.com/ex-git/zsh-unplugged-minimal/main sh -c "$(curl -fsSL .../setup.sh)"`.

**Upgrade:** Run the same install command again (from repo or URL). The script overwrites the config files in `~/.config/zsh` with the latest version and never touches `zsh_functions/local.zsh`.

## Project structure

After `./setup.sh`, the active config lives under `~/.config/zsh` (or your `INSTALL_DIR`):

```
~/.config/zsh/
├── zshrc               # Main config (sourced from ~/.zshrc)
└── zsh_functions/      # Sourced automatically
    ├── unplugged.zsh   # Plugin loader (Pure, autosuggestions, etc.)
    ├── nvm.zsh         # NVM / Node
    ├── pyenv.zsh       # Optional pyenv
    └── local.zsh       # Optional machine-only overrides (create yourself)
```

The repo you cloned only needs to exist while you run `setup.sh`; it is copied into the folder above.

## Customization

- **History file** – Uses `~/.zsh_history` (user home). Setup never copies or overwrites it. Override with `HISTFILE` in `zsh_functions/local.zsh` if you want a different path.
- **Plugins** – Edit the `plugins` array in `~/.config/zsh/zsh_functions/unplugged.zsh`. Plugins are cloned into `~/.config/zsh/plugins`.
- **Local overrides** – Create `~/.config/zsh/zsh_functions/local.zsh` for machine-only aliases and options (it is not overwritten by setup).

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
