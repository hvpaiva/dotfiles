#!/bin/bash
# chezmoi run_once_before: Install pacman hook for package tracking
set -euo pipefail

HOOK_SCRIPT="$HOME/.config/scripts/install-pkg-snapshot-hook.sh"

if [[ ! -x "$HOOK_SCRIPT" ]]; then
  echo "Hook installer not found at $HOOK_SCRIPT, skipping."
  exit 0
fi

echo "Installing pacman snapshot hook..."
"$HOOK_SCRIPT"
