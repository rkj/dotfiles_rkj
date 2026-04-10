# Bootstrap DOTFILES from this file's symlink path if not already set.
# This file lives at $DOTFILES/config/fish/conf.d/env.fish, symlinked
# from ~/.config/fish/conf.d/env.fish, so we can resolve it.
if test -z "$DOTFILES"
    set -l self (status filename)
    set -l resolved (realpath "$self" 2>/dev/null)
    if test -n "$resolved"
        # Strip /config/fish/conf.d/env.fish to get DOTFILES root
        set -gx DOTFILES (string replace '/config/fish/conf.d/env.fish' '' "$resolved")
    end
end

# Source shared environment variables
if test -n "$DOTFILES" -a -f "$DOTFILES/env"
    for line in (cat "$DOTFILES/env" | grep "^export ")
        set -l kv (string split -m 1 "=" (string sub -s 8 $line))
        set -gx $kv[1] (string trim -c "'" -c '"' $kv[2])
    end
end

# Paths
test -n "$DOTFILES"; and fish_add_path "$DOTFILES/bin"
fish_add_path ~/.cargo/bin
fish_add_path ~/.local/bin
test -d /google/bin/releases/editor-devtools; and fish_add_path /google/bin/releases/editor-devtools
