#!/bin/bash
# chezmoi run_once_after: Final setup tasks
set -euo pipefail

# Set fish as default shell if available and not already set
if command -v fish &>/dev/null; then
  FISH_PATH="$(command -v fish)"
  if [[ "$SHELL" != "$FISH_PATH" ]]; then
    if grep -qF "$FISH_PATH" /etc/shells; then
      echo "Setting fish as default shell..."
      chsh -s "$FISH_PATH" || echo "WARN: Could not change shell (run manually: chsh -s $FISH_PATH)"
    else
      echo "WARN: fish ($FISH_PATH) not in /etc/shells — add it first."
    fi
  fi
fi

# Activate mise if available
if command -v mise &>/dev/null; then
  echo "Activating mise..."
  mise install --yes 2>/dev/null || true
fi

# Enable systemd user services
if command -v systemctl &>/dev/null; then
  echo "Enabling user services..."
  systemctl --user daemon-reload || true
  systemctl --user enable --now elephant.service 2>/dev/null || true
fi

echo "Finalize complete."
