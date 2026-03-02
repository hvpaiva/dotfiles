# dotfiles

Personal dotfiles for Arch Linux and macOS, managed with [chezmoi](https://www.chezmoi.io/).

> **Personal project.** Public as inspiration only — not intended to be used by others as-is,
> no stability guarantees, may break without notice.

---

## Fresh machine

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply hvpaiva
```

On **macOS**, the profile is detected automatically. On **Linux**, you'll be asked a couple of questions:

**Profile** — the hardware this machine runs on:

| Value | When to use | What it changes |
|-------|-------------|-----------------|
| `desktop` | Arch desktop with NVIDIA GPU | Installs NVIDIA drivers and Steam. `monitors.conf` auto-detects all connected monitors. |
| `notebook` | Arch laptop with built-in display | No NVIDIA/gaming packages. `monitors.conf` targets `eDP-1` at 2x scale. |

**Purpose** — what you use this machine for (asked on all platforms):

| Value | When to use | What it adds |
|-------|-------------|--------------|
| `personal` | Personal use only | Nothing extra beyond core + dev + apps. |
| `work` | Work use only | Adds `terraform`, `tflint`, `helm`, `cursor`. |
| `both` | Personal + work | Same as `work` — adds the work tools. |

**Git email** — used in `~/.config/git/config`. Defaults to `contact@hvpaiva.dev`.

---

## What each platform gets

**Arch Linux** (profiles `desktop` / `notebook`):
- Full Hyprland + Waybar + Omarchy desktop environment
- Packages via pacman/yay with automatic drift tracking
- systemd user services

**macOS** (profile `macos`):
- Terminal environment: shell, editor, CLI tools, dev tools, apps
- Packages via Homebrew (`Brewfile` / `Brewfile.work`)
- No WM config — use whatever macOS setup you prefer

**Both**:
- bash + ble.sh, fish, starship, tmux
- neovim, lazygit, lazydocker, mise, sesh
- fzf, ripgrep, fd, bat, eza, zoxide and the usual CLI toolkit
- git config, SSH via 1Password agent, all language runtimes via mise

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

To edit directly on disk and sync back:

```bash
nvim ~/.config/some/file
chezmoi re-add ~/.config/some/file
chezmoi cd && git add -A && git commit -m "..." && git push
```

---

## Syncing across machines

After changing something on machine A:

```bash
chezmoi cd
git add -A && git commit -m "..." && git push
```

On machine B:

```bash
chezmoi update   # pulls from git and applies
```

Configs that vary per machine (e.g. `monitors.conf`) are templates — each machine
renders its own version from `chezmoi.toml`. No conflicts.

---

## Packages

**Linux** — tracked in `~/.config/packages/` as plain text lists (`NAME ORIGIN`).

New package installed? The pacman hook appends it automatically to `uncategorized.txt`.
Move it to the right category file when convenient.

Check for drift (installed but not tracked, or tracked but not installed):

```bash
~/.config/scripts/pkg-reconcile.sh
```

**macOS** — managed via Homebrew bundle:

```bash
brew bundle --file=~/.config/packages/Brewfile
```

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
