#!/usr/bin/env bash
# Set up the personal layer on a machine that already runs Omarchy (Arch) or
# omarchy-ubuntu. Idempotent: every step checks before acting.
set -u

dots() { git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" "$@"; }
step() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }

step "dotfiles: bare repo at ~/.dotfiles"
if [[ ! -d $HOME/.dotfiles ]]; then
  git clone --bare git@github.com:hvpaiva/dotfiles.git "$HOME/.dotfiles" || exit 1
  if ! dots checkout; then
    echo "existing files would be overwritten; move them away and run again" >&2
    exit 1
  fi
fi
dots config status.showUntrackedFiles normal

step "neovim config (hvpaiva/nvim)"
[[ -d $HOME/.config/nvim/.git ]] || git clone git@github.com:hvpaiva/nvim.git "$HOME/.config/nvim"

step "ble.sh"
if [[ ! -f $HOME/.local/share/blesh/ble.sh ]]; then
  tmp=$(mktemp -d)
  git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git "$tmp/ble.sh" \
    && make -C "$tmp/ble.sh" install PREFIX="$HOME/.local"
  rm -rf "$tmp"
fi

step "tmux plugins (tpm, XDG data dir)"
tpm=$HOME/.local/share/tmux/plugins/tpm
[[ -d $tpm ]] || git clone https://github.com/tmux-plugins/tpm "$tpm"
TMUX_PLUGIN_MANAGER_PATH="$HOME/.local/share/tmux/plugins" "$tpm/bin/install_plugins"

step "mise tools (config.toml + conf.d/local.toml)"
if command -v mise >/dev/null; then mise install -y; else echo "mise not found, skipping" >&2; fi

step "font: MesloLGLDZ Nerd Font Mono"
if command -v omarchy-font-set >/dev/null; then
  if ! fc-list : family | grep -q 'MesloLGLDZ Nerd Font Mono'; then
    echo "font not installed: get the Meslo Nerd Font first (omarchy menu > Style > Font on Arch; a Nerd Fonts release archive on Ubuntu)" >&2
  elif ! omarchy-font-current 2>/dev/null | grep -qF 'MesloLGLDZ Nerd Font Mono'; then
    omarchy-font-set "MesloLGLDZ Nerd Font Mono"
  fi
fi

step "themes (~/.config/omarchy/themes.txt)"
if command -v omarchy-theme-install >/dev/null; then
  while read -r url; do
    [[ -z $url || $url == \#* ]] && continue
    name=${url##*/}; name=${name%.git}; name=${name#omarchy-}; name=${name%-theme}
    [[ -d $HOME/.config/omarchy/themes/$name ]] && continue
    omarchy-theme-install "$url"
  done < "$HOME/.config/omarchy/themes.txt"
fi

step "kubectl completion, lazy-loaded by bash-completion"
if command -v kubectl >/dev/null; then
  mkdir -p "$HOME/.local/share/bash-completion/completions"
  kubectl completion bash > "$HOME/.local/share/bash-completion/completions/kubectl"
fi

step "per-host files"
for f in .config/git/local .config/bash/local .config/tmux/local.conf .config/blesh/local.sh .config/mise/conf.d/local.toml; do
  [[ -e $HOME/$f ]] || echo "  not present (write it if this host needs one): ~/$f"
done
[[ -f $HOME/.config/git/local ]] || printf '  git needs ~/.config/git/local:\n  [user]\n\temail = ...\n\tsigningkey = ~/.ssh/....pub\n'
