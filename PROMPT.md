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
    *   For JJ repos: ⇡ shows outgoing commits (`trunk()..@-`). Stash is git-only.
    *   Does NOT show branch name (user always uses main).
    *   Changes background color based on status (uses Tide's `tide_git_bg_color*` vars):
        *   **Green** (`4E9A06`): Clean.
        *   **Yellow** (`C4A000`): Working copy changes (dirty/staged/untracked).
        *   **Red** (`CC0000`): Conflicts.

2.  **Path Block (`vcs_path`)**:
    *   Displays the subpath inside the repository (only when not at repo root).
    *   Uses a folder icon ().
    *   Maintains a steady Blue background (`3465A4`, same as Tide's default pwd).

Outside any repo, `vcs_dir` falls back to pwd-style display (blue background, light text).

## Color Architecture

The `vcs_dir` item follows the same color pattern as Tide's built-in `_tide_item_git`:

*   **`tide_vcs_dir_color` is empty** (set to `''` in `apply-tide-theme.fish`). This means `_tide_print_item` does not set a foreground color — all text colors are controlled by inline `set_color` calls within the command substitution output. This matches how `tide_git_color` is empty in Tide.
*   **`tide_vcs_dir_bg_color`** defaults to `4E9A06` (green). The function mutates it per-render via `set -g` for unstable/urgent states. No save/restore is needed because the prompt renders in a subprocess that resets globals each time.
*   **Repo text**: `set_color $tide_git_color_branch` (black) for icon and path, then `set_color $tide_git_color_*` (black) for each status element — matching Tide's built-in git item.
*   **Non-repo text**: `set_color $tide_pwd_color_dirs` for the path, with bg overridden to `$tide_pwd_bg_color`.

## Configuration

*   `config/fish/functions/_tide_item_vcs_dir.fish`: Detects VCS, calculates status, and renders the repo block.
*   `config/fish/functions/_tide_item_vcs_path.fish`: Renders the subpath block.
*   `scripts/apply-tide-theme.fish`: Restores Tide config from snapshot and applies customizations.
*   `scripts/save-tide-config.fish`: Snapshots all Tide universal variables after `tide configure`.
*   `scripts/tide-config.fish`: Auto-generated snapshot (committed to repo).
*   `config/fish/fish_plugins`: Fisher plugin list (fisher + tide).

## Design Principles

- **Portability**: This configuration is designed to be easily cloned and deployed on any machine via `./scripts/init.sh`.
- **Self-Contained**: It should not contain any proprietary or environment-specific hardcoded values.
- **Extensibility**: Theme settings and variables are designed to be overrideable by external scripts if needed.

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

NOTE: The `vcs_path` file might be ignored by `.gitignore`. Use `git add -f` if you need to commit it again.

### JJ Prompt Optimization Constraint

> [!IMPORTANT]
> Any `jj` commands executed by the prompt (e.g., in `_tide_item_vcs_dir.fish`) MUST include the `--ignore-working-copy` flag.
> This prevents `jj` from creating unwanted working copy snapshots in the background, which can significantly slow down prompt rendering.
> Example: `jj --ignore-working-copy status --no-pager`
