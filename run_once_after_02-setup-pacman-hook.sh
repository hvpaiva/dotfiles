#!/bin/bash
# chezmoi run_once_after: Install pacman hook for automatic package tracking.
set -euo pipefail

HOOK_SCRIPT="$HOME/.config/scripts/install-pkg-snapshot-hook.sh"

if [[ ! -x "$HOOK_SCRIPT" ]]; then
  echo "ERROR: Hook installer not found at $HOOK_SCRIPT"
  exit 1
fi

echo ""
echo "======================================"
echo " Pacman Hook Setup"
echo "======================================"
echo ""

"$HOOK_SCRIPT"
