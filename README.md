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

You'll be prompted for:
- **Profile**: `desktop` (NVIDIA, gaming) or `notebook` (built-in display)
- **Purpose**: `personal`, `work`, or `both` (adds terraform, helm, cursor)
- **Git email**

That's it. Packages install, configs apply, shell and services are set up.

---

## Profiles

Stored in `~/.config/chezmoi/chezmoi.toml`. To change profile after the fact:

```bash
chezmoi init --data=false   # re-prompts for all values
chezmoi apply
```

What each profile affects:

| Variable | Options | Affects |
|----------|---------|---------|
| `profile` | `desktop`, `notebook` | monitors.conf, NVIDIA packages, gaming packages |
| `purpose` | `personal`, `work`, `both` | work packages (terraform, helm, cursor-bin) |
| `git_email` | any email | `~/.config/git/config` |

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

To edit directly on disk and sync back to the repo:

```bash
# Edit normally
nvim ~/.config/hypr/bindings.conf

# Sync the change back to chezmoi source
chezmoi re-add ~/.config/hypr/bindings.conf

# Commit and push
chezmoi cd
git add -A && git commit -m "..." && git push
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

If a config varies per machine (e.g. monitors), it's a template — each machine
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
If 1Password isn't running, those files are rendered empty — sign in and re-run `chezmoi apply`.

---

## Does it work on macOS?

No. The bootstrap scripts use `pacman`/`yay`, configs assume Hyprland/Wayland,
and services target systemd. macOS would need a separate profile and scripts.

---

## Simulate a fresh machine

To test the bootstrap without a real machine:

```bash
# Build a clean Arch Linux container
docker build -t arch-fresh -f ~/.local/share/chezmoi/test/Dockerfile.bootstrap \
  ~/.local/share/chezmoi/test/

# Enter it — you're now a fresh machine
docker run -it --rm arch-fresh

# Inside the container, run the real bootstrap:
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply hvpaiva
```

Note: `run_once_after` scripts will run. Package installation may be partial
(AUR/yay needs real mirrors); configs and templates apply fully.
