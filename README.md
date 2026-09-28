# dotfiles

The personal layer on top of [Omarchy](https://omarchy.org), for two machines:

| host | system | Omarchy comes from |
|---|---|---|
| **zeus** | Arch | the `omarchy` package |
| **athena** | Ubuntu 24.04 | [hvpaiva/omarchy-ubuntu](https://github.com/hvpaiva/omarchy-ubuntu), a port that keeps Ubuntu and layers Omarchy on top |

Omarchy stays Omarchy: nothing under `/usr/share/omarchy`, none of the template copies it
drops into `~/.config`, and none of the files the Ubuntu port installs into `$HOME` live
here. This repo holds only what diverges from those defaults, a script that turns a fresh
install into the same machine, and `dots`, the command that keeps it that way.

## Quick start

On a fresh Arch + Omarchy install, or a fresh Ubuntu 24.04:

```sh
bash <(curl -fsSL https://raw.githubusercontent.com/hvpaiva/dotfiles/master/bootstrap.sh)
```

That is the whole install. The script installs `git` if the machine lacks it, clones this
repo and hands over to `dots setup`, which does the rest and says what it is doing as it
goes:

1. the build dependencies mise cannot provide (compilers, headers, tmux, fontconfig);
2. on Ubuntu, Omarchy itself through the omarchy-ubuntu bootstrap (asks for your password,
   20–40 minutes the first time);
3. the per-host layers: public files from `hosts/<host>/`, sensitive ones from the private
   repo (needs the GitHub SSH key; skipped with a warning until it works);
4. [hvpaiva/nvim](https://github.com/hvpaiva/nvim) on `main`;
5. the distro packages this layer replaces with mise's copy (Omarchy ships `mise-bin`,
   `zoxide`, `herdr`, `cliamp`, `tobi-try`, `tree-sitter-cli`, `starship`; they go);
6. rustup and [augur](https://github.com/hvpaiva/augur), ble.sh, tmux plugins, the official
   mise build in `~/.local/bin` and every tool in `mise/config.toml`;
7. the terminal font and the extra Omarchy themes;
8. `dots doctor`, then a summary of anything that did not go as planned. The full output is
   kept in `~/.local/state/dotfiles/setup.log`.

Every step checks before acting, so running it again repairs a machine instead of
redoing it. Options: `--host NAME` (which per-host layers to use; asked on the first run),
`--reset` (drop local edits to tracked files), `--skip-omarchy`, `--skip-private`,
`--skip-mise`, `--skip-rust`.

## Day to day: `dots`

Three repositories make up a machine, and `dots` fronts all of them so you never have to
think about which one a change belongs to:

| repo | where | holds |
|---|---|---|
| dotfiles | `~/.dotfiles`, bare, `$HOME` is the work tree | everything shared, plus `hosts/<host>/` |
| private | `~/.local/share/dotfiles-private` | sensitive per-host files, and `common/` for every host |
| nvim | `~/.config/nvim` | the editor config, recorded here as a submodule pointer |

```
dots            what changed here, what is waiting on origin, what the machine lacks
dots save       commit and push every change, every repo
dots update     bring the machine up to date: repos, per-host links, tools
dots doctor     check the machine against the intended state, installs included
dots setup      install or repair the whole layer (what the one-liner runs)
```

`dots help`, `dots help <command>` and `man dots` document every command and flag; the
output follows kubectl's shape (tables, one object per row, states coloured by meaning):

```
$ dots
REPO       BRANCH   CHANGES     ORIGIN      NVIM
dotfiles   master   2 changed   in sync
private    main     clean       in sync
nvim       main     clean       in sync     recorded

PATH                        STATE       REPO
.config/bash/aliases        modified    dotfiles
.config/scripts/new-thing   untracked   dotfiles

HOST   LINKS   CHECKS
zeus   5/5     ok
```

Edit a file where the program reads it, `dots save` on this machine, `dots update` on the
other. New files inside the tracked boundary show up as `untracked` instead of silently
staying behind. The `CHECKS` column is the difference between "the files match" and "the
machine is what the files say": `dots doctor` spells out every check (mise tools, rustup,
augur, ble.sh, tmux plugins, per-host links, distro packages that came back, processes
still on a replaced binary, font, themes, a real login shell, GitHub over SSH).

If a program replaces one of the per-host links with a plain file (omarchy-shell rewrites
`shell.json`, the monitor panel rewrites `monitors.lua`), the live file wins: `dots save`
and `dots update` copy it back into its tree, restore the link and show it as a change.

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
- **mise** — the official build in `~/.local/bin`, one `config.toml` with every tool wanted
  on every machine, mise first over distro packages (herdr, zoxide, sesh, cliamp, try,
  tree-sitter, glow…). Per-host pins live in `conf.d/local.toml`. Rust comes from rustup.
- **neovim** — [hvpaiva/nvim](https://github.com/hvpaiva/nvim), its own repo, declared here
  as a submodule so a clone cannot forget it; `dots update` keeps it on `main` and
  `dots save` records the commit in use.
- **Omarchy personal bits** — hypr bindings, default agent, the list of extra themes
  (`omarchy/themes.txt`), `shell.toml`.
- **package lists** — `packages/universal` (cargo, go, npm) written by the `ci`/`ni`/`gi`
  wrappers, and `packages/arch`, kept current by a pacman hook that `dots setup` installs.

## Layout

```
README.md  bootstrap.sh  .github/    the repo root; kept out of $HOME by a sparse checkout
~/.gitignore                          whitelist: the manifest of everything tracked
~/.bashrc ~/.bash_profile ~/.profile ~/.XCompose ~/.inputrc ~/.gitmodules
~/.local/bin/dots                     the command above
~/.local/share/bash-completion/completions/dots
~/.local/share/man/man1/dots.1        man dots
~/.config/
  bash/ blesh/ tmux/ herdr/ git/ mise/ alacritty/ ghostty/ kitty/ foot/
  omarchy/{defaults,hooks/post-update.d/setup-agent.hook,themes.txt,shell.toml}
  hypr/bindings.lua  uwsm/default  autostart/com.onepassword.OnePassword.desktop
  sesh/ tensaku/  packages/ scripts/
  nvim/                               submodule → hvpaiva/nvim
  dotfiles/
    hosts/<host>/                     per-host, non-sensitive files (symlinked into $HOME)
    host                              which host this machine is (written by dots setup, untracked)
    test/container.sh                 the one-liner in a clean Arch or Ubuntu container
    test/dots.bats                    unit tests for dots
```

## How it works

A bare repository at `~/.dotfiles` with `$HOME` as the work tree, so tracked files sit
exactly where the programs read them, with no symlinks. That matters because Omarchy edits
some of these files in place: `omarchy-font-set` runs `sed -i` on the terminal configs and
migrations move files to `.bak`, both of which would silently break a symlink.

`~/.gitignore` is a whitelist: everything is ignored unless listed, so `dots` reports only
files inside the boundary — including new ones you forgot to add — and never the app
state, caches or upstream copies around them.

`README.md`, `bootstrap.sh` and `.github/` sit at the repo root so GitHub shows them, but
nobody wants them in `$HOME`: a sparse checkout (`~/.dotfiles/info/sparse-checkout`) keeps
them out of the work tree. `dots root show` brings them in to edit, `dots root hide` takes
them out again.

### Per-host files

Two trees, same layout (`<path relative to $HOME>`), both symlinked into place:

| tree | holds | examples |
|---|---|---|
| `~/.config/dotfiles/hosts/<host>/` (this repo) | machine-specific but harmless | `hypr/monitors.lua`, `git/local` identity, `tmux/local.conf` label, `mise/conf.d/local.toml` pins, `.profile.local` paths |
| `hvpaiva/dotfiles-private` → `~/.local/share/dotfiles-private/hosts/<host>/` | anything that should not be public | account ids, internal endpoints, `omarchy/shell.json` |

Per-host does not mean private: only sensitive content goes to the private repo. The
shared files have hooks for both trees: `bash/rc` sources `bash/local` then `bash/private`,
`.profile` sources `.profile.local` then `.profile.private`, `git/config` includes
`git/local` and `git/private`, mise reads everything in `conf.d/`, tmux sources
`local.conf`, ble.sh sources `blesh/local.sh`.

## Decisions

- One pager. `bat` is a viewer you call by hand, never a `$PAGER`: as a pager it gets stdin
  with no file name, so it cannot detect a syntax, and it turns a file `less` would seek
  into a pipe it must read to the end.
- Omarchy's tmux and herdr configuration as the base, personal additions on top, prefix
  `C-Space`. The status line follows the terminal palette, so it follows the theme.
- `MesloLGLDZ Nerd Font Mono`, size 11, applied by `omarchy-font-set` (fontconfig) with the
  terminal files restored from the repo afterwards, because font-set also pins foot to size 9.
- mise first, on both distros, for everything mise can provide; the distro copies are
  removed so there is one of each tool. mise itself is the official build, not a package.
- No symlinks for shared files (see above); symlinks only for the per-host trees, where the
  live file wins if a program breaks the link.

## Testing and CI

`bats .config/dotfiles/test` runs the unit tests for `dots` (bats comes from mise): the
pure helpers, and the git-backed ones against throwaway repositories, with no network and
no sudo.

`.config/dotfiles/test/container.sh arch|ubuntu [--full]` runs the one-liner twice inside a
clean container that has only what a fresh desktop install guarantees (on Ubuntu not even
git), checks that the second run is a no-op and that the build dependencies were installed
and the distro copies removed, then exercises `dots save` and `dots update` against the
local origin. `--full` also installs rustup, augur and every mise tool, which takes a while.

The GitHub workflow runs shellcheck, the unit tests and the quick container test for both
distros on every push, and the full container test weekly.
