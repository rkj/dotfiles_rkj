#!/bin/zsh
# It's ok to call this script multiple times, it will update all the links
# to the newest version and create any new stubs.

# Find proper path
root="$(cd "$(dirname "$0")" && pwd)"
cd $root
root=`pwd`

# Make stub files.
for stub in stubs/*; do
  file=`basename $stub`
  if [ ! -e $HOME/.$file ]; then
    cp $root/$stub $HOME/.$file
  else
    echo File $HOME/.$file already exists
  fi
done;

# Update symlinks for dotfiles (links/ -> ~/.<name>)
for link in links/*; do
  file=`basename $link`
  ln -nfs $root/$link $HOME/.$file
done;

# Update ~/.config symlinks (config/<name> -> ~/.config/<name>)
mkdir -p $HOME/.config
for cfg in $root/config/*/; do
  name=$(basename "$cfg")
  target="$HOME/.config/$name"
  if [ -d "$target" ] && [ ! -L "$target" ]; then
    echo "Warning: $target is a directory, backing up to ${target}.bak"
    mv "$target" "${target}.bak"
  fi
  ln -nfs "$cfg" "$target"
done

[ ! -e $HOME/.xmonad/xmonad.hs ] && mkdir -p $HOME/.xmonad && ln -nfs $root/xmonad.hs $HOME/.xmonad/xmonad.hs
mkdir -p $HOME/.profiles/
touch $HOME/.profiles/empty.sh

# Ensure DOTFILES is set in .profile.
if ! grep -q "^export DOTFILES=" $HOME/.profile 2>/dev/null; then
  echo ""                                        >> $HOME/.profile
  echo "export DOTFILES=$root"                   >> $HOME/.profile
  echo '[ -f $DOTFILES/includes/profile.sh ] && source $DOTFILES/includes/profile.sh'  >> $HOME/.profile
  echo "Added DOTFILES to ~/.profile"
else
  # Update existing DOTFILES line if path changed.
  sed -i "s|^export DOTFILES=.*|export DOTFILES=$root|" $HOME/.profile
  echo "DOTFILES already in ~/.profile (updated path)"
fi

# Prepare bash_profile if needed.
if [ ! -e $HOME/.bash_profile ]; then
  cp "$root/stubs/bash_profile" "$HOME/.bash_profile"
else
  cat <<EOQ
Remember to ensure your .bash_profile sources:

~/.profile
~/.bashrc

in that order, otherwise DOTFILES may be unset in bash sessions.
EOQ
fi

# Prepare bashrc if needed.
if [ ! -e $HOME/.bashrc ]; then
  echo 'source $DOTFILES/includes/bashrc'  >> $HOME/.bashrc
else
  cat <<EOQ
Remember to add:

source \$DOTFILES/includes/bashrc

to your .bashrc if you haven't already.
EOQ
fi

# Prepare tmux.conf if needed.
if [ ! -e $HOME/.tmux.conf ]; then
  cp "$root/stubs/tmux.conf" "$HOME/.tmux.conf"
else
  cat <<EOQ
Remember to ensure your .tmux.conf sources:

run-shell '[ -n "\$DOTFILES" ] && [ -f "\$DOTFILES/includes/tmux.conf" ] && tmux source-file "\$DOTFILES/includes/tmux.conf"'

tmux does not expand shell variables in config files directly, so DOTFILES must be
available in the environment when the tmux server starts.
EOQ
fi
