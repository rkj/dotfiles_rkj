function _tide_item_vcs_status_text --argument-names target_dir
    set -l home_regex (string escape --style=regex $HOME)

    # Save current directory and switch to target if provided
    set -l old_pwd $PWD
    if test -n "$target_dir"
        cd "$target_dir"
    end

    # Detect VCS type and repo root — JJ takes precedence over plain git
    set -l vcs_type ""
    set -l repo_root ""

    if set -l git_root (git rev-parse --show-toplevel 2>/dev/null)
        if test -d "$git_root/.jj"; and type -q jj
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
        # Outside any repo — use pwd style
        set -l display (string replace -r "^$home_regex" '~' $PWD)
        echo -ns "$display"
        if test -n "$target_dir"
            cd "$old_pwd"
        end
        return
    end

    set -l repo_display (string replace -r "^$home_regex" '~' $repo_root)

    # VCS icon
    set -l icon
    switch $vcs_type
        case git
            set icon " "
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

    else if test "$vcs_type" = jj
        # Use git status for file state — jj --ignore-working-copy shows stale data
        # after git commits that bypass jj snapshotting
        set -l stat (git --no-optional-locks status --porcelain 2>/dev/null)
        set conflicted (string match -r ^UU $stat | count)
        set staged (string match -r ^[ADMR] $stat | count)
        set dirty (string match -r ^.[ADMR] $stat | count)
        set untracked (string match -r '^\?\?' $stat | count)

        # Fall back to jj for conflict detection if git didn't find any
        if test "$conflicted" -eq 0
            set -l jj_stat (jj --ignore-working-copy status --no-pager 2>/dev/null)
            string match -q "*Conflict*" "$jj_stat"; and set conflicted 1
        end

        set ahead (jj --ignore-working-copy log --no-graph -r 'trunk()..@-' -T '"\n"' --no-pager 2>/dev/null | count)
    end

    # Build status string — only show non-zero counters
    echo -ns "$icon $repo_display"
    if test "$behind" -gt 0
        echo -ns ' ⇣'$behind
    end
    if test "$ahead" -gt 0
        echo -ns ' ⇡'$ahead
    end
    if test "$stash" -gt 0
        echo -ns ' *'$stash
    end
    if test "$conflicted" -gt 0
        echo -ns ' ~'$conflicted
    end
    if test "$staged" -gt 0
        echo -ns ' +'$staged
    end
    if test "$dirty" -gt 0
        echo -ns ' !'$dirty
    end
    if test "$untracked" -gt 0
        echo -ns ' ?'$untracked
    end

    if test -n "$target_dir"
        cd "$old_pwd"
    end
end
