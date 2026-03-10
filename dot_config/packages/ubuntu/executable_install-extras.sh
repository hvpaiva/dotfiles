#!/usr/bin/env bash
# Install tools not available via apt on Ubuntu.
# Each tool is guarded — only installs if not already present.
set -euo pipefail

echo "Installing extra tools..."

mkdir -p "$HOME/.local/bin"

# ─── oh-my-posh (prompt) ─────────────────────────────────────────────
if ! command -v oh-my-posh &>/dev/null; then
  echo "  Installing oh-my-posh..."
  curl -s https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin"
fi

# ─── Starship (prompt) ───────────────────────────────────────────────
if ! command -v starship &>/dev/null; then
  echo "  Installing starship..."
  curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# ─── Ghostty (terminal) ──────────────────────────────────────────────
if ! command -v ghostty &>/dev/null; then
  echo "  Installing ghostty..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)" || {
    echo "  WARN: Ghostty install failed. See https://github.com/mkasberg/ghostty-ubuntu"
  }
fi

# ─── Lazygit ──────────────────────────────────────────────────────────
if ! command -v lazygit &>/dev/null; then
  echo "  Installing lazygit..."
  LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" \
    | grep -Po '"tag_name": *"v\K[^"]*')
  curl -Lo /tmp/lazygit.tar.gz \
    "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
  tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
  sudo install /tmp/lazygit /usr/local/bin/
  rm -f /tmp/lazygit /tmp/lazygit.tar.gz
fi

# ─── Lazydocker ───────────────────────────────────────────────────────
if ! command -v lazydocker &>/dev/null; then
  echo "  Installing lazydocker..."
  LAZYDOCKER_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazydocker/releases/latest" \
    | grep -Po '"tag_name": *"v\K[^"]*')
  curl -Lo /tmp/lazydocker.tar.gz \
    "https://github.com/jesseduffield/lazydocker/releases/download/v${LAZYDOCKER_VERSION}/lazydocker_${LAZYDOCKER_VERSION}_Linux_x86_64.tar.gz"
  tar xf /tmp/lazydocker.tar.gz -C /tmp lazydocker
  sudo install /tmp/lazydocker /usr/local/bin/
  rm -f /tmp/lazydocker /tmp/lazydocker.tar.gz
fi

# ─── sesh (tmux session manager) ─────────────────────────────────────
if ! command -v sesh &>/dev/null; then
  echo "  Installing sesh..."
  SESH_VERSION=$(curl -s "https://api.github.com/repos/joshmedeski/sesh/releases/latest" \
    | grep -Po '"tag_name": *"v\K[^"]*')
  curl -Lo /tmp/sesh.tar.gz \
    "https://github.com/joshmedeski/sesh/releases/download/v${SESH_VERSION}/sesh_Linux_x86_64.tar.gz"
  tar xf /tmp/sesh.tar.gz -C /tmp sesh
  sudo install /tmp/sesh /usr/local/bin/
  rm -f /tmp/sesh /tmp/sesh.tar.gz
fi

# ─── gum (TUI toolkit) ───────────────────────────────────────────────
if ! command -v gum &>/dev/null; then
  echo "  Installing gum..."
  GUM_VERSION=$(curl -s "https://api.github.com/repos/charmbracelet/gum/releases/latest" \
    | grep -Po '"tag_name": *"v\K[^"]*')
  curl -Lo /tmp/gum.deb \
    "https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/gum_${GUM_VERSION}_amd64.deb"
  sudo dpkg -i /tmp/gum.deb || sudo apt-get install -f -y
  rm -f /tmp/gum.deb
fi

# ─── tflint ───────────────────────────────────────────────────────────
if ! command -v tflint &>/dev/null; then
  echo "  Installing tflint..."
  curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
fi

# ─── helm ─────────────────────────────────────────────────────────────
if ! command -v helm &>/dev/null; then
  echo "  Installing helm..."
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# ─── Rust (via rustup) ───────────────────────────────────────────────
if ! command -v rustup &>/dev/null; then
  echo "  Installing Rust via rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  # shellcheck source=/dev/null
  source "$HOME/.cargo/env"
fi

# ─── Nerd Fonts ───────────────────────────────────────────────────────
FONT_DIR="$HOME/.local/share/fonts"
if [[ ! -f "$FONT_DIR/JetBrainsMonoNerdFont-Regular.ttf" ]]; then
  echo "  Installing Nerd Fonts (JetBrainsMono, Meslo, CascadiaMono)..."
  mkdir -p "$FONT_DIR"
  for font in JetBrainsMono Meslo CascadiaMono; do
    curl -Lo "/tmp/${font}.tar.xz" \
      "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.tar.xz"
    tar xf "/tmp/${font}.tar.xz" -C "$FONT_DIR"
    rm -f "/tmp/${font}.tar.xz"
  done
  fc-cache -fv
fi

# ─── eza (ls replacement, not in Ubuntu 24.04 repos) ─────────────────
if ! command -v eza &>/dev/null; then
  echo "  Installing eza..."
  EZA_VERSION=$(curl -s "https://api.github.com/repos/eza-community/eza/releases/latest" \
    | grep -Po '"tag_name": *"v\K[^"]*')
  curl -Lo /tmp/eza.tar.gz \
    "https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_x86_64-unknown-linux-gnu.tar.gz"
  tar xf /tmp/eza.tar.gz -C /tmp
  sudo install /tmp/eza /usr/local/bin/
  rm -f /tmp/eza /tmp/eza.tar.gz
fi

# ─── zoxide (cd replacement, may not be in older Ubuntu repos) ───────
if ! command -v zoxide &>/dev/null; then
  echo "  Installing zoxide..."
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
fi

# ─── fastfetch (system info, not in Ubuntu 24.04 repos) ──────────────
if ! command -v fastfetch &>/dev/null; then
  echo "  Installing fastfetch..."
  FF_VERSION=$(curl -s "https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest" \
    | grep -Po '"tag_name": *"\K[^"]*')
  curl -Lo /tmp/fastfetch.deb \
    "https://github.com/fastfetch-cli/fastfetch/releases/download/${FF_VERSION}/fastfetch-linux-amd64.deb"
  sudo dpkg -i /tmp/fastfetch.deb || sudo apt-get install -f -y
  rm -f /tmp/fastfetch.deb
fi

# ─── Walker (app launcher, not in Ubuntu repos) ─────────────────────
if ! command -v walker &>/dev/null; then
  echo "  Installing walker..."
  WALKER_VERSION=$(curl -s "https://api.github.com/repos/abenz1267/walker/releases/latest" \
    | grep -Po '"tag_name": *"v\K[^"]*')
  curl -Lo /tmp/walker.deb \
    "https://github.com/abenz1267/walker/releases/download/v${WALKER_VERSION}/walker-amd64.deb"
  sudo dpkg -i /tmp/walker.deb || sudo apt-get install -f -y
  rm -f /tmp/walker.deb
fi

# ─── SwayOSD (on-screen display, not in Ubuntu 24.04 repos) ─────────
if ! command -v swayosd-server &>/dev/null; then
  echo "  Installing swayosd..."
  SWAYOSD_VERSION=$(curl -s "https://api.github.com/repos/ErikReider/SwayOSD/releases/latest" \
    | grep -Po '"tag_name": *"v\K[^"]*')
  if [[ -n "$SWAYOSD_VERSION" ]]; then
    curl -Lo /tmp/swayosd.tar.gz \
      "https://github.com/ErikReider/SwayOSD/releases/download/v${SWAYOSD_VERSION}/swayosd-v${SWAYOSD_VERSION}-x86_64.tar.gz"
    sudo tar xf /tmp/swayosd.tar.gz -C /usr/local
    rm -f /tmp/swayosd.tar.gz
  else
    echo "  WARN: Could not determine SwayOSD version. Skipping."
  fi
fi

# ─── uwsm (Universal Wayland Session Manager) ───────────────────────
if ! command -v uwsm-app &>/dev/null; then
  echo "  Installing uwsm via pip..."
  pipx install uwsm 2>/dev/null || pip install --user uwsm 2>/dev/null || {
    echo "  WARN: uwsm install failed. Install manually."
  }
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

echo "Extra tools installed."
