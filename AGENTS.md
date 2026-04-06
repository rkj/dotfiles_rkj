# Standing Orders for Autonomous Agents

This document defines the protocols for managing the rkj dotfiles environment.

## 🛠️ Tool Management
All CLI tools and system packages MUST be managed via the `provision` script (`~/dotfiles/personal/bin/provision`).

- **Adding a Tool:** Update the `TOOLS` list in the `provision` script. 
- **Renaming:** Use the `REMAP` logic for tools that have different names across package managers (e.g., `fd` vs `fd-find`).
- **Visual Theme:** Prompt and shell aesthetics are managed by `~/dotfiles/personal/bin/apply-tide-theme.fish`. This script is called automatically by `provision`.
- **System Preference:** 
    - **Bazzite:** Prefer `brew` or user-space managers. Avoid `rpm-ostree` layering.
    - **Goobuntu/Ubuntu:** Prefer `apt` for core tools, `brew` for modern CLI replacements.

## 🚀 Environment Awareness
- **At Work:** Do not attempt to install unauthorized external AI tools (e.g., `claude-code`).
- **Pathing:** All custom scripts go to `~/dotfiles/personal/bin/`. All environment variables go to `~/dotfiles/personal/env`.

## 🧪 Verification
After updating any configuration or adding a tool, verify:
1. The tool is in the `$PATH`.
2. The `fish` configuration remains valid.
