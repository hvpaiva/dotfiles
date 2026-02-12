#!/bin/bash
# chezmoi run_once_after: Final setup — shell, runtimes, services.
set -euo pipefail

echo ""
echo "======================================"
echo " Finalize"
echo "======================================"
echo ""

# Set fish as default shell
if command -v fish &>/dev/null; then
  FISH_PATH="$(command -v fish)"
  if [[ "$SHELL" != "$FISH_PATH" ]]; then
    if grep -qF "$FISH_PATH" /etc/shells; then
      echo "Setting fish as default shell..."
      chsh -s "$FISH_PATH" || echo "WARN: Could not change shell (run: chsh -s $FISH_PATH)"
    else
      echo "Adding fish to /etc/shells..."
      echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
      echo "Setting fish as default shell..."
      chsh -s "$FISH_PATH" || echo "WARN: Could not change shell (run: chsh -s $FISH_PATH)"
    fi
  else
    echo "Fish is already default shell."
  fi
else
  echo "WARN: fish not installed — skipping shell change."
fi

# Install mise runtimes
if command -v mise &>/dev/null; then
  echo "Installing mise runtimes..."
  mise install --yes 2>/dev/null || true
fi

# Install fisher plugins (if fish and fisher are available)
if command -v fish &>/dev/null && fish -c 'type -q fisher' 2>/dev/null; then
  echo "Installing fisher plugins..."
  fish -c 'fisher update' 2>/dev/null || true
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
echo "  - Open a new terminal (fish shell)"
echo "  - Run 'nvim' to trigger Lazy plugin install"
echo "  - Log out/in for full Hyprland session"
