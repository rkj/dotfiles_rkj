#!/usr/bin/env bash
# Smoke-test dotfiles in a clean Debian container.
# Usage: ./test-in-docker.sh
#
# Works with remote Docker contexts by using docker cp instead of bind mounts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

CONTAINER=$(docker create debian:bookworm sleep 3600)
trap "docker rm -f $CONTAINER >/dev/null 2>&1" EXIT

# Copy repo into container
docker cp "$SCRIPT_DIR" "$CONTAINER:/dotfiles"

# Start container and run test
docker start "$CONTAINER" >/dev/null

docker exec "$CONTAINER" bash -eux -c '
  apt-get update -qq
  apt-get install -y -qq zsh fish git sudo coreutils >/dev/null 2>&1

  useradd -m -s /bin/bash testuser
  cp -r /dotfiles /home/testuser/dotfiles_rkj
  chown -R testuser:testuser /home/testuser/dotfiles_rkj

  su - testuser -c "bash /home/testuser/dotfiles_rkj/test-inner.sh"
'
