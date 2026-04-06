#!/usr/bin/env fish
# --- RKJ Tide Theme Applicator ---
# Programmatically sets Tide universal variables.

echo "🛡️ Applying Tide Visual Theme..."

set -U tide_left_prompt_items os pwd git newline character
set -U tide_right_prompt_items status cmd_duration context jobs direnv node python rustc java php pulumi ruby go gcloud kubectl distrobox toolbox terraform aws nix_shell crystal elixir zig time

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

echo "✓ Theme applied. Restart your shell to see changes."
