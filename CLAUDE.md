# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A chezmoi-managed dotfiles repository supporting multiple platforms (Arch Linux, Ubuntu/Debian, macOS) and hardware profiles. Files prefixed with `dot_` deploy to `~/.config/` (or `~` for top-level dotfiles). Files ending in `.tmpl` are Go templates rendered by chezmoi using data from `.chezmoi.toml.tmpl`.

## Key Commands

```bash
# Apply changes to the home directory
chezmoi apply

# Preview what would change
chezmoi diff

# Edit a managed file (opens source, applies on save)
chezmoi edit ~/.config/bash/aliases

# Add a new file to chezmoi management
chezmoi add ~/.config/foo/bar

# Run local tests (from repo root)
./test/run-tests.sh

# Validate a bootstrapped machine
./test/executable_validate-bootstrap.sh

# Render a template to see output
chezmoi execute-template < some-file.tmpl
```

CI runs on push to master and PRs via `.github/workflows/test.yml` (shellcheck, template rendering, package list integrity, structure validation).

## Architecture

### Conditional Deployment Layers

The `.chezmoiignore` file conditionally excludes files based on detected platform, profile, and features. Not all files deploy everywhere.

| Layer | Condition | Examples |
|-------|-----------|---------|
| Core | Always | bash, neovim, git, tmux, starship, CLI tools |
| Hyprland desktop | `has_hyprland` | hypr/, waybar/, walker/, mako/, swayosd/ |
| Omarchy theme | `has_omarchy` | omarchy/, elephant/, aether/ |
| Arch-specific | `distro=arch` | pacman hooks, pkg-snapshot, safe-update |
| Ubuntu-specific | `distro_family=debian` | apt PPAs, binary downloads |
| macOS-specific | `distro=darwin` | Brewfile |
| Desktop profile | `profile=desktop` | GPU drivers, gaming packages |
| Work purpose | `purpose=work\|both` | terraform, tflint, helm, cursor |

### Configuration Variables (`.chezmoi.toml.tmpl`)

- **`profile`**: `desktop` / `notebook` / `macos` — hardware type
- **`purpose`**: `personal` / `work` / `both` — determines extra tooling
- **`distro`** / **`distro_family`**: auto-detected from `/etc/os-release`
- **`has_omarchy`**, **`has_hyprland`**, **`has_1password`**: auto-detected feature flags
- **`git_email`**: used in git config template

### Bootstrap Flow

Three `run_once_after_*` scripts execute in order on first apply:
1. **01-install-packages** — distro-specific package installation (pacman/apt/brew)
2. **02-setup-pacman-hook** — Arch only: pacman hook for package tracking
3. **99-finalize** — shell setup, ble.sh, TPM, mise runtimes, cargo/npm/go/pip packages, systemd services, Hyprland session

### Package Lists

Platform-specific lists live under `dot_config/packages/{arch,ubuntu,macos,universal}/`:
- **Arch**: `core.txt`, `dev.txt`, `apps.txt`, `desktop.txt`, `gaming.txt`, `work.txt`, `uncategorized.txt`
- **Ubuntu**: similar `.txt` files plus helper scripts (`executable_ppas-and-repos.sh`, `executable_install_pkgs.sh`, `executable_install-extras.sh`)
- **macOS**: `Brewfile`, `Brewfile.work`
- **Universal**: `cargo.txt`, `npm.txt`, `go.txt`, `pip.txt`

## Conventions

- **Templates**: use chezmoi template functions (`lookPath`, `eq`, `ne`, `output`) and data variables. Check `.chezmoi.toml.tmpl` for available variables.
- **Script naming**: `run_once_after_NN-description.sh.tmpl` — the `NN` controls ordering, `run_once` means it runs only once per content hash.
- **Chezmoi file prefixes**: `dot_` → `.`, `private_` → mode 0600, `executable_` → mode 0755, `exact_` → removes unmanaged files in directory.
- **Package tracking (Arch)**: a pacman hook auto-appends new packages to `uncategorized.txt`. Move them to the appropriate category file.
- **1Password integration**: optional SSH agent and commit signing. Credentials template (`cargo-aoc/credentials.toml.tmpl`) uses `op://` URIs.
- **Hyprland defaults**: `dot_config/hypr/defaults/` contains base configs for standalone (non-Omarchy) setups; machine-specific overrides go in the templated files.
- **uwsm-app fallback**: Hyprland helper scripts (`dot_config/scripts/hypr/`) and binding templates detect `uwsm-app` at runtime/render-time and fall back to direct execution when absent. Always use this pattern when adding new bindings.
- **PATH**: set in `dot_profile` (login shell). Includes `~/.local/bin`, `~/bin`, `~/.go/bin`, `~/go/bin`. Cargo adds `~/.cargo/bin` via `~/.cargo/env`. Do not add PATH exports to `dot_bashrc`.
