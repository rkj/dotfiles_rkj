#!/bin/zsh
# It's ok to call this script multiple times, it will update all the links
# to the newest version and create any new stubs.

# Find proper path
root=`dirname "$PWD"/"$0"`/
cd $root
root=`pwd`

git submodule update --init --recursive

# Make stub files.
for stub in stubs/*; do
  file=`basename $stub`
  if [ ! -e $HOME/.$file ]; then
    cp $root/$stub $HOME/.$file
  else
    echo File $HOME/.$file already exists
  fi
done;

# Update symlinks.
for link in links/**/* vim; do
  file=`basename $link`
  ln -nfs $root/$link $HOME/.$file
done;
[ ! -e $HOME/.xmonad/xmonad.hs ] && mkdir -p $HOME/.xmonad && ln -nfs $root/xmonad.hs $HOME/.xmonad/xmonad.hs
mkdir -p vim/tmp vim/backup vim/cache

# Prepare profile if needed.
if [ ! -e $HOME/.profile ]; then
  echo "export DOTFILES=$root"                 >  $HOME/.profile
  echo 'source $DOTFILES/includes/profile.sh'  >> $HOME/.profile
else
  cat <<EOQ
Remember to add:

export DOTFILES="$root"
source \$DOTFILES/includes/profile.sh

to your .profile if you haven't already.
EOQ
fi

