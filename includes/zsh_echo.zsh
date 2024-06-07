
rkj_debug "Executing DOTFILES/includes/zshrc-drives"
if hash timeout 2>/dev/null; then
  for mnt in `timeout 1 df | grep /dev/ | awk '{print $6}'`; do
    echo_free $mnt;
  done
else
  echo "Please install coreutils package to get timeout command"
fi
echo -ne "Today is "; date
echo -ne "Uptime: "; uptime
echo
command fortune 2>/dev/null || echo "Missing fortune"

