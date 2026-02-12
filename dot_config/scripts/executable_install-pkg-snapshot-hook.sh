#!/usr/bin/env bash
set -euo pipefail

REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "${USER:-root}")}"
REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"

SRC_UPDATE="${REAL_HOME}/.config/scripts/pkg-snapshot-update.sh"
HOOK_USER_FILE="${REAL_HOME}/.config/hooks/pkg-snapshot-append.hook"

HOOK_SYS_DIR="/etc/pacman.d/hooks"
HOOK_SYS_LINK="${HOOK_SYS_DIR}/pkg-snapshot-append.hook"

# Validation: both files must already exist
[[ -x "$SRC_UPDATE" ]]    || { echo "ERROR: $SRC_UPDATE is missing or not executable"; exit 1; }
[[ -f "$HOOK_USER_FILE" ]] || { echo "ERROR: $HOOK_USER_FILE does not exist"; exit 1; }

# Ensure system hook directory exists
sudo install -d -m 0755 "$HOOK_SYS_DIR"

# System symlink → user-managed hook
sudo ln -sfn "$HOOK_USER_FILE" "$HOOK_SYS_LINK"

echo "Linked:"
echo "  $HOOK_SYS_LINK -> $HOOK_USER_FILE"
echo "Done! Hook active for pacman/yay/paru installs."
