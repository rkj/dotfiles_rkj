# Fish Prompt Customization

This document explains how the customized Fish prompt works and how it is configured.

## Overview

The prompt uses the Tide theme, customized to display repository information and status in a split-block format. It supports Git and JJ (Jujutsu) repositories.

## How It Works

The prompt splits the version control system (VCS) information into two distinct blocks:

1.  **Repository Block (`vcs_dir`)**:
    *   Displays the repository root path or CitC client name.
    *   Displays an icon indicating the VCS type ( for Git, 🥋 for JJ).
    *   Changes background color based on status:
        *   **Green**: Clean.
        *   **Yellow**: Working copy changes (dirty).
        *   **Red**: Conflicts.
    *   Uses **Black text** on Yellow background for better contrast.

2.  **Path Block (`vcs_path`)**:
    *   Displays the subpath inside the repository.
    *   Uses a folder icon ().
    *   Maintains a steady Blue background.

## Configuration

The customization consists of the following files:

*   `config/fish/functions/_tide_item_vcs_dir.fish`: Calculates the repository root, status, and sets colors.
*   `config/fish/functions/_tide_item_vcs_path.fish`: Displays the subpath exported by `vcs_dir`.
*   `scripts/apply-tide-theme.fish`: Registers these items in `tide_left_prompt_items` and sets default colors.

To apply changes after modifying these files, run:
```fish
scripts/apply-tide-theme.fish
```

For active panes to pick up the changes, run:
```fish
tide reload
```

NOTE: The `vcs_path` file might be ignored by `.gitignore`. Use `git add -f` if you need to commit it again.
