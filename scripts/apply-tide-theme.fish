#!/usr/bin/env fish
# Apply the Tide theme from the committed snapshot, then layer on customizations.
#
# Workflow:
#   1. Run `tide configure` to pick your base style.
#   2. Run `fish scripts/save-tide-config.fish` to snapshot.
#   3. This script restores that snapshot + applies custom prompt items.

set -l script_dir (status dirname)
set -l config "$script_dir/tide-config.fish"

if not test -f $config
    echo "Error: $config not found. Run save-tide-config.fish first." >&2
    return 1
end

echo "Applying Tide config..."
source $config

# --- Customizations on top of the base Tide config ---

# Replace pwd+git with our custom vcs_dir + vcs_path items
set -U tide_left_prompt_items os context vcs_dir vcs_path newline character

# vcs_dir color must be EMPTY — like Tide's tide_git_color — so _tide_print_item
# doesn't set a foreground; all text colors come from inline set_color calls.
set -U tide_vcs_dir_color ''

# vcs_path uses the same colors as pwd (steady blue background, light text)
set -U tide_vcs_path_bg_color $tide_pwd_bg_color
set -U tide_vcs_path_color $tide_pwd_color_dirs

# Conditionally filter right prompt items for work environments
if test "$DOTFILES_IS_WORK" = true
    # Remove ruby and gcloud for work environments
    set -l filtered
    for item in $tide_right_prompt_items
        if not contains -- $item ruby gcloud
            set -a filtered $item
        end
    end
    set -U tide_right_prompt_items $filtered
end

# Re-run Tide's item filter to update _tide_left_items / _tide_right_items
if functions -q _tide_remove_unusable_items
    _tide_remove_unusable_items
end

if command -v tide >/dev/null
    tide reload
end

echo "✓ Theme applied."
