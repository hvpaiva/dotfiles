#!/bin/bash
# chezmoi run_once_after: Final setup — shell, runtimes, services.
set -euo pipefail

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

# Install mise runtimes
if command -v mise &>/dev/null; then
  echo "Installing mise runtimes..."
  mise install --yes 2>/dev/null || true
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
echo "  - Open a new terminal"
echo "  - Run 'nvim' to trigger Lazy plugin install"
echo "  - Log out/in for full Hyprland session"
