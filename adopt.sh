#!/bin/zsh
# adopt.sh - move a dotfile or ~/.config entry into the repo and symlink it back
#
# Usage:
#   ./adopt.sh ~/.foo             # moves to links/foo, symlinks ~/.foo
#   ./adopt.sh ~/.config/foo      # moves to config/foo, symlinks ~/.config/foo
#   ./adopt.sh --force ~/.foo     # overwrite an existing repo destination

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FORCE=false

if [[ "${1:-}" == "--force" || "${1:-}" == "-f" ]]; then
  FORCE=true
  shift
fi

if [[ -z "$1" ]]; then
  echo "Usage: $0 [--force|-f] <~/.dotfile | ~/.config/name>"
  exit 1
fi

# Resolve to absolute path
target=$(realpath "$1" 2>/dev/null || echo "$1")

if [[ "$target" == "$HOME/.config/"* ]]; then
  # ~/.config/<name> case
  name=$(basename "$target")
  dest="$SCRIPT_DIR/config/$name"

  if [[ -L "$target" ]]; then
    echo "Error: '$target' is already a symbolic link. Aborting."
    exit 1
  fi
  if [[ ! -e "$target" ]]; then
    echo "Error: '$target' does not exist."
    exit 1
  fi
  if [[ -e "$dest" && "$FORCE" != true ]]; then
    echo "Error: destination '$dest' already exists. Re-run with --force to overwrite it."
    exit 1
  fi

  echo "mv $target $dest"
  mv "$target" "$dest"
  echo "ln -nfs $dest $target"
  ln -nfs "$dest" "$target"

else
  # ~/.foo case
  filename=$(basename "$target")

  if [[ ! "$filename" =~ ^\. ]]; then
    echo "Error: '$filename' does not start with a dot. Did you mean ~/.config/$filename?"
    exit 1
  fi
  if [[ -L "$target" ]]; then
    echo "Error: '$target' is already a symbolic link. Aborting."
    exit 1
  fi
  if [[ ! -e "$target" ]]; then
    echo "Error: '$target' does not exist."
    exit 1
  fi

  # Strip leading dot for the repo filename
  link="${filename:1}"
  dest="$SCRIPT_DIR/links/$link"

  if [[ -e "$dest" && "$FORCE" != true ]]; then
    echo "Error: destination '$dest' already exists. Re-run with --force to overwrite it."
    exit 1
  fi

  echo "mv $target $dest"
  mv "$target" "$dest"
  echo "ln -nfs $dest $target"
  ln -nfs "$dest" "$target"
fi
