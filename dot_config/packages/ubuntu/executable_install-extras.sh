#!/usr/bin/env bash
# Install tools not available via apt on Ubuntu.
# Each tool is guarded — only installs if not already present.
# Does NOT exit on error — collects results and shows overview at the end.

echo ""
echo "======================================"
echo " Installing extra tools"
echo "======================================"
echo ""

mkdir -p "$HOME/.local/bin"

SUCCEEDED=()
FAILED=()
SKIPPED=()

try_install() {
  local name="$1"
  shift
  echo "  [$name] installing..."
  if "$@" 2>&1; then
    # Verify the command is now available
    if command -v "$name" &>/dev/null || [[ "$name" == "nerd-fonts" ]] || [[ "$name" == "adw-gtk3" ]] || [[ "$name" == "rust" ]]; then
      SUCCEEDED+=("$name")
      echo "  [$name] OK"
    else
      FAILED+=("$name")
      echo "  [$name] FAILED (command not found after install)"
    fi
  else
    FAILED+=("$name")
    echo "  [$name] FAILED"
  fi
}

# ─── oh-my-posh (prompt) ─────────────────────────────────────────────
if command -v oh-my-posh &>/dev/null; then
  SKIPPED+=("oh-my-posh")
else
  try_install "oh-my-posh" bash -c 'curl -s https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin"'
fi

# ─── Starship (prompt) ───────────────────────────────────────────────
if command -v starship &>/dev/null; then
  SKIPPED+=("starship")
else
  try_install "starship" bash -c 'curl -sS https://starship.rs/install.sh | sh -s -- -y'
fi

# ─── Ghostty (terminal) ──────────────────────────────────────────────
if command -v ghostty &>/dev/null; then
  SKIPPED+=("ghostty")
else
  try_install "ghostty" bash -c '
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)"
  '
fi

# ─── Lazygit ──────────────────────────────────────────────────────────
if command -v lazygit &>/dev/null; then
  SKIPPED+=("lazygit")
else
  try_install "lazygit" bash -c 'set -e
    V=$(curl -sf "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po "\"tag_name\": *\"v\K[^\"]*")
    curl -fLo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${V}/lazygit_${V}_Linux_x86_64.tar.gz"
    tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
    sudo install /tmp/lazygit /usr/local/bin/
    rm -f /tmp/lazygit /tmp/lazygit.tar.gz
  '
fi

# ─── Lazydocker ───────────────────────────────────────────────────────
if command -v lazydocker &>/dev/null; then
  SKIPPED+=("lazydocker")
else
  try_install "lazydocker" bash -c 'set -e
    V=$(curl -sf "https://api.github.com/repos/jesseduffield/lazydocker/releases/latest" | grep -Po "\"tag_name\": *\"v\K[^\"]*")
    curl -fLo /tmp/lazydocker.tar.gz "https://github.com/jesseduffield/lazydocker/releases/download/v${V}/lazydocker_${V}_Linux_x86_64.tar.gz"
    tar xf /tmp/lazydocker.tar.gz -C /tmp lazydocker
    sudo install /tmp/lazydocker /usr/local/bin/
    rm -f /tmp/lazydocker /tmp/lazydocker.tar.gz
  '
fi

# ─── sesh (tmux session manager) ─────────────────────────────────────
if command -v sesh &>/dev/null; then
  SKIPPED+=("sesh")
else
  try_install "sesh" bash -c 'set -e
    V=$(curl -sf "https://api.github.com/repos/joshmedeski/sesh/releases/latest" | grep -Po "\"tag_name\": *\"v\K[^\"]*")
    curl -fLo /tmp/sesh.tar.gz "https://github.com/joshmedeski/sesh/releases/download/v${V}/sesh_Linux_x86_64.tar.gz"
    tar xf /tmp/sesh.tar.gz -C /tmp sesh
    sudo install /tmp/sesh /usr/local/bin/
    rm -f /tmp/sesh /tmp/sesh.tar.gz
  '
fi

# ─── gum (TUI toolkit) ───────────────────────────────────────────────
if command -v gum &>/dev/null; then
  SKIPPED+=("gum")
else
  try_install "gum" bash -c 'set -e
    V=$(curl -sf "https://api.github.com/repos/charmbracelet/gum/releases/latest" | grep -Po "\"tag_name\": *\"v\K[^\"]*")
    curl -fLo /tmp/gum.deb "https://github.com/charmbracelet/gum/releases/download/v${V}/gum_${V}_amd64.deb"
    sudo dpkg -i /tmp/gum.deb || sudo apt-get install -f -y
    rm -f /tmp/gum.deb
  '
fi

# ─── tflint ───────────────────────────────────────────────────────────
if command -v tflint &>/dev/null; then
  SKIPPED+=("tflint")
else
  try_install "tflint" bash -c 'curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash'
fi

# ─── helm ─────────────────────────────────────────────────────────────
if command -v helm &>/dev/null; then
  SKIPPED+=("helm")
else
  try_install "helm" bash -c 'curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash'
fi

# ─── Rust (via rustup) ───────────────────────────────────────────────
if command -v rustup &>/dev/null; then
  SKIPPED+=("rust")
else
  try_install "rust" bash -c '
    curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  '
fi

# Ensure cargo is in PATH for later steps (Rust install runs in subshell)
if [[ -f "$HOME/.cargo/env" ]]; then
  # shellcheck source=/dev/null
  source "$HOME/.cargo/env"
fi

# ─── Nerd Fonts ───────────────────────────────────────────────────────
FONT_DIR="$HOME/.local/share/fonts"
if [[ -f "$FONT_DIR/JetBrainsMonoNerdFont-Regular.ttf" ]]; then
  SKIPPED+=("nerd-fonts")
else
  try_install "nerd-fonts" bash -c 'set -e
    FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"
    for font in JetBrainsMono Meslo CascadiaMono; do
      curl -fLo "/tmp/${font}.tar.xz" \
        "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.tar.xz"
      tar xf "/tmp/${font}.tar.xz" -C "$FONT_DIR"
      rm -f "/tmp/${font}.tar.xz"
    done
    fc-cache -fv
  '
fi

# ─── eza (ls replacement, not in Ubuntu 24.04 repos) ─────────────────
if command -v eza &>/dev/null; then
  SKIPPED+=("eza")
else
  try_install "eza" bash -c 'set -e
    V=$(curl -sf "https://api.github.com/repos/eza-community/eza/releases/latest" | grep -Po "\"tag_name\": *\"v\K[^\"]*")
    curl -fLo /tmp/eza.tar.gz "https://github.com/eza-community/eza/releases/download/v${V}/eza_x86_64-unknown-linux-gnu.tar.gz"
    tar xf /tmp/eza.tar.gz -C /tmp
    sudo install /tmp/eza /usr/local/bin/
    rm -f /tmp/eza /tmp/eza.tar.gz
  '
fi

# ─── zoxide (cd replacement, may not be in older Ubuntu repos) ───────
if command -v zoxide &>/dev/null; then
  SKIPPED+=("zoxide")
else
  try_install "zoxide" bash -c 'curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh'
fi

# ─── fastfetch (system info, not in Ubuntu 24.04 repos) ──────────────
if command -v fastfetch &>/dev/null; then
  SKIPPED+=("fastfetch")
else
  try_install "fastfetch" bash -c 'set -e
    V=$(curl -sf "https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest" | grep -Po "\"tag_name\": *\"\K[^\"]*")
    curl -fLo /tmp/fastfetch.deb "https://github.com/fastfetch-cli/fastfetch/releases/download/${V}/fastfetch-linux-amd64.deb"
    sudo dpkg -i /tmp/fastfetch.deb || sudo apt-get install -f -y
    rm -f /tmp/fastfetch.deb
  '
fi

# ─── Walker (app launcher — tarball, no .deb available) ──────────────
if command -v walker &>/dev/null; then
  SKIPPED+=("walker")
else
  try_install "walker" bash -c 'set -e
    V=$(curl -sf "https://api.github.com/repos/abenz1267/walker/releases/latest" | grep -Po "\"tag_name\": *\"v\K[^\"]*")
    curl -fLo /tmp/walker.tar.gz "https://github.com/abenz1267/walker/releases/download/v${V}/walker-v${V}-x86_64-unknown-linux-gnu.tar.gz"
    tar xf /tmp/walker.tar.gz -C /tmp
    sudo install /tmp/walker /usr/local/bin/
    rm -f /tmp/walker /tmp/walker.tar.gz
  '
fi

# ─── xdg-terminal-exec (freedesktop terminal launcher) ───────────────
if command -v xdg-terminal-exec &>/dev/null; then
  SKIPPED+=("xdg-terminal-exec")
else
  try_install "xdg-terminal-exec" bash -c '
    tmpdir=$(mktemp -d)
    git clone https://github.com/Vladimir-csp/xdg-terminal-exec.git "$tmpdir/xdg-terminal-exec"
    sudo install "$tmpdir/xdg-terminal-exec/xdg-terminal-exec" /usr/local/bin/
    rm -rf "$tmpdir"
  '
fi

# ─── cliphist (clipboard history for Wayland) ────────────────────────
if command -v cliphist &>/dev/null; then
  SKIPPED+=("cliphist")
else
  try_install "cliphist" bash -c 'set -e
    V=$(curl -sf "https://api.github.com/repos/sentriz/cliphist/releases/latest" | grep -Po "\"tag_name\": *\"v\K[^\"]*")
    curl -fLo /tmp/cliphist "https://github.com/sentriz/cliphist/releases/download/v${V}/v${V}-linux-amd64"
    chmod +x /tmp/cliphist
    sudo install /tmp/cliphist /usr/local/bin/
    rm -f /tmp/cliphist
  '
fi

# ─── hyprpicker (color picker for Hyprland — build from source) ──────
if command -v hyprpicker &>/dev/null; then
  SKIPPED+=("hyprpicker")
else
  if command -v cmake &>/dev/null; then
    try_install "hyprpicker" bash -c 'set -e
      sudo apt-get install -y libwayland-dev libpango1.0-dev libcairo2-dev wayland-protocols libxkbcommon-dev 2>/dev/null
      tmpdir=$(mktemp -d)
      V=$(curl -sf "https://api.github.com/repos/hyprwm/hyprpicker/releases/latest" | grep -Po "\"tag_name\": *\"v\K[^\"]*")
      curl -fL "https://github.com/hyprwm/hyprpicker/archive/refs/tags/v${V}.tar.gz" -o "$tmpdir/hyprpicker.tar.gz"
      tar xzf "$tmpdir/hyprpicker.tar.gz" -C "$tmpdir"
      cd "$tmpdir/hyprpicker-${V}"
      cmake -B build
      cmake --build build -j"$(nproc)"
      sudo install build/hyprpicker /usr/local/bin/
      rm -rf "$tmpdir"
    '
  else
    echo "  [hyprpicker] skipped (cmake not available — install cmake first)"
    SKIPPED+=("hyprpicker")
  fi
fi

# ─── gtk4-layer-shell (not packaged on Ubuntu 24.04, needed by SwayOSD) ──
if pkg-config --exists gtk4-layer-shell-0 2>/dev/null; then
  SKIPPED+=("gtk4-layer-shell")
else
  try_install "gtk4-layer-shell" bash -c 'set -e
    sudo apt-get install -y meson ninja-build libwayland-dev wayland-protocols \
      libgtk-4-dev gobject-introspection libgirepository1.0-dev valac
    tmpdir=$(mktemp -d)
    git clone --depth 1 --branch v1.3.0 https://github.com/wmww/gtk4-layer-shell.git "$tmpdir/gtk4-layer-shell"
    cd "$tmpdir/gtk4-layer-shell"
    meson setup build --prefix=/usr -Dtests=false -Ddocs=false -Dexamples=false
    ninja -C build
    sudo ninja -C build install
    sudo ldconfig
    rm -rf "$tmpdir"
  '
fi

# ─── SwayOSD (needs gtk4-layer-shell + cargo) ─────────────────────────
if command -v swayosd-server &>/dev/null; then
  SKIPPED+=("swayosd")
else
  if command -v cargo &>/dev/null && pkg-config --exists gtk4-layer-shell-0 2>/dev/null; then
    try_install "swayosd-server" bash -c 'set -e
      sudo apt-get install -y libgtk-4-dev libpulse-dev libevdev-dev libudev-dev libdbus-1-dev libinput-dev
      tmpdir=$(mktemp -d)
      git clone https://github.com/ErikReider/SwayOSD.git "$tmpdir/swayosd"
      cd "$tmpdir/swayosd"
      cargo build --release
      sudo install target/release/swayosd-server /usr/local/bin/
      sudo install target/release/swayosd-client /usr/local/bin/
      rm -rf "$tmpdir"
    '
  else
    echo "  [swayosd] skipped (needs cargo + gtk4-layer-shell — retry after installing both)"
    SKIPPED+=("swayosd")
  fi
fi

# ─── adw-gtk3 (dark GTK theme for Hyprland standalone) ──────────────
if [[ -d "$HOME/.local/share/themes/adw-gtk3-dark" ]] || dpkg -l adw-gtk3 &>/dev/null 2>&1; then
  SKIPPED+=("adw-gtk3")
else
  try_install "adw-gtk3" bash -c 'set -e
    V=$(curl -sf "https://api.github.com/repos/lassekongo83/adw-gtk3/releases/latest" | grep -Po "\"tag_name\": *\"\K[^\"]*")
    curl -fLo /tmp/adw-gtk3.tar.xz "https://github.com/lassekongo83/adw-gtk3/releases/download/${V}/adw-gtk3${V}.tar.xz"
    mkdir -p "$HOME/.local/share/themes"
    tar xf /tmp/adw-gtk3.tar.xz -C "$HOME/.local/share/themes"
    rm -f /tmp/adw-gtk3.tar.xz
  '
fi

# ─── Symlinks for Ubuntu-renamed binaries ─────────────────────────────
if command -v batcat &>/dev/null && [[ ! -e "$HOME/.local/bin/bat" ]]; then
  echo "  Creating symlink: bat -> batcat"
  ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
fi

if command -v fdfind &>/dev/null && [[ ! -e "$HOME/.local/bin/fd" ]]; then
  echo "  Creating symlink: fd -> fdfind"
  ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi

# ─── Overview ─────────────────────────────────────────────────────────
echo ""
echo "======================================"
echo " Extra tools — Overview"
echo "======================================"
echo ""
if [[ ${#SUCCEEDED[@]} -gt 0 ]]; then
  echo "  Installed: ${SUCCEEDED[*]}"
fi
if [[ ${#SKIPPED[@]} -gt 0 ]]; then
  echo "  Skipped (already present): ${SKIPPED[*]}"
fi
if [[ ${#FAILED[@]} -gt 0 ]]; then
  echo "  FAILED: ${FAILED[*]}"
  echo ""
  echo "  Some tools failed to install. You can retry them manually later."
fi
echo ""
