# Fish Prompt Customization

This document explains how the customized Fish prompt works and how it is configured.

## Overview

The prompt uses the Tide theme, customized to display repository information and status in a split-block format. It supports Git, JJ (Jujutsu), and Hg repositories. JJ takes precedence over Git in colocated repos.

## How It Works

The prompt splits the version control system (VCS) information into two distinct blocks:

1.  **Repository Block (`vcs_dir`)**:
    *   Displays the repository root path.
    *   Displays an icon indicating the VCS type ( for Git, 🥋 for JJ, ☿ for Hg).
    *   Shows status counters: upstream arrows (⇣⇡), stash (*), conflicts (~), staged (+), dirty (!), untracked (?).
    *   Does NOT show branch name.
    *   Changes background color based on status:
        *   **Green**: Clean.
        *   **Yellow**: Working copy changes.
        *   **Red**: Conflicts.
    *   **Home Directory Handling**: If the path evaluates to exactly `~`, it uses the `tide_pwd_icon_home` or fallback `` instead of the generic folder icon.

2.  **Path Block (`vcs_path`)**:
    *   Displays the subpath inside the repository (only when not at repo root).
    *   Uses a folder icon ().
    *   Maintains a steady Blue background.

Outside any repo, `vcs_dir` falls back to pwd-style display (blue background, light text).

## Technical Gotchas: Width Calculation in Two-Line Prompt

The prompt is configured as a two-line prompt, with filler dots connecting the left and right segments of the top line. This setup has a critical technical constraint regarding width calculations:

-   In `fish_prompt.fish` (a file generated on demand and not tracked), line 79 calculates the distance between sides:
    `math \$COLUMNS-(string length -V \"\$$prompt_var[1][1]\$$prompt_var[1][3]\")+$column_offset | read -lx dist_btwn_sides`
-   It adds a `$column_offset` (e.g., 5) to account for theme frame characters.
-   In the standard Tide setup, it then generates filler dots using `math max 0, \$dist_btwn_sides-\$_tide_pwd_len`. It subtracts the path length because default items use a placeholder `@PWD@` and Tide compensates for it later.
-   **The Problem**: Our custom items like `vcs_dir` print the actual path directly, so its length is *already counted* by `string length -V`. The subtraction of `_tide_pwd_len` caused a double-counting error, leaving a wide gap.
-   **The Solution**: We patched `fish_prompt.fish` in `scripts/apply-tide-theme.fish` to replace `-\$_tide_pwd_len` with `-$column_offset` on line 82. This cancels out the positive offset and produces the exact number of filler dots needed, avoiding over-counting and line overflow (which causes truncation).

## Configuration

*   `config/fish/functions/_tide_item_vcs_dir.fish`: Detects VCS, calculates status, and renders the repo block.
*   `config/fish/functions/_tide_item_vcs_path.fish`: Renders the subpath block.
*   `scripts/apply-tide-theme.fish`: Restores Tide config and applies customizations, including the width patch.

## Design Principles

-   **Portability**: The prompt should work on new environments after running `./scripts/init`.
-   **Self-Contained**: The shared repository does not contain environment-specific overrides.
-   **Patches for Portability**: If generated files like `fish_prompt.fish` need modifications, they should be patched by scripts run in `init.sh` instead of being committed.

### JJ Prompt Optimization Constraint

> [!IMPORTANT]
> Any `jj` commands executed by the prompt MUST include the `--ignore-working-copy` flag. This prevents `jj` from creating unwanted working copy snapshots in the background.
