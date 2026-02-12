#!/usr/bin/env bash
set -euo pipefail

# pkg-reconcile.sh — Compare declared package lists vs actually installed.
# Shows: (1) installed but not declared, (2) declared but not installed.

PKGDIR="${PKGDIR:-$HOME/.config/packages}"

if [[ ! -d "$PKGDIR" ]]; then
  echo "ERROR: Package directory $PKGDIR not found."
  exit 1
fi

# Collect all declared packages from list files
declared_file=$(mktemp)
installed_file=$(mktemp)
trap 'rm -f "$declared_file" "$installed_file"' EXIT

cat "$PKGDIR"/*.txt \
  | grep -Ev '^\s*(#|$)' \
  | awk '{print $1}' \
  | sort -u > "$declared_file"

# Get all explicitly installed packages
pacman -Qeq | sort -u > "$installed_file"

undeclared=0
missing=0

echo "=== Installed but NOT declared (consider adding to a list) ==="
while read -r pkg; do
  if pacman -Qm "$pkg" &>/dev/null; then
    echo "  $pkg  (AUR)"
  else
    echo "  $pkg  (pacman)"
  fi
  undeclared=$((undeclared + 1))
done < <(comm -23 "$installed_file" "$declared_file")

echo ""
echo "=== Declared but NOT installed (missing or removed) ==="
while read -r pkg; do
  echo "  $pkg"
  missing=$((missing + 1))
done < <(comm -13 "$installed_file" "$declared_file")

echo ""
echo "--- Summary ---"
echo "Installed:  $(wc -l < "$installed_file")"
echo "Declared:   $(wc -l < "$declared_file")"
echo "Undeclared: $undeclared"
echo "Missing:    $missing"
