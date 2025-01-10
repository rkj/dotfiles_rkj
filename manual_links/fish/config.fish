if status is-interactive
and not set -q TMUX
  exec tmux new-session -A -s fish
end
if status is-interactive
    # Commands to run in interactive sessions can go here
end
