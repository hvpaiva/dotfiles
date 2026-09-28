# dotfiles

The personal layer on top of [Omarchy](https://omarchy.org), for two machines:

| host | system | Omarchy comes from |
|---|---|---|
| **zeus** | Arch | the `omarchy` package |
| **athena** | Ubuntu 24.04 | [hvpaiva/omarchy-ubuntu](https://github.com/hvpaiva/omarchy-ubuntu), a port that keeps Ubuntu and layers Omarchy on top |

Omarchy stays Omarchy: nothing under `/usr/share/omarchy`, none of the template copies it
drops into `~/.config`, and none of the files the Ubuntu port installs into `$HOME` live
here. This repo holds only what diverges from those defaults, and a bootstrap that turns a
fresh install into the same machine.

## Quick start

```sh
bash <(curl -fsSL https://raw.githubusercontent.com/hvpaiva/dotfiles/master/.config/dotfiles/bootstrap.sh)
```

Needs `git` (Arch: `sudo pacman -S git`, Ubuntu: `sudo apt install git`). Everything
else the script installs itself. On Ubuntu it first runs the omarchy-ubuntu bootstrap,
which asks for your password and takes 20–40 minutes the first time.

The script is idempotent. Running it again is how a machine gets repaired: it pulls the
repo, re-links the per-host files, installs whatever is missing and ends with a report of
anything that drifted from the repo. `--reset` throws local edits to tracked files away.

```
bootstrap.sh [--host NAME] [--reset] [--skip-omarchy] [--skip-private] [--skip-mise] [--skip-rust]
```

For the private layer and for pushing, the machine needs a GitHub SSH key (the 1Password
agent). Without it the bootstrap skips that step and says so; run it again later.

## What you get

- **bash** — Omarchy's `default/bash/rc` sourced whole, then only what diverges:
  `~/.config/bash/{envs,aliases,functions,prompt,pkg-track}`. One pager everywhere
  (`less`, `LESS=-FRi`), man pages coloured through `LESS_TERMCAP` in the eight ANSI
  colours so they follow the theme. `ri` renders Markdown through glow; `riv` opens Ruby
  docs in a scratch nvim buffer. `pkg-track` wraps `cargo/npm/go/pipx install` and records
  what you installed. No starship.
- **ble.sh** — vi mode with a coloured mode indicator, transient prompt, shared history,
  fzf integration and [augur](https://github.com/hvpaiva/augur) inline suggestions.
- **tmux and herdr** — Omarchy's configuration read straight from the package
  (`source-file /usr/share/omarchy/config/tmux/tmux.conf`), plus `extras.conf`: tpm
  plugins under `~/.local/share/tmux`, sesh on `prefix+s`, resurrect/continuum, yank.
  herdr has no include mechanism, so its file is Omarchy's with three marked additions.
- **terminals** — alacritty, ghostty, kitty and foot, all on `MesloLGLDZ Nerd Font Mono` 11.
- **git** — shared config with global hooks (`~/.config/git/hooks`) that strip AI
  attribution trailers, run the repository's own hooks (a global `core.hooksPath` would
  otherwise disable them) and a per-host hook if present. Identity comes from the per-host
  layer.
- **mise** — one `config.toml` with every tool wanted on every machine, mise first over
  distro packages (herdr, zoxide, sesh, cliamp, try, tree-sitter…). Per-host pins live in
  `conf.d/local.toml`.
- **neovim** — [hvpaiva/nvim](https://github.com/hvpaiva/nvim), its own repo, declared here
  as a submodule so a clone cannot forget it; the bootstrap keeps it on `main`.
- **Omarchy personal bits** — hypr bindings, menu extension, branding, default agent, the
  list of extra themes (`omarchy/themes.txt`) the bootstrap installs, `shell.toml`.
- **package lists** — `packages/universal` (cargo, go, npm, pip), `packages/arch`,
  `packages/ubuntu`, with the pacman hook scripts that keep the Arch lists current.

## Layout

```
~/.gitignore                  whitelist: the manifest of everything tracked
~/.bashrc ~/.bash_profile ~/.profile ~/.XCompose ~/.inputrc ~/.gitmodules
~/.config/
  bash/ blesh/ tmux/ herdr/ git/ mise/ alacritty/ ghostty/ kitty/ foot/
  omarchy/{extensions,branding,defaults,hooks/post-update.d/setup-agent.hook,themes.txt,shell.toml}
  hypr/bindings.lua  uwsm/default  autostart/com.onepassword.OnePassword.desktop
  hldr/ sesh/ tensaku/ fastfetch/ aether/theme.override.css  packages/ scripts/
  nvim/                       submodule → hvpaiva/nvim
  dotfiles/
    bootstrap.sh              the script above
    hosts/<host>/             per-host, non-sensitive files (symlinked into $HOME)
    test/container.sh         runs the bootstrap twice in a clean Arch or Ubuntu container
```

## How it works

A bare repository at `~/.dotfiles` with `$HOME` as the work tree, so tracked files sit
exactly where the programs read them, with no symlinks. That matters because Omarchy edits
some of these files in place: `omarchy-font-set` runs `sed -i` on the terminal configs and
migrations move files to `.bak`, both of which would silently break a symlink.

`~/.gitignore` is a whitelist: everything is ignored unless listed, so `dots status`
reports only files inside the boundary — including new ones you forgot to add — and never
the app state, caches or upstream copies around them.

```sh
alias dots='git --git-dir="$HOME/.dotfiles" --work-tree="$HOME"'   # defined in bash/aliases
dots status                   # what changed, what is new inside the boundary
dots add -u && dots commit && dots push
dots pull                     # on the other machine; files are already in place
dots diff origin/master       # did the other machine move?
```

### Per-host files

Two trees, same layout (`<path relative to $HOME>`), both symlinked into place by the
bootstrap:

| tree | holds | examples |
|---|---|---|
| `~/.config/dotfiles/hosts/<host>/` (this repo) | machine-specific but harmless | `hypr/monitors.lua`, `git/local` identity, `tmux/local.conf` label, `mise/conf.d/local.toml` pins, `.profile.local` paths |
| `hvpaiva/dotfiles-private` → `~/.local/share/dotfiles-private/hosts/<host>/` | anything that should not be public | account ids, internal endpoints, `omarchy/shell.json` |

The host name is read from `~/.config/dotfiles/host` (written by `bootstrap.sh --host`).
Files that programs rewrite in place (omarchy-shell rewrites `shell.json`, the monitor
panel rewrites `monitors.lua`) turn from a link into a regular file; on the next bootstrap
run the live file wins: it is copied back into its tree and re-linked, and shows up in
`dots status` / `dotp status` for you to commit.

The shared files have hooks for both trees: `bash/rc` sources `bash/local` then
`bash/private`, `.profile` sources `.profile.local` then `.profile.private`, `git/config`
includes `git/local` and `git/private`, mise reads everything in `conf.d/`, tmux sources
`local.conf`, ble.sh sources `blesh/local.sh`.

## Decisions

- One pager. `bat` is a viewer you call by hand, never a `$PAGER`: as a pager it gets stdin
  with no file name, so it cannot detect a syntax, and it turns a file `less` would seek
  into a pipe it must read to the end.
- Omarchy's tmux and herdr configuration as the base, personal additions on top, prefix
  `C-Space`. The status line follows the terminal palette, so it follows the theme.
- `MesloLGLDZ Nerd Font Mono`, size 11, applied by `omarchy-font-set` (fontconfig) with the
  terminal files restored from the repo afterwards, because font-set also pins foot to size 9.
- mise first, on both distros, for everything mise can provide.
- Per-host does not mean private. Only sensitive content goes to the private repo.

## Repairing drift

`dots status` clean means the machine matches the repo. If it is not:

- keep the change: `dots add -u && dots commit && dots push`, then `dots pull` on the other
  machine (or run the bootstrap there);
- drop it: `bootstrap.sh --reset`.

The bootstrap moves pre-existing files it would overwrite to
`~/.local/state/dotfiles/pre-checkout-<date>/`, never deletes them.

## Testing

`~/.config/dotfiles/test/container.sh arch|ubuntu [--full]` runs the bootstrap twice inside a
clean container against a local bare clone of this repo and checks that the second run is a
no-op. `--full` also installs rustup, augur and every mise tool, which takes a while.
