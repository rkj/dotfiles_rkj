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

set -U tide_left_prompt_items os context pwd git newline character
set -U tide_right_prompt_items $right_items

set -U tide_prompt_transient_enabled false

# Context
set -U tide_context_always_display true

# Colors & Icons
set -U tide_os_bg_color D4D4D4
set -U tide_os_color C70036
set -U tide_os_icon \uf306
set -U tide_pwd_bg_color 3465A4
set -U tide_pwd_color_anchors E4E4E4
set -U tide_pwd_color_dirs E4E4E4
set -U tide_pwd_icon \uf07c
set -U tide_git_bg_color 4E9A06
set -U tide_git_icon \uf1d3
set -U tide_character_icon \u276f
set -U tide_character_color 5FD700

# Prompt Style
set -U tide_left_prompt_frame_enabled false
set -U tide_right_prompt_frame_enabled false
set -U tide_prompt_add_newline_before true
set -U tide_prompt_pad_items true
set -U tide_left_prompt_suffix \ue0b4
set -U tide_right_prompt_prefix \ue0b6

if command -v tide >/dev/null
    tide reload
end

echo "✓ Theme applied."
