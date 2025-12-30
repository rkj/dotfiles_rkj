#!/bin/zsh
# It's ok to call this script multiple times, it will update all the links
# to the newest version and create any new stubs.

# Find proper path
root="$(cd "$(dirname "$0")" && pwd)"
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
for link in links/*; do
  file=`basename $link`
  ln -nfs $root/$link $HOME/.$file
done;
ln -nfs $root/manual_links/fish $HOME/.config/fish

[ ! -e $HOME/.xmonad/xmonad.hs ] && mkdir -p $HOME/.xmonad && ln -nfs $root/xmonad.hs $HOME/.xmonad/xmonad.hs
mkdir -p links/vim/tmp links/vim/backup links/vim/cache $HOME/.profiles/
touch $HOME/.profiles/empty.sh

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

