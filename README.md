# dotfiles

Personal dotfiles for Linux and macOS, managed with [chezmoi](https://www.chezmoi.io/).

> **Personal project.** Public as inspiration only — not intended to be used by others as-is,
> no stability guarantees, may break without notice.

---

## Fresh machine

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply hvpaiva
```

On **macOS**, the profile is detected automatically. On **Linux**, you'll be asked a few questions.
The Linux distro is detected automatically from `/etc/os-release`.

**Profile** — the hardware this machine runs on:

| Value | When to use | What it changes |
|-------|-------------|-----------------|
| `desktop` | Desktop with dedicated GPU | Installs GPU drivers and gaming packages. `monitors.conf` auto-detects. |
| `notebook` | Laptop with built-in display | No GPU/gaming packages. `monitors.conf` targets `eDP-1` at 2x scale. |

**Purpose** — what you use this machine for (asked on all platforms):

| Value | When to use | What it adds |
|-------|-------------|--------------|
| `personal` | Personal use only | Nothing extra beyond core + dev + apps. |
| `work` | Work use only | Adds `terraform`, `tflint`, `helm`, `cursor`. |
| `both` | Personal + work | Same as `work` — adds the work tools. |

**Hyprland** — whether to install/configure the Hyprland desktop environment (asked on Linux only).
Defaults to `true` if Omarchy is detected, `false` otherwise. If enabled, deploys Hyprland, Waybar,
walker, swayosd, uwsm, hypridle, hyprlock, and mako configs.

**Git email** — used in `~/.config/git/config`. Defaults to `contact@hvpaiva.dev`.

**Git signing** — commit signing via 1Password SSH agent is enabled automatically when `op` is detected.
If 1Password isn't installed, signing is disabled and commits work normally without GPG/SSH signatures.

---

## What each platform gets

### Common (all platforms)

- bash + ble.sh, starship, tmux
- neovim, lazygit, lazydocker, mise, sesh
- fzf, ripgrep, fd, bat, eza, zoxide and the usual CLI toolkit
- git config, SSH via 1Password agent, language runtimes via mise

### Arch Linux (with Omarchy)

- Full Hyprland + Waybar + Omarchy desktop environment
- Packages via pacman/yay with automatic drift tracking (pacman hook)
- systemd user services (elephant, battery monitor)
- Dynamic theming via Omarchy (ghostty, btop, eza, mako, neovim)

### Arch Linux (without Omarchy)

- All common tools + Arch package management
- Standalone Catppuccin Mocha theme for neovim
- No Hyprland/Waybar/Omarchy configs deployed

### Ubuntu / Debian

- Packages via apt with external repos (Docker, GitHub CLI, mise, Neovim PPA, HashiCorp)
- Binary installs for tools not in apt (starship, ghostty, lazygit, lazydocker, sesh, gum, Nerd Fonts)
- Handles `bat`→`batcat` and `fd`→`fdfind` renames via symlinks + aliases
- Optional Hyprland desktop (via PPA) with standalone Catppuccin Mocha configs
- Walker, SwayOSD, uwsm installed from GitHub releases when Hyprland is enabled

### Other Linux distros

- All common tools work out of the box
- System package installation is skipped (see "Adding support for a new distro" below)
- Desktop-environment configs are only deployed if the corresponding tools are detected

### macOS

- Terminal environment: shell, editor, CLI tools, dev tools, apps
- Packages via Homebrew (`Brewfile` / `Brewfile.work`)
- No WM config

---

## Architecture

The repository is organized in layers that activate based on detected features:

| Layer | Condition | What it includes |
|-------|-----------|-----------------|
| **Core** | Always | bash, neovim, git, tmux, starship, CLI tools |
| **Desktop (Hyprland)** | `has_hyprland = true` | hypr, waybar, walker, swayosd, uwsm, autostart |
| **Omarchy** | `has_omarchy = true` (auto-detected) | themes, elephant, battery monitor, aether |
| **Distro (Arch)** | `distro = "arch"` | pacman packages, hooks, safe-update, pkg-reconcile |
| **Distro (Ubuntu)** | `distro = "ubuntu"` | apt packages, PPAs, binary extras |
| **Distro (macOS)** | `chezmoi.os = "darwin"` | Homebrew Brewfiles |

### Package structure

```
packages/
├── universal/         # cargo, npm, go, pip — same on all platforms
│   ├── cargo.txt
│   ├── npm.txt
│   ├── go.txt
│   └── pip.txt
├── arch/              # Arch Linux (pacman/yay/paru)
│   ├── core.txt
│   ├── dev.txt
│   ├── apps.txt
│   ├── desktop.txt    # profile=desktop only
│   ├── gaming.txt     # profile=desktop only
│   ├── work.txt       # purpose=work|both
│   └── uncategorized.txt
├── ubuntu/            # Ubuntu/Debian (apt)
│   ├── core.txt
│   ├── dev.txt
│   ├── apps.txt
│   ├── desktop.txt    # has_hyprland=true
│   ├── work.txt       # purpose=work|both
│   ├── install_pkgs.sh
│   ├── ppas-and-repos.sh
│   └── install-extras.sh
└── macos/             # macOS (Homebrew)
    ├── Brewfile
    └── Brewfile.work  # purpose=work|both
```

### Adding support for a new distro

1. Create `~/.local/share/chezmoi/dot_config/packages/<distro>/` with package lists
2. Add an installer branch in `run_once_after_01-install-packages.sh.tmpl`
3. (Optional) Add distro-specific scripts to `dot_config/scripts/`
4. Run `chezmoi init` to refresh the distro detection, then `chezmoi apply`

---

## Profiles

Profile values are stored in `~/.config/chezmoi/chezmoi.toml`. To re-prompt:

```bash
chezmoi init --data=false
chezmoi apply
```

---

## Daily usage

```bash
chezmoi diff                          # preview what would change on disk
chezmoi apply                         # apply source → disk
chezmoi add ~/.config/new-app/config  # start tracking a new file
chezmoi re-add ~/.config/some/file    # sync disk changes back to source
chezmoi update                        # git pull + apply (use on other machines)
```

---

## Packages

**Arch Linux** — tracked in `~/.config/packages/arch/` as plain text lists (`NAME ORIGIN`).

New package installed? The pacman hook appends it automatically to `uncategorized.txt`.
Move it to the right category file when convenient.

Check for drift (installed but not tracked, or tracked but not installed):

```bash
~/.config/scripts/pkg-reconcile.sh
```

**Ubuntu/Debian** — tracked in `~/.config/packages/ubuntu/` as plain text lists (one package per line).
External repos and binary tools are installed automatically on first `chezmoi apply`.

**macOS** — managed via Homebrew bundle:

```bash
brew bundle --file=~/.config/packages/macos/Brewfile
```

**Universal** — cargo, npm, go, pip packages tracked in `~/.config/packages/universal/`.
Use the shell wrappers `ci`, `ni`, `gi`, `pi` to install + auto-track.

---

## Secrets

No secrets in this repo. Private SSH key lives in 1Password, accessed via its SSH agent:

```
# ~/.ssh/config
Host *
    IdentityAgent ~/.1password/agent.sock
```

The `cargo-aoc` session token and anything else sensitive lives exclusively in 1Password.
If 1Password isn't running, those files render empty — sign in and re-run `chezmoi apply`.
