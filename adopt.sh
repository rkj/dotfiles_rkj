#!/bin/zsh

root=~/misc/dotfiles_corp/links
filename=$(basename "$1")
echo $filename
# Verify if the file exists and starts with a dot
if [[ ! -f "$HOME/$filename" || ! "$filename" =~ ^\. ]]; then
    echo "Error: File not found or does not start with a dot."
    exit 1
fi
if [[ -L "$HOME/$filename" ]]; then
  echo "Error: '$filename' is a symbolic link. Aborting."
  exit 1
fi

# Remove the leading dot
link="${filename:1}" 

echo mv $HOME/.$link $root/$link
mv $HOME/.$link $root/$link
echo ln -nfs $root/$link $HOME/.$link
ln -nfs $root/$link $HOME/.$link

