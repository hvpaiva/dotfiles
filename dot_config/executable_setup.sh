#!/usr/bin/env bash
# Bootstrap script (run from repo root).
# 1. Run the pre‑built `bones` binary to install managers & packages.
# 2. Ensure chezmoi is installed/up‑to‑date via Homebrew.
# 3. Apply the dotfiles.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"   # repo root
BONES_BIN="$REPO_DIR/bones"

if [[ ! -x "$BONES_BIN" ]]; then
  echo "❌  bones binary not found at $BONES_BIN" >&2
  exit 1
fi

# Step 1 · Install software layer
echo "🚀  Running bones up (this may take a while)…"
"$BONES_BIN" up -m "$REPO_DIR/packages.toml"

echo ""
# Step 2 · ChezMoi (Bones already ensured brew exists)
if ! command -v chezmoi >/dev/null 2>&1; then
  echo "🏗  Installing Chezmoi via Homebrew…"
  brew install chezmoi >/dev/null
fi

echo ""
# Step 3 · Apply dotfiles (source is this repo)
chezmoi apply --source="$REPO_DIR"

echo "✅  Bootstrap complete"
