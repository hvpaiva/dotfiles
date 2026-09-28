#!/usr/bin/env bash
# hvpaiva/dotfiles — set up, or repair, a machine's personal layer on top of Omarchy.
#
#   bash <(curl -fsSL https://raw.githubusercontent.com/hvpaiva/dotfiles/master/.config/dotfiles/bootstrap.sh)
#
# Arch: expects Omarchy to be installed already. Ubuntu 24.04: installs Omarchy first,
# through the omarchy-ubuntu port. Needs git; everything else it installs itself.
# Idempotent: every step checks before acting, so running it again repairs drift.
#
# Options
#   --host NAME      which hosts/NAME of the private layer this machine uses. Saved in
#                    ~/.config/dotfiles/host; asked on the first run otherwise.
#   --reset          discard local changes to tracked files (hard reset to origin)
#   --skip-omarchy   leave the Omarchy layer alone (port bootstrap, font, themes)
#   --skip-private   do not touch the private layer
#   --skip-mise      do not install mise or its tools
#   --skip-rust      do not install rustup or augur
#   -h, --help
#
# Environment overrides, mostly for tests: DOTFILES_REPO, DOTFILES_BRANCH,
# DOTFILES_PRIVATE_REPO.

set -u

REPO=${DOTFILES_REPO:-https://github.com/hvpaiva/dotfiles.git}
PUSH_URL=git@github.com:hvpaiva/dotfiles.git
BRANCH=${DOTFILES_BRANCH:-master}
PRIVATE_REPO=${DOTFILES_PRIVATE_REPO:-git@github.com:hvpaiva/dotfiles-private.git}
PRIVATE_DIR=$HOME/.local/share/dotfiles-private
NVIM_REPO=https://github.com/hvpaiva/nvim.git
NVIM_PUSH_URL=git@github.com:hvpaiva/nvim.git
AUGUR_REPO=https://github.com/hvpaiva/augur.git
AUGUR_PUSH_URL=git@github.com:hvpaiva/augur.git
AUGUR_DIR=$HOME/dev/personal/augur
PORT_REPO=https://github.com/hvpaiva/omarchy-ubuntu.git
PORT_DIR=$HOME/.local/share/omarchy-ubuntu
FONT="MesloLGLDZ Nerd Font Mono"
STATE_DIR=$HOME/.local/state/dotfiles
HOST_FILE=$HOME/.config/dotfiles/host

host="" reset=0 skip_omarchy=0 skip_private=0 skip_mise=0 skip_rust=0
usage() { sed -n '2,20p' <<'USAGE'
#
# bootstrap.sh [--host NAME] [--reset] [--skip-omarchy] [--skip-private] [--skip-mise] [--skip-rust]
#
#   --host NAME      which hosts/NAME of the private layer this machine uses
#   --reset          discard local changes to tracked files (hard reset to origin)
#   --skip-omarchy   leave the Omarchy layer alone (port bootstrap, font, themes)
#   --skip-private   do not touch the private layer
#   --skip-mise      do not install mise or its tools
#   --skip-rust      do not install rustup or augur
USAGE
}
while (($#)); do
  case $1 in
    --host) host=${2:?--host needs a name}; shift ;;
    --reset) reset=1 ;;
    --skip-omarchy) skip_omarchy=1 ;;
    --skip-private) skip_private=1 ;;
    --skip-mise) skip_mise=1 ;;
    --skip-rust) skip_rust=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

step() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
note() { printf '    %s\n' "$*"; }
warn() { printf '    \033[33m%s\033[0m\n' "$*"; }
die()  { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }
dots() { git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" "$@"; }
dotp() { git -C "$PRIVATE_DIR" "$@"; }

# Under `curl | bash` stdin is the pipe; the port's bootstrap and the prompts below
# need the terminal. Only reattach when the terminal can actually be opened.
if [[ ! -t 0 ]] && { exec 3</dev/tty; } 2>/dev/null; then exec <&3 3<&-; fi

have git || die "git is required. Arch: sudo pacman -S git — Ubuntu: sudo apt install git"
os=other
if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  # Omarchy ships its own os-release (ID=omarchy); ID_LIKE keeps the family
  case "${ID:-} ${ID_LIKE:-}" in *arch*|*omarchy*) os=arch ;; *ubuntu*) os=ubuntu ;; esac
fi
mkdir -p "$STATE_DIR" "$HOME/.local/bin" "$HOME/.config/dotfiles"
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# ── Omarchy ──────────────────────────────────────────────────────────────────
step "Omarchy"
if (( skip_omarchy )); then
  note "skipped (--skip-omarchy)"
elif [[ $os == arch ]]; then
  if have omarchy; then
    note "present: $(cat /usr/share/omarchy/version 2>/dev/null || echo '?')"
  else
    warn "Omarchy is not installed. This script does not install it on Arch (use the Omarchy"
    warn "ISO or installer); the rest of the layer is set up anyway."
  fi
elif [[ $os == ubuntu ]]; then
  if [[ ! -d $PORT_DIR/.git ]]; then
    git clone -q "$PORT_REPO" "$PORT_DIR" || die "cannot clone $PORT_REPO"
    note "cloned omarchy-ubuntu"
  else
    git -C "$PORT_DIR" pull -q --ff-only 2>/dev/null || warn "omarchy-ubuntu: pull skipped (local changes?)"
  fi
  note "running omarchy-ubuntu/bootstrap.sh — idempotent, asks for your password; the first run takes 20–40 min"
  "$PORT_DIR/bootstrap.sh" || die "omarchy-ubuntu bootstrap failed; fix it and run this script again"
else
  warn "unsupported distro '${ID:-?}': only the dotfiles layer is set up"
fi

# ── dotfiles (bare repo at ~/.dotfiles, $HOME as work tree) ──────────────────
step "dotfiles"
if [[ ! -d $HOME/.dotfiles ]]; then
  git clone -q --bare -b "$BRANCH" "$REPO" "$HOME/.dotfiles" || die "cannot clone $REPO"
  # files the distro or Omarchy already wrote in $HOME would block the checkout
  conflicts=$(dots checkout 2>&1 >/dev/null | sed -n 's/^\t//p')
  if [[ -n $conflicts ]]; then
    bk=$STATE_DIR/pre-checkout-$(date +%Y%m%d-%H%M%S)
    while IFS= read -r f; do
      [[ -n $f ]] || continue
      mkdir -p "$bk/$(dirname "$f")" && mv -- "$HOME/$f" "$bk/$f"
    done <<<"$conflicts"
    note "moved $(wc -l <<<"$conflicts") pre-existing files to $bk"
  fi
  dots checkout -q || die "checkout failed"
  note "checked out $(dots log --oneline -1)"
fi
dots config status.showUntrackedFiles normal
dots config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
dots config remote.origin.pushurl "$PUSH_URL"
if dots fetch -q origin 2>/dev/null; then
  dots branch -q --set-upstream-to="origin/$BRANCH" "$BRANCH" 2>/dev/null
  if (( reset )); then
    dots reset -q --hard "origin/$BRANCH" && note "reset to origin/$BRANCH ($(dots log --oneline -1))"
  elif [[ -z $(dots status --porcelain) ]]; then
    if dots merge -q --ff-only "origin/$BRANCH" 2>/dev/null; then
      note "at origin/$BRANCH: $(dots log --oneline -1)"
    else
      warn "local commits diverge from origin/$BRANCH; reconcile by hand (dots log --oneline HEAD...origin/$BRANCH)"
    fi
  else
    warn "local changes present, not pulling. 'dots status' shows them; keep them with"
    warn "'dots add -u && dots commit', or drop them by running this script with --reset"
  fi
else
  warn "cannot reach origin (offline?); using the local checkout as is"
fi

# ── host marker ──────────────────────────────────────────────────────────────
if [[ -n $host ]]; then
  printf '%s\n' "$host" >"$HOST_FILE"
elif [[ -r $HOST_FILE ]]; then
  host=$(<"$HOST_FILE")
elif [[ -t 0 ]]; then
  read -rp "    private layer host name for this machine [$(hostname)]: " host
  host=${host:-$(hostname)}
  printf '%s\n' "$host" >"$HOST_FILE"
else
  host=$(hostname)
fi

# ── per-host layers, symlinked into place ────────────────────────────────────
# Public per-host files live in ~/.config/dotfiles/hosts/<host>/ (tracked); sensitive ones
# in the private repo, same layout. Both are linked into $HOME here. If a program replaced a
# link with a regular file (omarchy-shell rewrites shell.json, the monitor panel rewrites
# monitors.lua), the live file is the truth: it is copied back into its repo and re-linked.
link_tree() {
  local root=$1 label=$2 linked=0 adopted=0 kept=0 src rel dst
  [[ -d $root ]] || { note "$label: nothing to link"; return 0; }
  while IFS= read -r src; do
    rel=${src#"$root"/}; dst=$HOME/$rel
    if [[ -L $dst ]]; then
      [[ $(readlink "$dst") == "$src" ]] && { kept=$((kept + 1)); continue; }
      rm -f "$dst"
    elif [[ -e $dst ]]; then
      if ! cmp -s "$dst" "$src"; then
        cp -p "$dst" "$src" && adopted=$((adopted + 1)) && note "$label: adopted the live $rel (review and commit it)"
      fi
      rm -f "$dst"
    fi
    mkdir -p "$(dirname "$dst")" && ln -s "$src" "$dst" && linked=$((linked + 1))
  done < <(find "$root" -type f 2>/dev/null)
  note "$label: $kept already linked, $linked linked now, $adopted adopted"
}

step "per-host layer: public (hosts/$host)"
link_tree "$HOME/.config/dotfiles/hosts/$host" "public"

step "per-host layer: private (hosts/$host)"
if (( skip_private )); then
  note "skipped (--skip-private)"
elif ! GIT_SSH_COMMAND="ssh -o BatchMode=yes -o ConnectTimeout=10" git ls-remote -q "$PRIVATE_REPO" HEAD >/dev/null 2>&1; then
  warn "no access to $PRIVATE_REPO (GitHub SSH key not set up yet?)."
  warn "Sensitive per-host files stay as they are; run this script again once the key works."
else
  if [[ ! -d $PRIVATE_DIR/.git ]]; then
    git clone -q "$PRIVATE_REPO" "$PRIVATE_DIR" || die "cannot clone $PRIVATE_REPO"
    note "cloned"
  else
    dotp pull -q --ff-only 2>/dev/null || warn "private: pull skipped (local changes?)"
  fi
  link_tree "$PRIVATE_DIR/hosts/$host" "private"
  link_tree "$PRIVATE_DIR/common" "private/common"
fi

# ── neovim (own repo, declared as a submodule of dotfiles) ───────────────────
step "neovim config"
nv=$HOME/.config/nvim
if [[ -d $nv && ! -d $nv/.git ]]; then
  if [[ -z $(ls -A "$nv") ]]; then rmdir "$nv"; else mv "$nv" "$STATE_DIR/nvim-$(date +%s)"; note "moved a non-git ~/.config/nvim aside"; fi
fi
if [[ ! -d $nv/.git ]]; then
  git clone -q -b main "$NVIM_REPO" "$nv" || die "cannot clone $NVIM_REPO"
  git -C "$nv" remote set-url --push origin "$NVIM_PUSH_URL"
  note "cloned"
else
  git -C "$nv" pull -q --ff-only 2>/dev/null && note "at $(git -C "$nv" log --oneline -1)" || warn "nvim config: pull skipped (local changes or detached HEAD)"
fi

# ── rust toolchain + augur (ble.sh inline suggestions) ───────────────────────
step "rustup"
if (( skip_rust )); then
  note "skipped (--skip-rust)"
elif [[ -x $HOME/.cargo/bin/cargo ]]; then
  note "present: $("$HOME/.cargo/bin/rustc" --version 2>/dev/null)"
else
  have curl || die "curl is required to install rustup"
  curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | sh -s -- -y -q --no-modify-path >/dev/null && note "installed" || die "rustup install failed"
fi
step "augur"
if (( skip_rust )); then
  note "skipped (--skip-rust)"
else
  build=0
  if [[ ! -d $AUGUR_DIR/.git ]]; then
    git clone -q "$AUGUR_REPO" "$AUGUR_DIR" || die "cannot clone $AUGUR_REPO"
    git -C "$AUGUR_DIR" remote set-url --push origin "$AUGUR_PUSH_URL"
    build=1
  else
    before=$(git -C "$AUGUR_DIR" rev-parse HEAD)
    git -C "$AUGUR_DIR" pull -q --ff-only 2>/dev/null || true
    [[ $(git -C "$AUGUR_DIR" rev-parse HEAD) != "$before" ]] && build=1
  fi
  have augur || build=1
  if (( build )); then
    have cc || warn "no C compiler (Arch: pacman -S base-devel — Ubuntu: apt install build-essential); the build may fail"
    "$HOME/.cargo/bin/cargo" install -q --path "$AUGUR_DIR" && note "built and installed $(augur --version 2>/dev/null)" || warn "augur build failed; the shell works without it"
  else
    note "present: $(augur --version 2>/dev/null)"
  fi
fi

# ── ble.sh ───────────────────────────────────────────────────────────────────
step "ble.sh"
if [[ -f $HOME/.local/share/blesh/ble.sh ]]; then
  note "present"
elif ! have make || ! have gawk; then
  warn "ble.sh needs make and gawk (Arch: pacman -S make gawk — Ubuntu: apt install make gawk); skipped"
else
  tmp=$(mktemp -d)
  if git clone -q --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git "$tmp/ble.sh" \
     && make -s -C "$tmp/ble.sh" install PREFIX="$HOME/.local" >/dev/null; then note "installed"; else warn "ble.sh install failed"; fi
  rm -rf "$tmp"
fi

# ── tmux plugins ─────────────────────────────────────────────────────────────
step "tmux plugins"
tpm=$HOME/.local/share/tmux/plugins/tpm
[[ -d $tpm ]] || git clone -q https://github.com/tmux-plugins/tpm "$tpm"
if have tmux; then
  TMUX_PLUGIN_MANAGER_PATH="$HOME/.local/share/tmux/plugins" "$tpm/bin/install_plugins" >/dev/null 2>&1 && note "installed/verified" || warn "tpm could not install plugins now; press prefix+I inside tmux"
else
  warn "tmux not installed; plugins install on first use (prefix+I)"
fi

# ── mise ─────────────────────────────────────────────────────────────────────
step "mise"
if (( skip_mise )); then
  note "skipped (--skip-mise)"
else
  if ! have mise; then
    have curl || die "curl is required to install mise"
    curl -fsSL https://mise.run | MISE_INSTALL_PATH="$HOME/.local/bin/mise" sh >/dev/null 2>&1 && note "installed ~/.local/bin/mise" || die "mise install failed"
  fi
  if mise install -y >"$STATE_DIR/mise-install.log" 2>&1; then
    note "$(mise ls --global 2>/dev/null | wc -l) tools present (log: $STATE_DIR/mise-install.log)"
  else
    warn "some tools failed to install; see $STATE_DIR/mise-install.log"
  fi
  mise reshim >/dev/null 2>&1 || true
fi

# ── Omarchy-side pieces ──────────────────────────────────────────────────────
if (( ! skip_omarchy )) && have omarchy-font-set; then
  step "font: $FONT"
  if ! fc-list : family 2>/dev/null | grep -qF "$FONT"; then
    warn "font not installed (Arch: omarchy menu > Style > Font; Ubuntu: a Nerd Fonts release archive into ~/.local/share/fonts)"
  elif omarchy-font-current 2>/dev/null | grep -qF "$FONT"; then
    note "present"
  else
    omarchy-font-set "$FONT" >/dev/null 2>&1
    # font-set rewrites the terminal configs (and pins foot to size 9); fontconfig is what
    # we wanted from it, the terminal files come back from the repo
    dots checkout -q -- .config/foot/foot.ini .config/alacritty/alacritty.toml .config/ghostty/config .config/kitty/kitty.conf
    note "applied ($(omarchy-font-current 2>/dev/null))"
  fi
  step "themes"
  n=0
  while read -r url; do
    [[ -z $url || $url == \#* ]] && continue
    name=${url##*/}; name=${name%.git}; name=${name#omarchy-}; name=${name%-theme}
    [[ -d $HOME/.config/omarchy/themes/$name ]] && continue
    omarchy-theme-install "$url" >/dev/null 2>&1 && n=$((n + 1)) || warn "theme install failed: $url"
  done <"$HOME/.config/omarchy/themes.txt"
  note "$n installed, $(ls "$HOME/.config/omarchy/themes" 2>/dev/null | wc -l) present"
fi

step "shell completions"
comp=$HOME/.local/share/bash-completion/completions
mkdir -p "$comp"
if have kubectl; then
  kubectl completion bash >"$comp/kubectl" 2>/dev/null
  for a in kubecolor k; do
    printf 'source "$HOME/.local/share/bash-completion/completions/kubectl"\ncomplete -o default -F __start_kubectl %s\n' "$a" >"$comp/$a"
  done
  note "kubectl, kubecolor, k"
else
  note "kubectl not present, nothing to generate"
fi

# ── report ───────────────────────────────────────────────────────────────────
step "state"
drift=$(dots status --short)
if [[ -z $drift ]]; then
  note "tracked files match the repo ($(dots log --oneline -1))"
else
  warn "tracked files differ from the repo:"; printf '%s\n' "$drift" | sed 's/^/      /'
  warn "keep: dots add -u && dots commit && dots push   |   drop: bootstrap.sh --reset"
fi
if [[ -d $PRIVATE_DIR/.git ]] && [[ -n $(dotp status --short 2>/dev/null) ]]; then
  warn "private repo has uncommitted changes: dotp status"
fi
[[ -e $HOME/.config/git/local ]] || warn "no ~/.config/git/local (email, signing key): add hosts/$host/.config/git/local to the private repo"
note "open a new terminal (or log out and in) for the shell to pick everything up"
