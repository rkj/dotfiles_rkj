function _tide_item_vcs_dir
    set -l home_regex (string escape --style=regex $HOME)

    # Detect VCS type and repo root — JJ takes precedence over plain git
    set -l vcs_type ""
    set -l repo_root ""

    if set -l git_root (git rev-parse --show-toplevel 2>/dev/null)
        if test -d "$git_root/.jj"
            set vcs_type jj
        else
            set vcs_type git
        end
        set repo_root $git_root
    else if type -q hg; and set -l hg_root (hg root 2>/dev/null)
        set vcs_type hg
        set repo_root $hg_root
    end

    if test -z "$vcs_type"
        # Outside any repo — use pwd colors (no save/restore needed, subprocess resets)
        set -g tide_vcs_dir_bg_color $tide_pwd_bg_color
        set -l display (string replace -r "^$home_regex" '~' $PWD)
        _tide_print_item vcs_dir (set_color $tide_pwd_color_dirs; echo -ns "$tide_pwd_icon $display")
        return
    end

    set -l repo_display (string replace -r "^$home_regex" '~' $repo_root)

    # VCS icon
    set -l icon
    switch $vcs_type
        case git
            set icon "$tide_git_icon "
        case jj
            set icon "🥋"
        case hg
            set icon "☿ "
    end

    # Gather status
    set -l behind 0
    set -l ahead 0
    set -l stash 0
    set -l conflicted 0
    set -l staged 0
    set -l dirty 0
    set -l untracked 0

    if test "$vcs_type" = git
        set -l stat (git --no-optional-locks status --porcelain 2>/dev/null)
        set conflicted (string match -r ^UU $stat | count)
        set staged (string match -r ^[ADMR] $stat | count)
        set dirty (string match -r ^.[ADMR] $stat | count)
        set untracked (string match -r '^\?\?' $stat | count)
        set stash (git stash list 2>/dev/null | count)
        if git rev-list --count --left-right @{upstream}...HEAD 2>/dev/null | read -d \t -l b a
            set behind $b
            set ahead $a
        end

        if test "$conflicted" -gt 0
            set -g tide_vcs_dir_bg_color $tide_git_bg_color_urgent
        else if test "$staged" -gt 0 -o "$dirty" -gt 0 -o "$untracked" -gt 0
            set -g tide_vcs_dir_bg_color $tide_git_bg_color_unstable
        end

    else if test "$vcs_type" = jj
        set -l jj_stat (jj --ignore-working-copy status --no-pager 2>/dev/null)
        set -l jj_changes (jj --ignore-working-copy diff --summary -r @ --no-pager 2>/dev/null)

        string match -q "*Conflict*" "$jj_stat"; and set conflicted 1
        set staged (string match -r '^A ' $jj_changes | count)
        set dirty (string match -r '^[MD] ' $jj_changes | count)

        if test "$conflicted" -gt 0
            set -g tide_vcs_dir_bg_color $tide_git_bg_color_urgent
        else if test (count $jj_changes) -gt 0
            set -g tide_vcs_dir_bg_color $tide_git_bg_color_unstable
        end

        set ahead (jj --ignore-working-copy log --no-graph -r 'trunk()..@-' -T '"\n"' --no-pager 2>/dev/null | count)
    end

    # Build colored status string — only show non-zero counters
    # Use black text like Tide's git item (tide_git_color_branch = 000000)
    _tide_print_item vcs_dir (set_color $tide_git_color_branch; echo -ns "$icon$repo_display"
        if test "$behind" -gt 0
            set_color $tide_git_color_upstream; echo -ns ' ⇣'$behind
        end
        if test "$ahead" -gt 0
            set_color $tide_git_color_upstream; echo -ns ' ⇡'$ahead
        end
        if test "$stash" -gt 0
            set_color $tide_git_color_stash; echo -ns ' *'$stash
        end
        if test "$conflicted" -gt 0
            set_color $tide_git_color_conflicted; echo -ns ' ~'$conflicted
        end
        if test "$staged" -gt 0
            set_color $tide_git_color_staged; echo -ns ' +'$staged
        end
        if test "$dirty" -gt 0
            set_color $tide_git_color_dirty; echo -ns ' !'$dirty
        end
        if test "$untracked" -gt 0
            set_color $tide_git_color_untracked; echo -ns ' ?'$untracked
        end)
end
