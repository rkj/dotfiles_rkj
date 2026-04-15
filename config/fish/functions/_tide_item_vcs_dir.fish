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
        # Outside any repo — fall back to pwd-style display
        set -l display (string replace -r "^$home_regex" '~' $PWD)
        _tide_print_item vcs_dir "$tide_pwd_icon $display"
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

    # Status counters — git/jj use git porcelain, hg is simple dirty check
    set -l bg_color $tide_vcs_dir_bg_color
    set -l status_parts

    if test "$vcs_type" = git -o "$vcs_type" = jj
        set -l stat (git --no-optional-locks status --porcelain 2>/dev/null)
        set -l conflicted (string match -r ^UU $stat | count)
        set -l staged (string match -r ^[ADMR] $stat | count)
        set -l dirty (string match -r ^.[ADMR] $stat | count)
        set -l untracked (string match -r '^\?\?' $stat | count)
        set -l stash (git stash list 2>/dev/null | count)

        set -l behind 0
        set -l ahead 0
        if git rev-list --count --left-right @{upstream}...HEAD 2>/dev/null | read -d \t -l b a
            set behind $b
            set ahead $a
        end

        # Determine bg color
        if test "$conflicted" -gt 0
            set bg_color $tide_git_bg_color_urgent
        else if test "$staged" -gt 0 -o "$dirty" -gt 0 -o "$untracked" -gt 0
            set bg_color $tide_git_bg_color_unstable
        end

        # Build status indicators
        test "$behind" -gt 0; and set -a status_parts "⇣$behind"
        test "$ahead" -gt 0; and set -a status_parts "⇡$ahead"
        test "$stash" -gt 0; and set -a status_parts "*$stash"
        test "$conflicted" -gt 0; and set -a status_parts "~$conflicted"
        test "$staged" -gt 0; and set -a status_parts "+$staged"
        test "$dirty" -gt 0; and set -a status_parts "!$dirty"
        test "$untracked" -gt 0; and set -a status_parts "?$untracked"
    end

    set -l output "$icon$repo_display"
    if test (count $status_parts) -gt 0
        set output "$output "(string join ' ' $status_parts)
    end

    tide_vcs_dir_bg_color=$bg_color _tide_print_item vcs_dir $output
end
