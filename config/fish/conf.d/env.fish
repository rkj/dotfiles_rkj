if not contains -- no-query-term $fish_features
    set -Ua fish_features no-query-term
end

# Reset terminal mouse tracking and focus reporting modes after every command
# and before every prompt. When an SSH session or TUI app (zellij, ohmyagy,
# helix, vim, etc.) drops abruptly overnight, the terminal is otherwise left in
# mouse-motion reporting mode (?1003h/?1006h), causing mouse movement over the
# window to dump raw SGR control codes (^[[<35;...M).
function __fish_reset_mouse_tracking --on-event fish_postexec --on-event fish_prompt
    if status is-interactive; and isatty stdout
        printf '\e[?1000l\e[?1002l\e[?1003l\e[?1005l\e[?1006l\e[?1015l\e[?1016l\e[?1004l\e[?25h'
    end
end
__fish_reset_mouse_tracking

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

# Source shared environment variables from tracked and local overlays.
function source_dotfiles_env --argument-names file_path
    if test -f "$file_path"
        for line in (cat "$file_path" | grep "^export ")
            set -l kv (string split -m 1 "=" (string sub -s 8 $line))
            set -gx $kv[1] (string trim -c "'" -c '"' $kv[2])
        end
    end
end

if test -n "$DOTFILES"
    source_dotfiles_env "$DOTFILES/env"
    source_dotfiles_env "$DOTFILES/env.local"
end

# Paths
test -n "$DOTFILES"; and fish_add_path "$DOTFILES/bin"
fish_add_path ~/.cargo/bin
fish_add_path ~/.local/bin
