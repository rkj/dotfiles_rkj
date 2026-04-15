# Fish Prompt Customization

This document explains how the customized Fish prompt works and how it is configured.

## Overview

The prompt uses the Tide theme, customized to display repository information and status in a split-block format. It supports Git, JJ (Jujutsu), and Hg repositories. JJ takes precedence over Git in colocated repos.

## How It Works

The prompt splits the version control system (VCS) information into two distinct blocks:

1.  **Repository Block (`vcs_dir`)**:
    *   Displays the repository root path.
    *   Displays an icon indicating the VCS type ( for Git, 🥋 for JJ, ☿ for Hg).
    *   Shows status counters: upstream arrows (⇣⇡), stash (*), conflicts (~), staged (+), dirty (!), untracked (?).
    *   Does NOT show branch name (user always uses main).
    *   Changes background color based on status:
        *   **Green**: Clean.
        *   **Yellow**: Working copy changes (dirty/staged/untracked).
        *   **Red**: Conflicts.

2.  **Path Block (`vcs_path`)**:
    *   Displays the subpath inside the repository (only when not at repo root).
    *   Uses a folder icon ().
    *   Maintains a steady Blue background (same as Tide's default pwd).

Outside any repo, `vcs_dir` falls back to standard pwd-style display.

## Configuration

*   `config/fish/functions/_tide_item_vcs_dir.fish`: Detects VCS, calculates status, and renders the repo block.
*   `config/fish/functions/_tide_item_vcs_path.fish`: Renders the subpath block.
*   `scripts/apply-tide-theme.fish`: Restores Tide config from snapshot and applies customizations.
*   `scripts/save-tide-config.fish`: Snapshots all Tide universal variables after `tide configure`.
*   `scripts/tide-config.fish`: Auto-generated snapshot (committed to repo).
*   `config/fish/fish_plugins`: Fisher plugin list (fisher + tide).

## Workflow

After running `tide configure` to pick a base style:

```fish
# Snapshot Tide's universal variables
fish scripts/save-tide-config.fish

# Apply snapshot + customizations (vcs_dir/vcs_path items, colors)
fish scripts/apply-tide-theme.fish
```

On a fresh machine, `./scripts/init.sh` → `bin/provision` handles everything automatically.

For active panes to pick up function changes:
```fish
source ~/.config/fish/functions/_tide_item_vcs_dir.fish
source ~/.config/fish/functions/_tide_item_vcs_path.fish
```

## .gitignore Notes

Tide's internal functions are gitignored via `config/fish/functions/_tide*`, but custom VCS items are excluded from that pattern via `!config/fish/functions/_tide_item_vcs_*`.
