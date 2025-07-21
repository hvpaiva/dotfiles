# hvpaiva/dotfiles

```sh
██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗
██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║     ██╔════╝██╔════╝
██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗  ███████╗
██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║
██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗███████║
╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝
```
> Personal macOS environment · dotfiles managed with **Chezmoi**, packages installed by **Bones**.

---

## 🚀 Fresh install

```bash
# clone anywhere you like (example: ~/dotfiles)
git clone https://github.com/hvpaiva/dotfiles
cd ~/dotfiles

# one command does everything
./setup.sh
```

What `setup.sh` does:
1. runs the pre‑built **Bones** binary → installs Homebrew (if missing) and every package in `packages.toml` (including Chezmoi).
2. ensures Chezmoi is current (`brew install chezmoi`).
3. `chezmoi apply --source "$PWD"` → all files land in `$HOME`.

> No Git? Download the repo as a ZIP, extract, then run `./setup.sh`.

---

## 🔄 Update an existing machine

```bash
cd ~/dotfiles   # wherever you cloned it
git pull        # new configs & packages
./setup.sh      # re‑install any missing tools, re‑apply dotfiles
```

---

## 🛠 Core toolkit

| Category | Primary | Secondary |
|----------|---------|-----------|
| **Editor** | Helix | Neovim (LazyVim) |
| **Terminal emulator** | Ghostty | Wezterm |
| **Multiplexer** | Zellij | Tmux |
| **Shell** | Fish | Nushell |
| **Dotfile manager** | ChezMoi | — |

Other CLI essentials installed by Bones: `asdf atuin bat doing envman exercism eza flameshot gh ghostty git github‑copilot gitui helix htop jrnl karabiner kitty lazydocker lazygit lazysql neofetch nushell nvim op openapi presenterm skhd starship tardis tmux wezterm yabai yazi zellij zsh` …and many more listed in `packages.toml`.

---

## 📦 Regenerate the manifest

After installing tools manually:

```bash
bones snapshot -m packages.toml
git commit -am "snapshot"
```

---

## 🔧 Rebuild Bones (optional)

```bash
# Go to Bones path or clone it
cargo install --path .
cp ~/.cargo/bin/bones ~/.config/script/bones
```
> The `.config/script/bin` is in PATH also.

Commit the new binary and push.
