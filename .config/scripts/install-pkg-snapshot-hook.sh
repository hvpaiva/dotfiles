#!/usr/bin/env bash
# Install the pacman hook that records newly installed explicit packages in
# ~/.config/packages/arch/uncategorized.txt (through pkg-snapshot-update.sh).
# Idempotent; needs sudo. dots setup runs it on Arch.
set -euo pipefail

REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "${USER:-root}")}"
REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"
SRC_UPDATE="${REAL_HOME}/.config/scripts/pkg-snapshot-update.sh"
HOOK=/etc/pacman.d/hooks/pkg-snapshot-append.hook

[[ -x "$SRC_UPDATE" ]] || { echo "ERROR: $SRC_UPDATE is missing or not executable" >&2; exit 1; }

# pacman runs hooks as root: the path must be absolute
sudo install -d -m 0755 /etc/pacman.d/hooks
sudo tee "$HOOK" >/dev/null <<EOF
[Trigger]
Operation = Install
Type = Package
Target = *

[Action]
Description = Recording explicitly installed packages in ~/.config/packages/arch
When = PostTransaction
Exec = $SRC_UPDATE
NeedsTargets
EOF
echo "Installed $HOOK -> $SRC_UPDATE"
