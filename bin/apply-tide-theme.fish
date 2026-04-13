#!/usr/bin/env fish
# --- RKJ Tide Theme Applicator ---
# Programmatically sets Tide universal variables.

echo "🛡️ Applying Tide Visual Theme..."

set -l right_items status cmd_duration jobs direnv node python rustc java php pulumi go kubectl distrobox toolbox nix_shell crystal elixir zig time

# Conditionally add personal-only items
if test "$DOTFILES_IS_WORK" != true
    # Add ruby and gcloud for personal environments
    set -a right_items ruby gcloud
end

# Items
set -U tide_left_prompt_items os context pwd git newline character
set -U tide_right_prompt_items $right_items

# General Style
set -U tide_prompt_add_newline_before true
set -U tide_prompt_pad_items true
set -U tide_prompt_transient_enabled false
set -U tide_prompt_color_frame_and_connection 444444
set -U tide_prompt_color_separator_same_color 949494
set -U tide_prompt_icon_connection ·
set -U tide_prompt_min_cols 34

# Rounded Separators
set -U tide_left_prompt_prefix ""
set -U tide_left_prompt_suffix 
set -U tide_left_prompt_separator_diff_color 
set -U tide_left_prompt_separator_same_color 

set -U tide_right_prompt_prefix 
set -U tide_right_prompt_suffix ""
set -U tide_right_prompt_separator_diff_color 
set -U tide_right_prompt_separator_same_color 

# Frame
set -U tide_left_prompt_frame_enabled false
set -U tide_right_prompt_frame_enabled false

# Context
set -U tide_context_always_display true
set -U tide_context_bg_color 444444
set -U tide_context_color_default D7AF87
set -U tide_context_color_root D7AF00
set -U tide_context_color_ssh D7AF87
set -U tide_context_hostname_parts 1

# Colors & Icons
set -U tide_os_bg_color D4D4D4
set -U tide_os_color C70036
set -U tide_os_icon 
set -U tide_pwd_bg_color 3465A4
set -U tide_pwd_color_anchors E4E4E4
set -U tide_pwd_color_dirs E4E4E4
set -U tide_pwd_color_truncated_dirs BCBCBC
set -U tide_pwd_icon 
set -U tide_pwd_icon_home 
set -U tide_pwd_icon_unwritable 
set -U tide_git_bg_color 4E9A06
set -U tide_git_bg_color_unstable C4A000
set -U tide_git_bg_color_urgent CC0000
set -U tide_git_icon 
set -U tide_character_icon ❯
set -U tide_character_color 5FD700
set -U tide_character_color_failure FF0000

# Status Icons
set -U tide_status_icon ✔
set -U tide_status_icon_failure ✘
set -U tide_status_bg_color 2E3436
set -U tide_status_bg_color_failure CC0000
set -U tide_status_color 4E9A06
set -U tide_status_color_failure FFFF00

if command -v tide >/dev/null
    tide reload
end

echo "✓ Theme applied."
