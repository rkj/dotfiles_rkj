#!/usr/bin/env fish
# Apply the Tide theme and custom prompt items.
#
# Uses `tide configure --auto` so there's no snapshot file to maintain.
# Re-run this script whenever you want to reset to the canonical theme.

echo "Applying Dracula color theme..."
fish_config theme choose Dracula

echo "Applying Tide config..."
tide configure --auto \
    --style=Rainbow \
    --prompt_colors='True color' \
    --show_time='24-hour format' \
    --rainbow_prompt_separators=Angled \
    --powerline_prompt_heads=Round \
    --powerline_prompt_tails=Flat \
    --powerline_prompt_style='Two lines, character' \
    --prompt_connection=Dotted \
    --powerline_right_prompt_frame=No \
    --prompt_connection_andor_frame_color=Darkest \
    --prompt_spacing=Sparse \
    --icons='Many icons' \
    --transient=No

# --- Customizations on top of the base Tide config ---

# Replace pwd+git with our custom vcs_dir + vcs_path items
set -U tide_left_prompt_items os context vcs_dir vcs_path newline character

# vcs_dir foreground must be unset — _tide_print_item would otherwise override
# the inline set_color calls that color the VCS text.
set -eU tide_vcs_dir_color

# vcs_path uses the same colors as pwd
set -U tide_vcs_path_bg_color $tide_pwd_bg_color
set -U tide_vcs_path_color $tide_pwd_color_dirs

# Conditionally filter right prompt items for work environments
if test "$DOTFILES_IS_WORK" = true
    set -l filtered
    for item in $tide_right_prompt_items
        if not contains -- $item ruby gcloud
            set -a filtered $item
        end
    end
    set -U tide_right_prompt_items $filtered
end

# Update _tide_left/right_items directly — tide reload calls fish_prompt.fish
# which exits early in non-interactive subprocesses, so _tide_remove_unusable_items
# would never run and these cached vars would stay stale.
_tide_remove_unusable_items

tide reload

# Patch fish_prompt.fish to fix width calculation for custom items
set -l prompt_file ~/.config/fish/functions/fish_prompt.fish
if test -f $prompt_file
    if test (uname) = "Darwin"
        sed -i '' 's/-\\\$_tide_pwd_len/-$column_offset/g' $prompt_file
    else
        sed -i 's/-\\\$_tide_pwd_len/-$column_offset/g' $prompt_file
    end
end

echo "✓ Theme applied."
