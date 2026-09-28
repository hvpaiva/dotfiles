#!/usr/bin/env bash
# Setup external APT repositories needed by dev.txt and work.txt.
# Idempotent — safe to re-run.
set -euo pipefail

echo "Setting up external repositories..."

ARCH="$(dpkg --print-architecture)"
CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"

add_key_and_repo() {
  local name="$1"
  local url_key="$2"
  local repo_line="$3"
  local list="/etc/apt/sources.list.d/${name}.list"
  if [[ -f "$list" ]]; then
    echo "  $name: already configured"
    return
  fi
  echo "  $name: adding..."
  curl -fsSL "$url_key" | sudo gpg --dearmor -o "/usr/share/keyrings/${name}-archive-keyring.gpg"
  echo "$repo_line" | sudo tee "$list" > /dev/null
}

# GitHub CLI
add_key_and_repo "githubcli" \
  "https://cli.github.com/packages/githubcli-archive-keyring.gpg" \
  "deb [arch=${ARCH} signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main"

# Docker
add_key_and_repo "docker" \
  "https://download.docker.com/linux/ubuntu/gpg" \
  "deb [arch=${ARCH} signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu ${CODENAME} stable"

# mise (runtime manager)
if [[ ! -f /etc/apt/sources.list.d/mise.list ]]; then
  echo "  mise: adding..."
  sudo install -dm 755 /etc/apt/keyrings
  curl -fsSL https://mise.jdx.dev/gpg-key.pub \
    | sudo tee /etc/apt/keyrings/mise-archive-keyring.asc > /dev/null
  echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.asc] https://mise.jdx.dev/deb stable main" \
    | sudo tee /etc/apt/sources.list.d/mise.list > /dev/null
fi

# Hyprland (community PPA by cppiber — latest builds for Ubuntu)
if ! grep -rq "cppiber/hyprland" /etc/apt/sources.list.d/ 2>/dev/null; then
  echo "  hyprland-ppa: adding..."
  sudo add-apt-repository -y ppa:cppiber/hyprland
fi

# Neovim (unstable PPA for latest version)
if ! grep -rq "neovim-ppa" /etc/apt/sources.list.d/ 2>/dev/null; then
  echo "  neovim-ppa: adding..."
  sudo add-apt-repository -y ppa:neovim-ppa/unstable
fi

# HashiCorp (Terraform) — only if work packages will be installed
if [[ ! -f /etc/apt/sources.list.d/hashicorp.list ]]; then
  echo "  hashicorp: adding..."
  curl -fsSL https://apt.releases.hashicorp.com/gpg \
    | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [arch=${ARCH} signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com ${CODENAME} main" \
    | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
fi

sudo apt-get update
echo "External repositories configured."
