# Source shared environment variables
if test -f ~/dotfiles/personal/env
    for line in (cat ~/dotfiles/personal/env | grep "^export ")
        set -l kv (string split -m 1 "=" (string sub -s 8 $line))
        set -gx $kv[1] (string trim -c "'" -c '"' $kv[2])
    end
end

# Paths
fish_add_path ~/dotfiles/personal/bin
fish_add_path ~/.cargo/bin
fish_add_path ~/.local/bin
fish_add_path /google/bin/releases/editor-devtools
