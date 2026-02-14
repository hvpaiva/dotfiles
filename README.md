# dotfiles

Dotfiles for Arch Linux + [Hyprland](https://hyprland.org/) + [Omarchy](https://omarchy.com/), managed with [chezmoi](https://www.chezmoi.io/).

## Bootstrap

On a fresh machine with Arch/Omarchy installed:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply hvpaiva
```

chezmoi will:

1. Ask for the machine **profile** (`desktop` or `notebook`)
2. Ask for the **purpose** (`personal`, `work`, or `both`)
3. Ask for the **git email**
4. Apply all configs
5. Install all packages for the selected profile
6. Set up the pacman hook for automatic tracking
7. Set fish as the default shell, activate mise and systemd services

## Structure

```
~/.local/share/chezmoi/
├── .chezmoi.toml.tmpl          # Profile prompts (desktop/notebook, work/personal)
├── .chezmoiignore              # Per-profile exclusions
├── run_once_after_01-*         # Install packages
├── run_once_after_02-*         # Install pacman hook
├── run_once_after_99-*         # Final setup (shell, mise, systemd)
│
├── dot_config/
│   ├── packages/               # Categorized lists (249 packages)
│   ├── hypr/                   # Hyprland (templated monitors.conf)
│   ├── nvim/                   # Neovim (LazyVim)
│   ├── git/                    # Git (templated email)
│   ├── fish/ bash/ tmux/       # Shell
│   ├── ghostty/                # Terminal
│   ├── waybar/ mako/ walker/   # Desktop UI
│   ├── scripts/                # install_pkgs.sh, pkg-reconcile.sh, etc.
│   └── ...                     # btop, eza, lazygit, mise, sesh, etc.
│
├── private_dot_ssh/            # SSH config + public key
│                               # (private key lives in 1Password)
└── test/
    └── run-tests.sh            # Automated test suite
```

## Profiles

chezmoi uses templates to adapt configs per machine:

| Variable | Options | Affects |
|----------|---------|---------|
| `profile` | `desktop`, `notebook` | monitors.conf, nvidia/gaming packages |
| `purpose` | `personal`, `work`, `both` | terraform/helm/cursor packages |
| `git_email` | any email | git config |

Values are stored in `~/.config/chezmoi/chezmoi.toml` (generated during `chezmoi init`).

### Monitors

- **desktop**: `monitor=,preferred,auto,auto` (auto-detect)
- **notebook**: `monitor=eDP-1,preferred,auto,2` (built-in display at 2x)

## Package management

### Categories

The 249 packages are split into 6 lists under `~/.config/packages/`:

| File | When installed | Examples |
|------|---------------|----------|
| `core.txt` | Always | base, hyprland, fish, pipewire, fonts |
| `dev.txt` | Always | git, neovim, docker, rust, mise |
| `apps.txt` | Always | 1password, zen-browser, signal, spotify |
| `desktop.txt` | profile=desktop | nvidia-open-dkms, steam |
| `work.txt` | purpose=work\|both | terraform, helm, cursor-bin |
| `gaming.txt` | profile=desktop | retroarch + 33 libretro cores |

Format: one line per package, `NAME ORIGIN` (pacman/yay/paru).

### Automatic tracking

A pacman hook (`/etc/pacman.d/hooks/pkg-snapshot-append.hook`) detects newly installed packages and appends them to `~/.config/packages/uncategorized.txt`. You then move them to the appropriate category.

### Reconciliation

```bash
~/.config/scripts/pkg-reconcile.sh
```

Shows packages that are installed but not in any list, and packages in the lists that are not installed.

### Manual installation

```bash
~/.config/scripts/install_pkgs.sh ~/.config/packages/core.txt ~/.config/packages/dev.txt
```

Installs in batch by origin (pacman first, then yay/paru). If the batch fails, it retries individually and reports which ones failed.

## Secrets

No secrets in this repository. The private SSH key lives in the [1Password](https://1password.com/) vault and is accessed via the SSH agent:

```
# ~/.ssh/config
Host *
    IdentityAgent ~/.1password/agent.sock
```

The Advent of Code token (`cargo-aoc`) and other secrets are stored exclusively in 1Password.

## Design decisions

### Why chezmoi instead of stow/bare git?

- **Templates**: configs vary per machine (monitors, git email, nvidia packages)
- **Bootstrap scripts**: `run_once_after_*` install packages and configure services automatically
- **Smart ignore**: `.chezmoiignore` supports templates — ignores `desktop.txt` when profile=notebook
- **Non-destructive merge**: chezmoi never overwrites without showing a diff first

### Why package lists in .txt instead of in the script?

- **Readability**: easy to see/edit what is installed
- **Reconciliation**: `pkg-reconcile.sh` compares declared vs installed
- **Automatic hook**: new packages go to `uncategorized.txt` automatically
- **Profiles**: bootstrap only includes the lists for the selected profile

### Why run_once_after instead of run_once_before?

`before` scripts run *before* chezmoi applies the files. On the first run, the package scripts and `.txt` lists don't exist yet. That's why we use `after` — it ensures everything has been copied before attempting to install.

### Why not version fish_variables?

`fish_variables` contains runtime state (PATH, plugin variables). Each machine generates its own. Versioning it would cause constant conflicts.

### Why keep lazy-lock.json?

The Lazy.nvim lockfile ensures reproducible plugin versions. It works like a `package-lock.json` — when applying on a new machine, plugins are installed at the same versions.

## Tests

### Repository validation

```bash
cd ~/.local/share/chezmoi
./test/run-tests.sh
```

The suite validates:

- **Structure**: essential files exist, no accidental `run_once_before`
- **Packages**: no duplicates, correct format, valid origins, 249+ declared
- **Templates**: syntax ok, profile prompts present
- **Scripts**: `bash -n` on all, shellcheck if available
- **Secrets**: no AWS keys, private keys, or .env in the repo
- **chezmoi**: >100 managed files, templates render correctly

### Bootstrap validation (live machine)

```bash
~/test/validate-bootstrap.sh
```

Run this after `chezmoi init --apply` to verify the live machine state: templates rendered, hooks installed, configs in place, tools available.

## Daily usage

```bash
# Edit a config
chezmoi edit ~/.config/hypr/bindings.conf

# See differences before applying
chezmoi diff

# Apply changes
chezmoi apply

# Add a new file to chezmoi
chezmoi add ~/.config/new-app/config

# Update from another machine
chezmoi update

# Re-initialize (change profile)
chezmoi init --data=false
```

## What the bootstrap does

The single command `sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply hvpaiva` executes, in order:

1. **Installs chezmoi** to `~/.local/bin/`
2. **Clones this repo** to `~/.local/share/chezmoi/`
3. **Asks for profile** (desktop/notebook, personal/work/both, email)
4. **Applies all files** — configs, scripts, SSH, package lists
5. **`run_once_after_01`** — installs yay if needed, then installs all packages in batch
6. **`run_once_after_02`** — installs the pacman hook to `/etc/pacman.d/hooks/`
7. **`run_once_after_99`** — sets fish as default shell, installs mise runtimes, fisher plugins, systemd services

Result: fully configured machine. Open a terminal, log into Hyprland, ready to go.
