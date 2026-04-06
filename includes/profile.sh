[[ -e /etc/profile ]] && source /etc/profile

export EDITOR=hx
export LESS="FRX"
if [[ ! ":$PATH:" == *"$DOTFILES/bin"* ]]; then
  export PATH=$DOTFILES/bin:$PATH
fi

# require 'sox'
alias engage='play -n -c1 synth whitenoise band -n 100 20 band -n 50 20 gain +25  fade h 1 864000 1'

open() {
  xdg-open "$@" >/dev/null
}
o() {
  open "$@"
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

swarm_exec() {
  local service_name="$1"
  shift
  local exec_command="${@:-/bin/sh}"
  local node=$(docker service ps -f "desired-state=running" --format "{{.Node}}" "$service_name" | head -n1)
  local container_id=$(ssh "$node" "docker ps -q -f name=$service_name")
  ssh -t "$node" "docker exec -it $container_id $exec_command"
}

swarm_ls() {
  docker service ls -q | xargs -I {} docker service ps --format '{{.Node}}\t{{.Name}}' {} --filter "desired-state=running" | sort
}

source <(cat ~/.profiles/*.sh)

