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

# -----------------------------------------------
# 1. chezmoi state
# -----------------------------------------------
echo "[1/6] chezmoi state"

assert "chezmoi is installed" command -v chezmoi
assert "chezmoi config exists" test -f ~/.config/chezmoi/chezmoi.toml
assert "chezmoi source dir exists" test -d ~/.local/share/chezmoi

if command -v chezmoi &>/dev/null; then
  managed=$(chezmoi managed 2>/dev/null | wc -l || echo 0)
  assert "chezmoi manages >100 files ($managed found)" test "$managed" -gt 100

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
echo "[2/6] Template rendering"

# Read profile from chezmoi config TOML file directly
config_file="$HOME/.config/chezmoi/chezmoi.toml"
if [[ -f "$config_file" ]]; then
  profile=$(sed -n 's/^[[:space:]]*profile[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$config_file")
  purpose=$(sed -n 's/^[[:space:]]*purpose[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$config_file")
  git_email=$(sed -n 's/^[[:space:]]*git_email[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$config_file")
fi
profile="${profile:-unknown}"
purpose="${purpose:-unknown}"
git_email="${git_email:-unknown}"

echo "  Profile: $profile | Purpose: $purpose | Email: $git_email"

assert "git config exists" test -f ~/.config/git/config
assert "git config has email" grep -q "$git_email" ~/.config/git/config
assert "monitors.conf exists" test -f ~/.config/hypr/monitors.conf
assert "monitors.conf has monitor= line" grep -q 'monitor=' ~/.config/hypr/monitors.conf

echo ""

# -----------------------------------------------
# 3. Package lists
# -----------------------------------------------
echo "[3/6] Package lists"

PKGDIR="$HOME/.config/packages"
assert "packages dir exists" test -d "$PKGDIR"

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
echo "  Total declared packages: $total"

echo ""

# -----------------------------------------------
# 4. Pacman hook
# -----------------------------------------------
echo "[4/6] Pacman hook"

assert "hook symlink exists" test -L /etc/pacman.d/hooks/pkg-snapshot-append.hook
assert "hook target is readable" test -f /etc/pacman.d/hooks/pkg-snapshot-append.hook
assert "pkg-snapshot-update.sh is executable" test -x ~/.config/scripts/pkg-snapshot-update.sh

echo ""

# -----------------------------------------------
# 5. Key configs in place
# -----------------------------------------------
echo "[5/6] Key configs"

assert "blesh config exists" test -f ~/.config/blesh/init.sh
assert "nvim init.lua exists" test -f ~/.config/nvim/init.lua
assert "hyprland.conf exists" test -f ~/.config/hypr/hyprland.conf
assert "ghostty config exists" test -d ~/.config/ghostty
assert "waybar config exists" test -d ~/.config/waybar
assert "ssh config exists" test -f ~/.ssh/config

warn_check "tmux config exists" test -f ~/.config/tmux/tmux.conf
warn_check "lazygit config exists" test -d ~/.config/lazygit
warn_check "btop config exists" test -d ~/.config/btop

echo ""

# -----------------------------------------------
# 6. Tools & shell
# -----------------------------------------------
echo "[6/6] Tools & shell"

current_shell=$(getent passwd "$USER" | cut -d: -f7)
assert "default shell is bash" test "$current_shell" = "/usr/bin/bash"

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
