#!/usr/bin/env bash
# hvpaiva/dotfiles — first-time setup of a machine. Everything after this is `dots`.
#
#   bash <(curl -fsSL https://raw.githubusercontent.com/hvpaiva/dotfiles/master/bootstrap.sh) [options]
#
# Installs git if the machine lacks it, clones the repo bare into ~/.dotfiles with $HOME as
# the work tree, keeps this file, README.md and .github/ out of $HOME (sparse checkout), then
# hands over to `dots setup`, which installs everything else: build dependencies, Omarchy on
# Ubuntu (through omarchy-ubuntu), the private layer, neovim, rustup and augur, ble.sh, tmux
# plugins, mise and its tools, font and themes, and removes the distro packages the layer
# replaces. Running it again is `dots setup`.
#
# Options are `dots setup`'s:
#   --host NAME  --reset  --skip-omarchy  --skip-private  --skip-mise  --skip-rust
# Environment overrides, for tests: DOTFILES_REPO, DOTFILES_BRANCH (and dots setup's).

set -u
REPO=${DOTFILES_REPO:-https://github.com/hvpaiva/dotfiles.git}
BRANCH=${DOTFILES_BRANCH:-master}
GITDIR=$HOME/.dotfiles
dots() { git --git-dir="$GITDIR" --work-tree="$HOME" "$@"; }
die()  { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }
note() { printf '    %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

# Under `curl | bash` stdin is the pipe; sudo and the prompts ahead need the terminal.
# Only reattach when the terminal can actually be opened.
if [[ ! -t 0 ]] && { exec 3</dev/tty; } 2>/dev/null; then exec <&3 3<&-; fi

printf '\n\033[1;36m==> git\033[0m\n'
if have git; then
  note "present"
else
  note "installing (sudo may ask for your password)"
  if have pacman; then
    sudo pacman -S --needed --noconfirm git >/dev/null || die "could not install git"
  elif have apt-get; then
    sudo apt-get update -qq >/dev/null 2>&1
    sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq git >/dev/null || die "could not install git"
  else
    die "no pacman or apt-get here; install git and run this again"
  fi
  note "installed"
fi

printf '\n\033[1;36m==> dotfiles\033[0m\n'
if [[ -d $GITDIR ]]; then
  note "already cloned"
else
  git clone -q --bare -b "$BRANCH" "$REPO" "$GITDIR" || die "cannot clone $REPO"
  dots config core.sparseCheckout true
  dots config core.sparseCheckoutCone false
  printf '/*\n!/README.md\n!/bootstrap.sh\n!/.github/\n' >"$GITDIR/info/sparse-checkout"
  # files the distro or Omarchy already wrote in $HOME (.bashrc, .profile from /etc/skel)
  # would block the checkout: keep them aside. That failed checkout already filled the
  # index, so a plain checkout afterwards would write nothing; reset --hard does.
  conflicts=$(dots checkout 2>&1 >/dev/null | sed -n 's/^\t//p')
  if [[ -n $conflicts ]]; then
    bk=$HOME/.local/state/dotfiles/pre-checkout-$(date +%Y%m%d-%H%M%S)
    while IFS= read -r f; do
      [[ -n $f ]] || continue
      mkdir -p "$bk/$(dirname "$f")" && mv -- "$HOME/$f" "$bk/$f"
    done <<<"$conflicts"
    note "moved $(wc -l <<<"$conflicts") pre-existing file(s) to $bk"
  fi
  dots reset -q --hard HEAD || die "checkout failed"
  note "checked out $(dots log --oneline -1)"
fi
[[ -x $HOME/.local/bin/dots ]] || die "the checkout has no ~/.local/bin/dots; is $REPO the right repository?"
exec "$HOME/.local/bin/dots" setup "$@"
