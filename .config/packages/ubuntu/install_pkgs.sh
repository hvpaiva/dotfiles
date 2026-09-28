#!/usr/bin/env bash
# shellcheck disable=SC2024
set -Eeuo pipefail

# install_pkgs.sh — Install packages from list files via apt.
# Reads one package name per line, ignores comments and blank lines.

LOG_DIR="${LOG_DIR:-$HOME/.local/state/pkg-restore}"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/install-$(date -u +%Y%m%dT%H%M%SZ).log"

log() { printf '%s %s\n' "[$1]" "$2" | tee -a "$LOG_FILE"; }

echo "Installer start: $(date -u +%FT%TZ)"
echo "log_file=$LOG_FILE"
echo ""

# Collect packages from all list files
declare -a PKGS=()

for listfile in "$@"; do
  [[ -f "$listfile" ]] || { log "WARN" "File not found: $listfile"; continue; }
  while IFS= read -r line; do
    [[ -z "${line// }" || "$line" =~ ^[[:space:]]*# ]] && continue
    read -r name <<< "$line"
    [[ -z "$name" ]] && continue
    PKGS+=("$name")
  done < "$listfile"
done

[[ ${#PKGS[@]} -eq 0 ]] && { echo "No packages to install."; exit 0; }

echo "Total packages to process: ${#PKGS[@]}"

# Filter out already-installed packages
declare -a TO_INSTALL=()
for pkg in "${PKGS[@]}"; do
  if ! dpkg -s "$pkg" &>/dev/null; then
    TO_INSTALL+=("$pkg")
  fi
done

if [[ ${#TO_INSTALL[@]} -eq 0 ]]; then
  echo "All ${#PKGS[@]} packages already installed."
  exit 0
fi

already=$((${#PKGS[@]} - ${#TO_INSTALL[@]}))
echo "To install: ${#TO_INSTALL[@]} ($already already installed)"
echo ""

fail=0
success=0

log "INFO" "Installing ${#TO_INSTALL[@]} packages via apt..."
start_ts=$(date +%s)
rc=0
sudo apt-get install -y "${TO_INSTALL[@]}" >>"$LOG_FILE" 2>&1 || rc=$?

if (( rc == 0 )); then
  success=${#TO_INSTALL[@]}
  log "INFO" "apt batch OK"
else
  log "WARN" "apt batch failed (rc=$rc), retrying individually..."
  for pkg in "${TO_INSTALL[@]}"; do
    if sudo apt-get install -y "$pkg" >>"$LOG_FILE" 2>&1; then
      success=$((success + 1))
    else
      fail=$((fail + 1))
      log "FAIL" "apt: $pkg"
    fi
  done
fi

elapsed=$(( $(date +%s) - start_ts ))
log "INFO" "apt done in ${elapsed}s"

printf "\nDone. Success: %s  Fail: %s\n" "$success" "$fail"
printf "Full log: %s\n" "$LOG_FILE"
