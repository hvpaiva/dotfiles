#!/usr/bin/env bash
# shellcheck disable=SC2024  # sudo redirects to user-owned log file intentionally
set -Eeuo pipefail

# install_pkgs.sh — Install packages from categorized list files.
# Reads package lists from ~/.config/packages/*.txt, groups by origin,
# and installs in batch for speed.

PKGDIR="${PKGDIR:-$HOME/.config/packages}"
LOG_DIR="${LOG_DIR:-$HOME/.local/state/pkg-restore}"

mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/install-$(date -u +%Y%m%dT%H%M%SZ).log"

log() { printf '%s %s\n' "[$1]" "$2" | tee -a "$LOG_FILE"; }

# ---------- header ----------
echo "Installer start: $(date -u +%FT%TZ)"
echo "pkg_dir=$PKGDIR"
echo "log_file=$LOG_FILE"
echo ""

# ---------- collect packages from all list files ----------
declare -a PACMAN_PKGS=()
declare -a YAY_PKGS=()
declare -a PARU_PKGS=()

for listfile in "$@"; do
  [[ -f "$listfile" ]] || { log "WARN" "File not found: $listfile"; continue; }
  while IFS= read -r line; do
    [[ -z "${line// }" || "$line" =~ ^[[:space:]]*# ]] && continue
    read -r name origin <<<"$line" || true
    [[ -z "$name" || -z "$origin" ]] && { log "WARN" "Skipping malformed: '$line'"; continue; }
    case "$origin" in
      pacman) PACMAN_PKGS+=("$name") ;;
      yay)    YAY_PKGS+=("$name")    ;;
      paru)   PARU_PKGS+=("$name")   ;;
      *)      log "ERROR" "Unknown origin '$origin' for '$name'" ;;
    esac
  done < "$listfile"
done

TOTAL=$(( ${#PACMAN_PKGS[@]} + ${#YAY_PKGS[@]} + ${#PARU_PKGS[@]} ))
[[ $TOTAL -eq 0 ]] && { echo "No packages to install."; exit 0; }

echo "Total packages to process: $TOTAL"
echo "  pacman: ${#PACMAN_PKGS[@]}  yay: ${#YAY_PKGS[@]}  paru: ${#PARU_PKGS[@]}"
echo ""

command -v sudo >/dev/null 2>&1 && sudo -v || true

# Warn if AUR toolchain is missing
if (( ${#YAY_PKGS[@]} + ${#PARU_PKGS[@]} > 0 )); then
  command -v git >/dev/null 2>&1 || log "WARN" "Missing AUR prerequisite: git"
  pacman -Qgq base-devel >/dev/null 2>&1 || log "WARN" "Missing AUR prerequisite group: base-devel"
fi

fail=0
success=0

# ---------- batch install: pacman ----------
if (( ${#PACMAN_PKGS[@]} > 0 )); then
  log "INFO" "Installing ${#PACMAN_PKGS[@]} pacman packages in batch..."
  start_ts=$(date +%s)
  rc=0
  sudo pacman -S --noconfirm --needed "${PACMAN_PKGS[@]}" >>"$LOG_FILE" 2>&1 || rc=$?
  if (( rc == 0 )); then
    success=$((success + ${#PACMAN_PKGS[@]}))
    log "INFO" "pacman batch OK"
  else
    log "WARN" "pacman batch failed (rc=$rc), retrying individually..."
    for pkg in "${PACMAN_PKGS[@]}"; do
      if sudo pacman -S --noconfirm --needed "$pkg" >>"$LOG_FILE" 2>&1; then
        success=$((success + 1))
      else
        fail=$((fail + 1))
        log "FAIL" "pacman: $pkg"
      fi
    done
  fi
  elapsed=$(( $(date +%s) - start_ts ))
  log "INFO" "pacman done in ${elapsed}s"
fi

# ---------- batch install: yay ----------
if (( ${#YAY_PKGS[@]} > 0 )); then
  if command -v yay &>/dev/null; then
    log "INFO" "Installing ${#YAY_PKGS[@]} yay packages in batch..."
    start_ts=$(date +%s)
    rc=0
    yay -S --noconfirm --needed "${YAY_PKGS[@]}" >>"$LOG_FILE" 2>&1 || rc=$?
    if (( rc == 0 )); then
      success=$((success + ${#YAY_PKGS[@]}))
      log "INFO" "yay batch OK"
    else
      log "WARN" "yay batch failed (rc=$rc), retrying individually..."
      for pkg in "${YAY_PKGS[@]}"; do
        if yay -S --noconfirm --needed "$pkg" >>"$LOG_FILE" 2>&1; then
          success=$((success + 1))
        else
          fail=$((fail + 1))
          log "FAIL" "yay: $pkg"
        fi
      done
    fi
    elapsed=$(( $(date +%s) - start_ts ))
    log "INFO" "yay done in ${elapsed}s"
  else
    log "ERROR" "yay not found — skipping ${#YAY_PKGS[@]} AUR packages"
    fail=$((fail + ${#YAY_PKGS[@]}))
  fi
fi

# ---------- batch install: paru ----------
if (( ${#PARU_PKGS[@]} > 0 )); then
  if command -v paru &>/dev/null; then
    log "INFO" "Installing ${#PARU_PKGS[@]} paru packages in batch..."
    start_ts=$(date +%s)
    rc=0
    paru -S --noconfirm --needed "${PARU_PKGS[@]}" >>"$LOG_FILE" 2>&1 || rc=$?
    if (( rc == 0 )); then
      success=$((success + ${#PARU_PKGS[@]}))
      log "INFO" "paru batch OK"
    else
      log "WARN" "paru batch failed (rc=$rc), retrying individually..."
      for pkg in "${PARU_PKGS[@]}"; do
        if paru -S --noconfirm --needed "$pkg" >>"$LOG_FILE" 2>&1; then
          success=$((success + 1))
        else
          fail=$((fail + 1))
          log "FAIL" "paru: $pkg"
        fi
      done
    fi
    elapsed=$(( $(date +%s) - start_ts ))
    log "INFO" "paru done in ${elapsed}s"
  else
    log "ERROR" "paru not found — skipping ${#PARU_PKGS[@]} AUR packages"
    fail=$((fail + ${#PARU_PKGS[@]}))
  fi
fi

printf "\nDone. Success: %s  Fail: %s\n" "$success" "$fail"
printf "Full log: %s\n" "$LOG_FILE"
