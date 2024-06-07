#!/bin/zsh

# find proper path
root=`dirname "$PWD"/"$0"`/../
cd $root
root=`pwd`

# make stubs
for stub in stubs/*; do
  file=`basename $stub`
  if [ ! -e $HOME/.$file ]; then
    cp $root/$stub $HOME/.$file
  else
    echo File $HOME/.$file already exists
  fi
done;

# make symlinks
for link in links/**/* vim; do
  file=`basename $link`
  ln -nfs $root/$link $HOME/.$file
done;
[ ! -e $HOME/.xmonad/xmonad.hs ] && mkdir -p $HOME/.xmonad && ln -nfs $root/xmonad.hs $HOME/.xmonad/xmonad.hs
mkdir vim/tmp

# prepare profile
if [ ! -e $HOME/.profile ]; then
  echo "export DOTFILES=$root"                 >  $HOME/.profile
  echo 'source $DOTFILES/includes/profile.sh'  >> $HOME/.profile
else
  echo "Remember to add 'export DOTFILES="$root"\nsource \$DOTFILES/includes/profile.sh' to your .profile if you haven't already."
fi

