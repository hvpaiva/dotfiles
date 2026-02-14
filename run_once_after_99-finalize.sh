#!/bin/bash
# chezmoi run_once_after: Final setup — shell, runtimes, tools, services.
set -euo pipefail

PKGDIR="$HOME/.config/packages"

echo ""
echo "======================================"
echo " Finalize"
echo "======================================"
echo ""

# Ensure bash is the default shell
BASH_PATH="/usr/bin/bash"
if [[ "$SHELL" != "$BASH_PATH" ]]; then
  echo "Setting bash as default shell..."
  chsh -s "$BASH_PATH" || echo "WARN: Could not change shell (run: chsh -s $BASH_PATH)"
else
  echo "Bash is already default shell."
fi

# Install ble.sh (Bash Line Editor)
BLESH_DIR="$HOME/.local/share/blesh"
if [[ ! -d "$BLESH_DIR" ]]; then
  echo "Installing ble.sh..."
  tmpdir=$(mktemp -d)
  git clone --recursive --depth 1 https://github.com/akinomyoga/ble.sh.git "$tmpdir/ble.sh"
  make -C "$tmpdir/ble.sh" install PREFIX="$HOME/.local" 2>/dev/null || {
    echo "WARN: ble.sh build failed. Install manually: https://github.com/akinomyoga/ble.sh"
  }
  rm -rf "$tmpdir"
else
  echo "ble.sh already installed."
fi

# Install mise runtimes
if command -v mise &>/dev/null; then
  echo "Installing mise runtimes..."
  mise install --yes 2>/dev/null || true
fi

# Install cargo packages
if command -v cargo &>/dev/null && [[ -f "$PKGDIR/cargo.txt" ]]; then
  echo "Installing cargo packages..."
  while read -r pkg; do
    [[ -z "${pkg// }" || "$pkg" =~ ^# ]] && continue
    if ! cargo install --list 2>/dev/null | grep -q "^$pkg "; then
      echo "  cargo install $pkg"
      cargo install "$pkg" 2>/dev/null || echo "  WARN: failed to install $pkg"
    fi
  done < "$PKGDIR/cargo.txt"
fi

# Install npm global packages
if command -v npm &>/dev/null && [[ -f "$PKGDIR/npm.txt" ]]; then
  echo "Installing npm global packages..."
  while read -r pkg; do
    [[ -z "${pkg// }" || "$pkg" =~ ^# ]] && continue
    if ! npm list -g "$pkg" &>/dev/null; then
      echo "  npm install -g $pkg"
      npm install -g "$pkg" 2>/dev/null || echo "  WARN: failed to install $pkg"
    fi
  done < "$PKGDIR/npm.txt"
fi

# Install go tools
if command -v go &>/dev/null && [[ -f "$PKGDIR/go.txt" ]]; then
  echo "Installing go tools..."
  while read -r pkg; do
    [[ -z "${pkg// }" || "$pkg" =~ ^# ]] && continue
    echo "  go install $pkg"
    go install "$pkg" 2>/dev/null || echo "  WARN: failed to install $pkg"
  done < "$PKGDIR/go.txt"
fi

# Install pip/pipx packages
if command -v pipx &>/dev/null && [[ -f "$PKGDIR/pip.txt" ]]; then
  echo "Installing pipx packages..."
  while read -r pkg; do
    [[ -z "${pkg// }" || "$pkg" =~ ^# ]] && continue
    if ! pipx list --short 2>/dev/null | grep -q "^$pkg "; then
      echo "  pipx install $pkg"
      pipx install "$pkg" 2>/dev/null || echo "  WARN: failed to install $pkg"
    fi
  done < "$PKGDIR/pip.txt"
fi

# Enable systemd user services
if command -v systemctl &>/dev/null; then
  echo "Enabling user services..."
  systemctl --user daemon-reload || true
  systemctl --user enable --now elephant.service 2>/dev/null || true
fi

echo ""
echo "======================================"
echo " Bootstrap complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo "  - Run 'exec bash -l' to reload shell with ble.sh"
echo "  - Run 'nvim' to trigger Lazy plugin install"
echo "  - Log out/in for full Hyprland session"
