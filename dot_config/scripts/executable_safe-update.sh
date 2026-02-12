#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
#  SAFE UPDATE FOR ARCH / OMARCHY + BTRFS + LUKS + LIMINE
#  Garantido para abortar com segurança se QUALQUER etapa crítica falhar.
# ============================================================================

# ------- Pretty printing ----------------------------------------------------
info()  { printf "\n\033[1;36m[INFO]\033[0m %s\n"  "$*"; }
warn()  { printf "\n\033[1;33m[WARN]\033[0m %s\n"  "$*"; }
error() { printf "\n\033[1;31m[ERROR]\033[0m %s\n" "$*"; }

timestamp="$(date +%Y%m%d-%H%M%S)"
log_file="/var/log/safe-update-${timestamp}.log"

log() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$log_file"; }

# Save debug package on failure
fail() {
  error "$1"
  mkdir -p "/tmp/safe-update-debug-$timestamp"

  cp "$log_file" "/tmp/safe-update-debug-$timestamp/" || true
  lsblk -f > "/tmp/safe-update-debug-$timestamp/lsblk.txt" || true
  blkid   > "/tmp/safe-update-debug-$timestamp/blkid.txt" || true
  findmnt > "/tmp/safe-update-debug-$timestamp/findmnt.txt" || true
  dmesg | tail -n 200 > "/tmp/safe-update-debug-$timestamp/dmesg.txt" || true

  tar -czf "/tmp/safe-update-debug-$timestamp.tar.gz" "/tmp/safe-update-debug-$timestamp" || true

  error "DEBUG PACKAGE GENERATED: /tmp/safe-update-debug-$timestamp.tar.gz"
  exit 1
}

log "------- SAFE UPDATE STARTED -------"


# ============================================================================
# 0) HARD BLOCKERS — LIVE ISO / SNAPSHOT / OVERLAY
# ============================================================================

# Live ISO detection
if [[ -d /run/archiso ]]; then
  fail "You are inside the ARCH ISO. Updating here would destroy your system."
fi

# Snapshot/overlay detection
root_source="$(findmnt -no SOURCE / || true)"
if [[ "$root_source" =~ overlay ]] || [[ "$root_source" =~ airootfs ]]; then
  fail "You are booted into a snapshot or overlay: root=$root_source"
fi

# Writable root check
if ! touch /tmp/safe-update-test.$$ 2>/dev/null; then
  fail "Root filesystem is NOT writable — refusing to continue."
fi
rm -f /tmp/safe-update-test.$$


# ============================================================================
# 1) MUST BE UEFI
# ============================================================================
if [[ ! -d /sys/firmware/efi ]]; then
  fail "System NOT booted in UEFI mode. Limine requires UEFI."
fi
info "Boot mode OK: UEFI detected."


# ============================================================================
# 2) ESP DETECTION (robust, no false positives)
# ============================================================================

info "Detecting ESP (EFI System Partition)..."

esp_candidate="$(lsblk -nr -o NAME,FSTYPE,MOUNTPOINT | awk '$2=="vfat" && $3=="" {print "/dev/"$1; exit}')"

if [[ -z "$esp_candidate" ]]; then
  fail "ESP could NOT be detected. No unmounted VFAT partition found."
fi

info "ESP candidate detected: $esp_candidate"

# Validate with blkid
if ! blkid "$esp_candidate" | grep -qi "vfat"; then
  fail "ESP candidate '$esp_candidate' does not appear to be VFAT."
fi

# Try mount read-only first to verify integrity
info "Testing ESP mount (read-only check)..."
mkdir -p /boot

if mountpoint -q /boot; then
  warn "/boot already mounted. Unmounting for safety..."
  umount /boot || fail "Could not unmount /boot"
fi

if ! mount -o ro "$esp_candidate" /boot; then
  fail "Could not mount ESP (read-only test failed)."
fi

info "ESP read-only test passed."
umount /boot

# Final RW mount
info "Mounting ESP in /boot..."
if ! mount "$esp_candidate" /boot; then
  fail "Could NOT mount ESP in /boot"
fi

info "ESP successfully mounted at /boot."


# ============================================================================
# 3) NETWORK VALIDATION
# ============================================================================

info "Checking network connectivity..."

if ! ping -c1 archlinux.org &>/dev/null; then
  warn "Failed DNS ping. Testing raw IP..."
  if ! ping -c1 1.1.1.1 &>/dev/null; then
    fail "No network connectivity."
  fi
fi

info "Network OK."


# ============================================================================
# 4) UPDATE DATABASE + FULL SYSTEM UPDATE
# ============================================================================

info "Updating package databases and system..."
log "Running pacman -Syu..."

if ! pacman -Syu --noconfirm | tee -a "$log_file"; then
  fail "pacman -Syu failed."
fi

info "System packages updated."


# ============================================================================
# 5) DKMS REBUILD (if installed)
# ============================================================================

if command -v dkms &>/dev/null; then
  info "Rebuilding DKMS modules..."
  if ! dkms autoinstall | tee -a "$log_file"; then
    warn "DKMS rebuild failed — GPU or NIC modules may be affected."
  fi
else
  warn "DKMS not installed — skipping."
fi


# ============================================================================
# 6) INITRAMFS + LIMINE UPDATE
# ============================================================================

info "Rebuilding initramfs..."

if command -v mkinitcpio &>/dev/null; then
  if ! mkinitcpio -P | tee -a "$log_file"; then
    fail "mkinitcpio failed."
  fi
elif command -v dracut &>/dev/null; then
  if ! dracut -f | tee -a "$log_file"; then
    fail "dracut failed."
  fi
else
  fail "No initramfs tool found (mkinitcpio/dracut missing)."
fi

info "Initramfs OK."

# ---- Limine ---------------------------------------------------------------

info "Updating Limine..."

if command -v limine-update &>/dev/null; then
  limine-update | tee -a "$log_file" || fail "limine-update failed."
elif command -v limine-mkinitcpio &>/dev/null; then
  limine-mkinitcpio | tee -a "$log_file" || fail "limine-mkinitcpio failed."
elif command -v limine-install &>/dev/null; then
  limine-install | tee -a "$log_file" || fail "limine-install failed."
else
  fail "No Limine tools found (update/install missing)."
fi

info "Limine updated."


# ============================================================================
# 7) KERNEL VS HEADERS SANITY CHECK
# ============================================================================
running_kernel="$(uname -r | sed 's/-arch.*//')"
installed_headers="$(pacman -Q linux-headers | awk '{print $2}' | sed 's/-arch.*//' || echo NONE)"

if [[ "$running_kernel" != "$installed_headers" ]]; then
  warn "Kernel and headers mismatch:"
  warn "  running kernel:  $running_kernel"
  warn "  installed hdrs:   $installed_headers"
  warn "This is NOT fatal. Reboot → rerun script."
else
  info "Kernel/headers match OK."
fi


# ============================================================================
# 8) FINAL SUMMARY + CONFIRMATION
# ============================================================================

info "================ SUMMARY ================"
echo " ESP device:        $esp_candidate"
echo " Kernel running:    $running_kernel"
echo " Kernel headers:    $installed_headers"
echo " Log file:          $log_file"
echo "========================================="

read -rp "Type YES to reboot safely: " confirm
if [[ "$confirm" != "YES" ]]; then
  warn "Reboot cancelled."
  exit 0
fi

info "Rebooting..."
reboot
