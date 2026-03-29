#!/bin/zsh
# adopt.sh - move a dotfile or ~/.config entry into the repo and symlink it back
#
# Usage:
#   ./adopt.sh ~/.foo           # moves to links/foo, symlinks ~/.foo
#   ./adopt.sh ~/.config/foo    # moves to config/foo, symlinks ~/.config/foo

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ -z "$1" ]]; then
  echo "Usage: $0 <~/.dotfile | ~/.config/name>"
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

  echo "mv $target $dest"
  mv "$target" "$dest"
  echo "ln -nfs $dest $target"
  ln -nfs "$dest" "$target"
fi
