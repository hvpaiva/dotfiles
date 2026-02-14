#!/usr/bin/env bash
# Append only newly-installed *explicit* package names to uncategorized.txt.
# Reads package names from stdin (one per line) via a pacman hook with NeedsTargets.
# Checks ALL category files so already-categorized packages are skipped.
# Never exit non-zero — a broken snapshot must never block pacman or other hooks.
set -uo pipefail
trap 'exit 0' ERR

TARGET_USER="${SUDO_USER:-$(logname 2>/dev/null || echo root)}"
USER_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

PKGDIR="${USER_HOME}/.config/packages"
UNCATEGORIZED="${PKGDIR}/uncategorized.txt"

mkdir -p "$PKGDIR"
touch "$UNCATEGORIZED"
chown -R "$TARGET_USER":"$TARGET_USER" "$PKGDIR"

# Load already-listed names from ALL list files to avoid duplicates.
declare -A ALREADY=()
for f in "$PKGDIR"/*.txt; do
  [[ -f "$f" ]] || continue
  while read -r line; do
    [[ -z "${line// }" || "$line" =~ ^# ]] && continue
    name="${line%% *}"
    [[ -n "$name" ]] && ALREADY["$name"]=1
  done < "$f"
done

# Lightweight manager detection: yay / paru / fallback pacman.
detect_mgr() {
  local pid comm parent
  pid=$PPID
  for _ in {1..10}; do
    [[ -r "/proc/$pid/comm" ]] || break
    read -r comm <"/proc/$pid/comm" || true
    case "$comm" in
      yay)  echo "yay";  return 0 ;;
      paru) echo "paru"; return 0 ;;
    esac
    parent=$(awk '{print $4}' "/proc/$pid/stat" 2>/dev/null || echo)
    [[ -n "$parent" && "$parent" != "$pid" ]] || break
    pid="$parent"
  done
  echo "pacman"
}

SRC="$(detect_mgr)"

# Read targets from stdin and append only if:
#  - it's explicitly installed (not a dependency), and
#  - it's not already listed in any category file.
while IFS= read -r pkg; do
  [[ -z "${pkg// }" ]] && continue

  # Skip if not explicitly installed (dependencies will fail this check)
  if ! pacman -Qe "$pkg" &>/dev/null; then
    continue
  fi

  # Append to uncategorized if not present in any list
  if [[ -z "${ALREADY[$pkg]+x}" ]]; then
    echo "$pkg $SRC" >> "$UNCATEGORIZED"
    ALREADY["$pkg"]=1
  fi
done

chown "$TARGET_USER":"$TARGET_USER" "$UNCATEGORIZED"
