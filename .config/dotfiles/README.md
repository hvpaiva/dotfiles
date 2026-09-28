# dotfiles

The personal layer on top of Omarchy, for both machines:

- **zeus** — Arch, Omarchy from the `omarchy` package (`/usr/share/omarchy`).
- **athena** — Ubuntu 24.04, Omarchy through [omarchy-ubuntu](https://github.com/hvpaiva/omarchy-ubuntu)
  in dev-link mode (`/usr/share/omarchy` → `~/.local/share/omarchy`).

Upstream Omarchy stays upstream: nothing under `/usr/share/omarchy`, none of the
template copies it drops into `~/.config`, and none of the files the Ubuntu port
installs into `$HOME` are tracked here. `~/.config/nvim` is its own repo
([hvpaiva/nvim](https://github.com/hvpaiva/nvim)).

## How it works

A bare repository at `~/.dotfiles` with `$HOME` as the work tree. Files stay where
the programs expect them — no symlinks, because Omarchy edits some of them in place
(`omarchy-font-set` runs `sed -i` on the terminal configs, migrations move files to
`.bak`). `~/.gitignore` is a whitelist and doubles as the manifest: everything is
ignored unless listed there, so `dots status` reports only files inside the boundary,
including new ones you forgot to add.

```
alias dots='git --git-dir="$HOME/.dotfiles" --work-tree="$HOME"'   # in bash/aliases
dots status            # what changed, what is new inside the boundary
dots add -u; dots commit; dots push
dots pull              # on the other machine; files are already in place
dots diff origin/master   # did the other machine move?
```

## Per-host files (not tracked)

| File | Holds |
|---|---|
| `~/.config/bash/local` | env, aliases, init that only this host needs (work tooling, askpass) |
| `~/.config/git/local` | `[user] email` and `signingkey` |
| `~/.config/tmux/local.conf` | status-line label, host-specific hooks |
| `~/.config/blesh/local.sh` | `BLESH_HOST_LABEL` when the hostname is an asset tag |
| `~/.config/mise/conf.d/local.toml` | tools only this host uses; overrides pins in `config.toml` |
| `~/.config/git/hooks.local/<hook>` | extra git hooks for this host, chained after the shared ones |
| `~/.config/hypr/monitors.lua` | Omarchy's own per-machine file |

## Decisions (2026-09-27)

- One pager: `less`, with `LESS_TERMCAP` colors in the eight ANSI colors so man pages
  follow the theme. `bat` is a file viewer, never a `$PAGER`.
- Bash: Omarchy's `default/bash/rc` is sourced whole, then `~/.config/bash/rc` with only
  what diverges. No starship.
- tmux and herdr: Omarchy's config, with a small `extras.conf` (tmux) or three marked
  additions (herdr, which has no include mechanism).
- Font: `MesloLGLDZ Nerd Font Mono` on both, applied by `omarchy-font-set`; size 11.
- zoxide, herdr and sesh come from mise on both machines, never from the distro.

## New machine

```
git clone --bare git@github.com:hvpaiva/dotfiles.git ~/.dotfiles
git --git-dir=$HOME/.dotfiles --work-tree=$HOME checkout   # back up anything it refuses to overwrite
~/.config/dotfiles/bootstrap.sh
```

Then write the per-host files above (at least `~/.config/git/local`).
