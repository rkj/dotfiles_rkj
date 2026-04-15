function _tide_item_vcs_path
    # Detect repo root (same logic as vcs_dir — JJ takes precedence)
    set -l repo_root ""
    if set -l git_root (git rev-parse --show-toplevel 2>/dev/null)
        set repo_root $git_root
    else if type -q hg; and set -l hg_root (hg root 2>/dev/null)
        set repo_root $hg_root
    end

    if test -z "$repo_root"
        return
    end

    set -l subpath (string replace "$repo_root" '' $PWD | string trim -l -c /)
    if test -z "$subpath"
        return
    end

    _tide_print_item vcs_path "$tide_pwd_icon $subpath"
end
