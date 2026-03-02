# dotfiles

Personal dotfiles for Arch Linux + Hyprland + Omarchy, managed with [chezmoi](https://www.chezmoi.io/).

> **Personal project.** Public as inspiration only — not intended to be used by others as-is,
> no stability guarantees, may break without notice.

---

## Fresh machine

Requires Arch Linux + Omarchy already installed. Then:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply hvpaiva
```

### What you'll be asked

**Profile** — the hardware this machine runs on:

| Value | When to use | What it changes |
|-------|-------------|-----------------|
| `desktop` | Desktop with NVIDIA GPU | Installs NVIDIA drivers (`nvidia-open-dkms`, `nvidia-utils`, `lib32-nvidia-utils`) and Steam. `monitors.conf` auto-detects all connected monitors. |
| `notebook` | Laptop with built-in display | No NVIDIA/gaming packages. `monitors.conf` targets `eDP-1` at 2x scale. |

**Purpose** — what you use this machine for:

| Value | When to use | What it adds |
|-------|-------------|--------------|
| `personal` | Personal use only | Nothing extra beyond core + dev + apps. |
| `work` | Work use only | Adds `terraform`, `tflint`, `helm`, `cursor-bin`. |
| `both` | Personal + work | Same as `work` — adds the work tools. |

**Git email** — used in `~/.config/git/config`. Defaults to `contact@hvpaiva.dev`.

---

## Profiles

Profile values are stored in `~/.config/chezmoi/chezmoi.toml`. To change them:

```bash
chezmoi init --data=false   # re-prompts for all values
chezmoi apply
```

---

## Daily usage

```bash
chezmoi edit ~/.config/hypr/bindings.conf  # open config in $EDITOR via chezmoi
chezmoi diff                                # preview what would change on disk
chezmoi apply                               # apply source → disk
chezmoi add ~/.config/new-app/config        # start tracking a new file
chezmoi re-add ~/.config/some/file          # sync disk changes back to source
chezmoi update                              # git pull + apply (use on other machines)
```

To edit directly on disk and sync back:

```bash
nvim ~/.config/hypr/bindings.conf
chezmoi re-add ~/.config/hypr/bindings.conf
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

Packages are tracked in `~/.config/packages/` as plain text lists (`NAME ORIGIN`).

**New package installed?** The pacman hook appends it automatically to `uncategorized.txt`.
Move it to the right category file when convenient.

**Check for drift** (installed but not tracked, or tracked but not installed):

```bash
~/.config/scripts/pkg-reconcile.sh
```

**Manually install all packages for this profile:**

```bash
~/.config/scripts/install_pkgs.sh \
  ~/.config/packages/core.txt \
  ~/.config/packages/dev.txt \
  ~/.config/packages/apps.txt
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

---

## Does it work on macOS?

No. Bootstrap scripts use `pacman`/`yay`, configs assume Hyprland/Wayland,
services target systemd. macOS would need a separate profile and scripts from scratch.
