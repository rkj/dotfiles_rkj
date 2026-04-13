# Standing Orders for Autonomous Agents

This document defines the protocols for managing the rkj personal dotfiles environment.

## 🛠️ Tool Management
All CLI tools and system packages MUST be managed via the `provision` script (`bin/provision`).

- **Adding a Tool:** Update the `TOOLS` list in the `provision` script. 
- **Fish Plugins:** All Fish plugins MUST be managed by `fisher` within the `provision` script.
- **Visual Theme:** Prompt and shell aesthetics are managed by `bin/apply-tide-theme.fish`. This script is called automatically by `provision`.

## 🚀 Environment Awareness
- **Pathing:** All custom scripts go to `bin/`. All environment variables go to `env/`.

## 🧪 Verification
After updating any configuration or adding a tool, verify:
1. The tool is in the `$PATH`.
2. The `fish` configuration remains valid.
