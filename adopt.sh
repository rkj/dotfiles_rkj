#!/bin/zsh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
root="$SCRIPT_DIR/links"

# Verify if the file exists and starts with a dot
if [[ ! -f "$1" || ! "$(basename "$1")" =~ ^. ]]; then
    echo "Error: File not found or does not start with a dot."
    exit 1
fi

filename="$1"
link="${filename#$HOME/}"
link="${link#.}"

if [[ -L "$filename" ]]; then
    echo "Error: '$filename' is a symbolic link. Aborting."
    exit 1
fi

# Create the directory structure in the repository if necessary
echo mkdir -p "$root/$(dirname "$link")"
mkdir -p "$root/$(dirname "$link")"

# Move the file to the repository and create the symlink
echo mv "$filename" "$root/$link"
mv "$filename" "$root/$link"

echo ln -nfs "$root/$link" "$filename"
ln -nfs "$root/$link" "$filename"
