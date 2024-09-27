[[ -e /etc/profile ]] && source /etc/profile

[ -n "$DISPLAY" -a "$TERM" = "xterm" ] && export TERM=xterm-256color
[ -n "$DISPLAY" -a -n "$TMUX" ] && export TERM=screen-256color
[ -z "$DISPLAY" ] && export DISPLAY=:0

export EDITOR=vim
export JAVA_OPTS="-Dfile.encoding=utf8"
export JRUBY_OPTS="--1.9"
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_COLLATE=pl_PL.UTF-8
export LESS="FRX"
export RUBYOPT=rubygems
if [[ ! ":$PATH:" == *"$DOTFILES/bin"* ]]; then
  export PATH=$DOTFILES/bin:$PATH
fi

alias 7z='7z -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on'
alias a="ack --color"
alias bc='bc -l ~/.bc'
alias be="bundle exec "
alias cp='cp -i'
alias hl='ack --color --passthru --flush'
alias ka="killall -vm "
alias lzma='lzma -vk'
alias mv='mv -i'
alias pg="ps aux | grep "
alias port='sudo port'
alias sp="source ~/.profile"
alias sudo='sudo -E'
alias sz="source ~/.zshrc"
alias td='python ~/misc/dotfiles/t/t.py --task-dir ~/Dropbox/tasks --list tasks'
alias v='l --color=none'
alias grep="grep --line-number --color"

# tmux buffer to clipboard
alias tbc='tmux save-buffer - | xclip -i'

# require 'sox'
alias engage='play -n -c1 synth whitenoise band -n 100 20 band -n 50 20 gain +25  fade h 1 864000 1'

kinesiskb() {
  # setxkbmap pl -model apple \
  setxkbmap -model pc105 \
    -layout pl \
    -variant basic \
    -option '' \
    -option ctrl:nocaps \
    -option altwin:swap_alt_win \
  && xmodmap $DOTFILES/links/Xmodmap-kinesis
}

open() {
  xdg-open "$@" >/dev/null
}
o() {
  open "$@"
}

# mercurial diff viewer
hdv() {
  hg diff "$@" | vim -R -
}
# mercurial gvim diff viewer
hdg() {
  hg diff "$@" | gvim -R -
}

# multiple hg
mhg() {
  local mhgrepo
  local dir=`pwd`/.hg
  for d in `find . -mindepth 2 -depth -name .hg | sort` $([[ -e $dir ]] && echo $dir); do
    mhgrepo=`dirname "$d"`
    echo "$fg[red]$mhgrepo$fg[default]"
    (cd $mhgrepo && hg "$@")
  done
}

# multiple git
mgit() {
  local mgitrepo
  local dir=`pwd`/.git
  for d in `find . -mindepth 2 -depth -name .git | sort` $([[ -e $dir ]] && echo $dir); do
    mgitrepo=`dirname "$d"`
    echo "$fg[red]$mgitrepo$fg[default]"
    (cd $mgitrepo && git "$@")
  done
}

# Chuck Norris kills da process
chuck() {
  ps aux | grep $1 | tr -s '\t' ' ' | cut -f2 -d' ' | xargs kill $2
}

# Fast Find
ff() {
  find . -type 'f' -iname "*$@*"
}

fvim() {
  PS3="File to edit in VIM: "
  filenames=`ff "$@"`
  if (( ${#filenames} == 0 )); then echo No files found; return; fi
  count=`echo "$filenames" | wc -l`
  if (( $count == 1 )); then vim $filenames; return; fi
  select FILENAME in $filenames; do
    vim $FILENAME;
    return;
  done
}

trash() {
  for file in "$@"; do # Cycle through each argument for deletion
    if [ -e "$file" ]; then
      if [ ! -d ~/.Trash/"${file:t}" ]; then # Target exists and can be moved to Trash safely
        mv "$file" ~/.Trash
      else # Target exists and conflicts with target in Trash
        i=1
        while [ -e ~/.Trash/"${file:t}.$i" ]; do
          i=$(($i + 1)) # Increment target name until there is no longer a conflict
        done
        mv "$file" ~/.Trash/"${file:t}.$i" # Move to the Trash with non-conflicting name
      fi
    else # Target doesn't exist, return error
      echo "trash: $file: No such file or directory";
    fi
  done
}

mkcd() {
  mkdir -p "$@" && cd "$@"
}

cdtoday() {
  mkcd "$(date +%Y-%m-%d)$@"
}

# History of todays commands.
# Optionally may pass hour to match, e.g. today 11:
history_from() {
  fc -l -i -D -n 1 | sort | awk -F '  ' '{if($1>"'"$@"'") print}'
}

today() {
  history_from "$(date +%Y-%m-%d) $@"
}

cleanshell() {
  local tmpdir=$(mktemp -d)
  local tmprc=$(mktemp)
  cat >> "$tmprc" << EOF
PS1='\\$ '
cd "$tmpdir"
EOF
  env - HOME="$HOME" TERM="$TERM" bash --rcfile "$tmprc"
  rm -rf "$tmpdir" "$tmprc"
}

resudo() {
  sudo $(fc -ln -1)
}

# swap current window with the target window number
swaptmux() {
  tmux swap-window -s $(tmux display-message -p '#{window_index}') -t "$@"
}

# prints the processes having the most files opened
filecounts() {
  (for i in /proc/[0-9]*; do echo $(sudo ls -l $i/fd 2>/dev/null | wc -l ) $i $(cat $i/comm 2>/dev/null); done) | sort -nr | head
}

duu() {
  du -xh -d 1 . 2>/dev/null | sort -h
}

nectarine() {
  mpv --player-operation-mode=pseudo-gui -- http://necta-v6.burn.net:8000/nectarine
}

print_colors() {
  for i in {0..255}; do print -Pn "%K{$i}  %k%F{$i}${(l:3::0:)i}%f " ${${(M)$((i%6)):#3}:+$'\n'}; done
}

ping_with_stats() {
  ping "$@" | awk '{ sent=NR-1; received+=/^.*(time=.+ ms).*$/; loss=0; } { if (sent>0) loss=100-((received/sent)*100) } { print $0; printf "sent:%d received:%d loss:%d%%\n", sent, received, loss; }'
}
# fix for tmux/screen attaching and lossing ssh agent
if [ ! -z "$SSH_AUTH_SOCK" -a "$SSH_AUTH_SOCK" != "$HOME/.ssh/agent_sock" ] ; then
    unlink "$HOME/.ssh/agent_sock" 2>/dev/null
    ln -s "$SSH_AUTH_SOCK" "$HOME/.ssh/agent_sock"
    export SSH_AUTH_SOCK="$HOME/.ssh/agent_sock"
fi

countdown() {
  start="$(( $(date '+%s') + $1))"
  while [ $start -ge $(date +%s) ]; do
    time="$(( $start - $(date +%s) ))"
    printf '%s\r' "$(date -u -d "@$time" +%H:%M:%S)"
    sleep 0.1
  done
}

source <(cat ~/.profiles/*.sh)

