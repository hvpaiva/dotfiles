#!/bin/bash
set -euo pipefail

# test/run-tests.sh — Automated validation for chezmoi dotfiles.
# Run from repo root: ./test/run-tests.sh
# Requires: bash, chezmoi (optional: shellcheck)

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PKGDIR="$REPO_ROOT/dot_config/packages"
SCRIPTS_DIR="$REPO_ROOT/dot_config/scripts"

pass=0
fail=0
skip=0

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

assert_not() {
  local name="$1"; shift
  if ! "$@" >/dev/null 2>&1; then
    green "  PASS: $name"
    pass=$((pass + 1))
  else
    red "  FAIL: $name"
    fail=$((fail + 1))
  fi
}

skip_test() {
  yellow "  SKIP: $1 ($2)"
  skip=$((skip + 1))
}

echo "========================================="
echo " Dotfiles Test Suite"
echo "========================================="
echo ""

# -----------------------------------------------
# 1. Structure tests
# -----------------------------------------------
echo "[1/7] Structure"

assert "chezmoi.toml.tmpl exists" test -f "$REPO_ROOT/.chezmoi.toml.tmpl"
assert ".chezmoiignore exists" test -f "$REPO_ROOT/.chezmoiignore"
assert "run_once_after_01 exists" test -f "$REPO_ROOT/run_once_after_01-install-packages.sh.tmpl"
assert "run_once_after_02 exists" test -f "$REPO_ROOT/run_once_after_02-setup-pacman-hook.sh"
assert "run_once_after_99 exists" test -f "$REPO_ROOT/run_once_after_99-finalize.sh"
assert "packages dir exists" test -d "$PKGDIR"
assert "scripts dir exists" test -d "$SCRIPTS_DIR"
assert "private_dot_ssh exists" test -d "$REPO_ROOT/private_dot_ssh"

# Ensure no run_once_before scripts (they run before files are applied)
assert "no run_once_before scripts" \
  bash -c '! ls "$1"/run_once_before_* 2>/dev/null | grep -q .' -- "$REPO_ROOT"

echo ""

# -----------------------------------------------
# 2. Package list integrity
# -----------------------------------------------
echo "[2/7] Package lists"

# Pacman-managed lists (two-column: NAME ORIGIN)
PACMAN_LISTS="apps.txt core.txt desktop.txt dev.txt gaming.txt work.txt uncategorized.txt"
for f in $PACMAN_LISTS; do
  assert "package list $f exists" test -f "$PKGDIR/$f"
done

# Non-pacman lists (single-column: just package name)
OTHER_LISTS="cargo.txt npm.txt go.txt pip.txt"
for f in $OTHER_LISTS; do
  assert "package list $f exists" test -f "$PKGDIR/$f"
done

# No duplicates within pacman lists
dupes=$(cat "$PKGDIR"/{apps,core,desktop,dev,gaming,work,uncategorized}.txt \
  | grep -Ev '^\s*(#|$)' \
  | awk '{print $1}' \
  | sort | uniq -d)
assert "no duplicate packages across pacman lists" test -z "$dupes"

# Pacman lists: every line has exactly 2 fields: NAME ORIGIN
bad_lines=$(cat "$PKGDIR"/{apps,core,desktop,dev,gaming,work,uncategorized}.txt \
  | grep -Ev '^\s*(#|$)' \
  | awk 'NF != 2 {print FILENAME": "$0}')
assert "pacman lists have NAME ORIGIN format" test -z "$bad_lines"

# Pacman lists: valid origins only
bad_origins=$(cat "$PKGDIR"/{apps,core,desktop,dev,gaming,work,uncategorized}.txt \
  | grep -Ev '^\s*(#|$)' \
  | awk '$2 != "pacman" && $2 != "yay" && $2 != "paru" {print $0}')
assert "pacman origins are pacman/yay/paru" test -z "$bad_origins"

# Non-pacman lists: every line has exactly 1 field (package name only)
bad_other=$(cat "$PKGDIR"/{cargo,npm,go,pip}.txt \
  | grep -Ev '^\s*(#|$)' \
  | awk 'NF != 1 {print FILENAME": "$0}')
assert "non-pacman lists have single-column format" test -z "$bad_other"

# Count total packages across all lists
total=$(cat "$PKGDIR"/*.txt | grep -Ev '^\s*(#|$)' | awk '{print $1}' | sort -u | wc -l)
assert "at least 200 packages declared" test "$total" -ge 200

echo "  (total declared: $total)"
echo ""

# -----------------------------------------------
# 3. Template syntax
# -----------------------------------------------
echo "[3/7] Template syntax"

for tmpl in $(find "$REPO_ROOT" -name '*.tmpl' -type f); do
  rel="${tmpl#$REPO_ROOT/}"
  # Check for common template errors: unclosed actions, mismatched braces
  unclosed=$(grep -cP '\{\{[^}]*$' "$tmpl" || true)
  assert "template $rel has no unclosed {{ }}" test "$unclosed" -eq 0
done

# Verify .chezmoi.toml.tmpl has required prompts
assert "config template has profile prompt" \
  grep -q 'promptChoiceOnce.*profile' "$REPO_ROOT/.chezmoi.toml.tmpl"
assert "config template has purpose prompt" \
  grep -q 'promptChoiceOnce.*purpose' "$REPO_ROOT/.chezmoi.toml.tmpl"
assert "config template has git_email prompt" \
  grep -q 'promptStringOnce.*git_email' "$REPO_ROOT/.chezmoi.toml.tmpl"

echo ""

# -----------------------------------------------
# 4. Script syntax (bash -n)
# -----------------------------------------------
echo "[4/7] Script syntax (bash -n)"

for script in "$SCRIPTS_DIR"/executable_*.sh "$REPO_ROOT"/run_once_*.sh; do
  [[ -f "$script" ]] || continue
  rel="${script#$REPO_ROOT/}"
  assert "syntax OK: $rel" bash -n "$script"
done

# Template scripts: strip template directives, then check syntax
for script in "$REPO_ROOT"/run_once_*.sh.tmpl; do
  [[ -f "$script" ]] || continue
  rel="${script#$REPO_ROOT/}"
  tmpfile=$(mktemp)
  # Remove {{ ... }} lines for syntax check
  sed '/{{.*}}/d' "$script" > "$tmpfile"
  assert "syntax OK (stripped): $rel" bash -n "$tmpfile"
  rm -f "$tmpfile"
done

echo ""

# -----------------------------------------------
# 5. Shellcheck (if available)
# -----------------------------------------------
echo "[5/7] Shellcheck"

if command -v shellcheck &>/dev/null; then
  for script in "$SCRIPTS_DIR"/executable_*.sh "$REPO_ROOT"/run_once_*.sh; do
    [[ -f "$script" ]] || continue
    rel="${script#$REPO_ROOT/}"
    assert "shellcheck: $rel" shellcheck -S warning "$script"
  done
else
  skip_test "shellcheck" "not installed"
fi

echo ""

# -----------------------------------------------
# 6. Secret detection
# -----------------------------------------------
echo "[6/7] Secret detection"

# Patterns that indicate real secrets (not placeholder text or package names)
secret_files=$(grep -rlE \
  '(AKIA[A-Z0-9]{16}|ghp_[a-zA-Z0-9]{36}|-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY)' \
  "$REPO_ROOT" \
  --include='*.sh' --include='*.tmpl' --include='*.toml' \
  --include='*.conf' --include='*.yml' --include='*.yaml' \
  --include='*.json' --include='*.lua' --include='*.fish' \
  2>/dev/null || true)
assert "no AWS keys or private keys in repo" test -z "$secret_files"

# No .env files
env_files=$(find "$REPO_ROOT" -name '.env' -o -name '.env.*' 2>/dev/null | grep -v '.git/' || true)
assert "no .env files in repo" test -z "$env_files"

# SSH private key should not be in repo
assert "no SSH private key" \
  bash -c '! test -f "$1/private_dot_ssh/id_ed25519"' -- "$REPO_ROOT"
assert "no SSH private key (rsa)" \
  bash -c '! test -f "$1/private_dot_ssh/id_rsa"' -- "$REPO_ROOT"

echo ""

# -----------------------------------------------
# 7. Chezmoi integration (if chezmoi available)
# -----------------------------------------------
echo "[7/7] Chezmoi integration"

if command -v chezmoi &>/dev/null; then
  # Check that managed files list is non-empty
  managed_count=$(chezmoi managed 2>/dev/null | wc -l || echo 0)
  assert "chezmoi manages >100 files" test "$managed_count" -gt 100
  echo "  (managed: $managed_count)"

  # Check templates render without errors
  assert "git config template renders" \
    chezmoi cat ~/.config/git/config
  assert "monitors template renders" \
    chezmoi cat ~/.config/hypr/monitors.conf
  assert "install-packages template renders" \
    chezmoi cat ~/01-install-packages.sh
else
  skip_test "chezmoi integration" "chezmoi not in PATH"
fi

echo ""

# -----------------------------------------------
# Summary
# -----------------------------------------------
echo "========================================="
printf ' Results: \033[32m%s passed\033[0m, ' "$pass"
if (( fail > 0 )); then
  printf '\033[31m%s failed\033[0m' "$fail"
else
  printf "0 failed"
fi
if (( skip > 0 )); then
  printf ', \033[33m%s skipped\033[0m' "$skip"
fi
echo ""
echo "========================================="

exit "$fail"
