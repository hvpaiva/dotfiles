#!/bin/bash
set -euo pipefail

# test/validate-bootstrap.sh — Validate that bootstrap applied correctly
# on the current machine. Run after `chezmoi init --apply` to verify
# that files, templates, hooks, and tools are all in place.

pass=0
fail=0
warn_count=0

green() { printf '\033[32m%s\033[0m\n' "$*"; }
red()   { printf '\033[31m%s\033[0m\n' "$*"; }
yellow(){ printf '\033[33m%s\033[0m\n' "$*"; }

assert() {
  local name="$1"; shift
  if "$@" >/dev/null 2>&1; then
    green "  PASS: $name"
    pass=$((pass + 1))
  else
    red "  FAIL: $name"
    fail=$((fail + 1))
  fi
}

warn_check() {
  local name="$1"; shift
  if "$@" >/dev/null 2>&1; then
    green "  PASS: $name"
    pass=$((pass + 1))
  else
    yellow "  WARN: $name"
    warn_count=$((warn_count + 1))
  fi
}

echo "========================================="
echo " Bootstrap Validation"
echo "========================================="
echo ""

# Feature detection
HAS_PACMAN=false; command -v pacman &>/dev/null && HAS_PACMAN=true
HAS_HYPRLAND=false; command -v hyprctl &>/dev/null && HAS_HYPRLAND=true
HAS_OMARCHY=false; command -v omarchy-version &>/dev/null && HAS_OMARCHY=true

# -----------------------------------------------
# 1. chezmoi state
# -----------------------------------------------
echo "[1/7] chezmoi state"

assert "chezmoi is installed" command -v chezmoi
assert "chezmoi config exists" test -f ~/.config/chezmoi/chezmoi.toml
assert "chezmoi source dir exists" test -d ~/.local/share/chezmoi

if command -v chezmoi &>/dev/null; then
  managed=$(chezmoi managed 2>/dev/null | wc -l || echo 0)
  assert "chezmoi manages >50 files ($managed found)" test "$managed" -gt 50

  # Check for drift (files that differ from source)
  drift=$(chezmoi diff 2>/dev/null | head -1 || true)
  if [[ -z "$drift" ]]; then
    green "  PASS: no drift (applied state matches source)"
    pass=$((pass + 1))
  else
    yellow "  WARN: drift detected (chezmoi diff has changes)"
    warn_count=$((warn_count + 1))
  fi
fi

echo ""

# -----------------------------------------------
# 2. Template rendering
# -----------------------------------------------
echo "[2/7] Template rendering"

# Read profile from chezmoi config TOML file directly
config_file="$HOME/.config/chezmoi/chezmoi.toml"
if [[ -f "$config_file" ]]; then
  profile=$(sed -n 's/^[[:space:]]*profile[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$config_file")
  purpose=$(sed -n 's/^[[:space:]]*purpose[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$config_file")
  git_email=$(sed -n 's/^[[:space:]]*git_email[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$config_file")
  distro=$(sed -n 's/^[[:space:]]*distro[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$config_file")
fi
profile="${profile:-unknown}"
purpose="${purpose:-unknown}"
git_email="${git_email:-unknown}"
distro="${distro:-unknown}"

echo "  Profile: $profile | Purpose: $purpose | Email: $git_email | Distro: $distro"

assert "git config exists" test -f ~/.config/git/config
assert "git config has email" grep -q "$git_email" ~/.config/git/config

if $HAS_HYPRLAND; then
  assert "monitors.conf exists" test -f ~/.config/hypr/monitors.conf
  assert "monitors.conf has monitor= line" grep -q 'monitor=' ~/.config/hypr/monitors.conf
fi

echo ""

# -----------------------------------------------
# 3. Package lists
# -----------------------------------------------
echo "[3/7] Package lists"

if $HAS_PACMAN; then
  PKGDIR="$HOME/.config/packages/arch"
  assert "arch packages dir exists" test -d "$PKGDIR"

  for f in core.txt dev.txt apps.txt; do
    assert "$f exists and is non-empty" test -s "$PKGDIR/$f"
  done

  # Profile-specific lists
  if [[ "$profile" == "desktop" ]]; then
    assert "desktop.txt exists (profile=desktop)" test -s "$PKGDIR/desktop.txt"
    assert "gaming.txt exists (profile=desktop)" test -s "$PKGDIR/gaming.txt"
  fi

  if [[ "$purpose" == "work" || "$purpose" == "both" ]]; then
    assert "work.txt exists (purpose=$purpose)" test -s "$PKGDIR/work.txt"
  fi

  # Count total packages across all lists
  total=$(cat "$PKGDIR"/*.txt 2>/dev/null | grep -Ev '^\s*(#|$)' | awk '{print $1}' | sort -u | wc -l)
  echo "  Total declared Arch packages: $total"
elif command -v apt-get &>/dev/null; then
  PKGDIR="$HOME/.config/packages/ubuntu"
  assert "ubuntu packages dir exists" test -d "$PKGDIR"

  for f in core.txt dev.txt apps.txt; do
    assert "$f exists and is non-empty" test -s "$PKGDIR/$f"
  done

  total=$(cat "$PKGDIR"/*.txt 2>/dev/null | grep -Ev '^\s*(#|$)' | sort -u | wc -l)
  echo "  Total declared Ubuntu packages: $total"
elif [[ "$(uname)" == "Darwin" ]]; then
  assert "Brewfile exists" test -f "$HOME/.config/packages/macos/Brewfile"
fi

UNIVDIR="$HOME/.config/packages/universal"
assert "universal packages dir exists" test -d "$UNIVDIR"

echo ""

# -----------------------------------------------
# 4. Pacman hook (Arch only)
# -----------------------------------------------
echo "[4/7] Pacman hook"

if $HAS_PACMAN; then
  assert "hook symlink exists" test -L /etc/pacman.d/hooks/pkg-snapshot-append.hook
  assert "hook target is readable" test -f /etc/pacman.d/hooks/pkg-snapshot-append.hook
  assert "pkg-snapshot-update.sh is executable" test -x ~/.config/scripts/pkg-snapshot-update.sh
else
  yellow "  SKIP: not on Arch Linux"
  warn_count=$((warn_count + 1))
fi

echo ""

# -----------------------------------------------
# 5. Key configs in place
# -----------------------------------------------
echo "[5/7] Key configs"

assert "blesh config exists" test -f ~/.config/blesh/init.sh
assert "nvim init.lua exists" test -f ~/.config/nvim/init.lua
assert "ghostty config exists" test -d ~/.config/ghostty
assert "ssh config exists" test -f ~/.ssh/config

if $HAS_HYPRLAND; then
  assert "hyprland.conf exists" test -f ~/.config/hypr/hyprland.conf
  assert "waybar config exists" test -d ~/.config/waybar
fi

warn_check "tmux config exists" test -f ~/.config/tmux/tmux.conf
warn_check "lazygit config exists" test -d ~/.config/lazygit
warn_check "btop config exists" test -d ~/.config/btop

echo ""

# -----------------------------------------------
# 6. Tools & shell
# -----------------------------------------------
echo "[6/7] Tools & shell"

current_shell=$(getent passwd "$USER" | cut -d: -f7)
bash_path=$(command -v bash 2>/dev/null || echo /usr/bin/bash)
assert "default shell is bash" test "$current_shell" = "$bash_path"

warn_check "git is installed" command -v git
warn_check "nvim is installed" command -v nvim
warn_check "mise is installed" command -v mise
warn_check "docker is installed" command -v docker
warn_check "ble.sh is installed" test -d ~/.local/share/blesh

echo ""

# -----------------------------------------------
# 7. Secret safety
# -----------------------------------------------
echo "[7/7] Secret safety"

warn_check "no private SSH key on disk (~/.ssh/id_ed25519)" \
  bash -c '! grep -q "PRIVATE KEY" ~/.ssh/id_ed25519 2>/dev/null'
assert "1Password agent configured" grep -q '1password/agent.sock' ~/.ssh/config

echo ""

# -----------------------------------------------
# Summary
# -----------------------------------------------
echo "========================================="
printf ' Results: \033[32m%d passed\033[0m' "$pass"
if (( fail > 0 )); then
  printf ', \033[31m%d failed\033[0m' "$fail"
else
  printf ', 0 failed'
fi
if (( warn_count > 0 )); then
  printf ', \033[33m%d warnings\033[0m' "$warn_count"
fi
echo ""
echo "========================================="

exit "$fail"
