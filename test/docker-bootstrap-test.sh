#!/usr/bin/env bash
# test/docker-bootstrap-test.sh — Simulate a fresh machine bootstrap in Docker.
#
# Builds an Arch Linux container, runs chezmoi init --apply from the public
# GitHub repo (hvpaiva/dotfiles), and validates the result.
#
# Usage:
#   ./test/docker-bootstrap-test.sh            # build & run (default)
#   ./test/docker-bootstrap-test.sh --no-cache # force full rebuild
#   ./test/docker-bootstrap-test.sh --keep     # don't remove container on exit
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE_NAME="dotfiles-bootstrap-test"
DOCKERFILE="$REPO_ROOT/test/Dockerfile.bootstrap"

NO_CACHE=""
DOCKER_OPTS="--rm"

for arg in "$@"; do
  case "$arg" in
    --no-cache) NO_CACHE="--no-cache" ;;
    --keep)     DOCKER_OPTS="" ;;
  esac
done

echo "======================================"
echo " Bootstrap simulation"
echo " Image : $IMAGE_NAME"
echo " Source: test/Dockerfile.bootstrap"
echo "======================================"
echo ""
echo "Building image..."
docker build $NO_CACHE -t "$IMAGE_NAME" -f "$DOCKERFILE" "$REPO_ROOT/test"

echo ""
echo "Running bootstrap..."
docker run $DOCKER_OPTS "$IMAGE_NAME"
