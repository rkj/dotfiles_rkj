# Standing Orders for Autonomous Agents

This document defines the protocols for managing the rkj dotfiles environment.

## 🛠️ Tool Management
All CLI tools and system packages MUST be managed via the `provision` script (`$DOTFILES/bin/provision`).

- **Adding a Tool:** Update the `TOOLS` list in the `provision` script. 
- **Renaming:** Use the `REMAP` logic for tools that have different names across package managers (e.g., `fd` vs `fd-find`).
- **Visual Theme:** Prompt and shell aesthetics are managed by `$DOTFILES/bin/apply-tide-theme.fish`. This script is called automatically by `provision`.
- **Package name remapping:** Some tools have different package/binary names across distros. Update the `PKG_APT`, `BIN_APT`, `PKG_DNF`, `BIN_DNF` tables in `provision` when adding tools with name differences (e.g., `fd` → `fd-find`/`fdfind` on Debian, `bat` → `batcat` on Debian).
- **System Preference:** 
    - **Bazzite (Fedora Atomic):** Immutable OS — `dnf` is NOT available on the host. `brew` is the primary package manager. `rpm-ostree` can layer packages but requires a reboot; avoid unless necessary. `provision` will offer to install brew if missing.
    - **Debian/Ubuntu:** `apt` for core tools, `brew` for modern CLI tools not in apt repos (helix, yazi).
    - **Fedora (non-atomic):** `dnf` for core tools, `brew` as fallback.

## 🚀 Environment Awareness
- **At Work:** Do not attempt to install unauthorized external AI tools (e.g., `claude-code`).
- **Pathing:** All custom scripts go to `$DOTFILES/bin/`. All environment variables go to `$DOTFILES/env`.

## 🧪 Verification
After updating any configuration or adding a tool, verify:
1. The tool is in the `$PATH`.
2. The `fish` configuration remains valid.
