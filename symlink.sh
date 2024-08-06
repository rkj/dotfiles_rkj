#!/bin/zsh

root="$(cd "$(dirname "$0")" && pwd)"
link_root="$root/links"

# Create symlinks
find "$link_root" -type f | while read -r link; do
    target="$HOME/.${link#$link_root/}"
    # mkdir -p "$(dirname "$target")"
    echo ln -nfs "$link" "$target"
    # ln -nfs "$link" "$target"
done
