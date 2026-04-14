function _tide_item_vcs_dir
    set -l vcs_type
    set -l repo_name
    set -l subpath

    set -l home_regex (string escape --style=regex $HOME)

    if set -l repo_root (git rev-parse --show-toplevel 2>/dev/null)
        if test -d "$repo_root/.jj"
            set vcs_type "jj"
        else
            set vcs_type "git"
        end
        set repo_name (string replace -r "^$home_regex" '~' $repo_root)
        set subpath (string replace "$repo_root" '' $PWD | string trim -l -c /)
        test -z "$subpath" && set subpath "/"
    else if type -q hg; and set -l hg_root (hg root 2>/dev/null)
        set vcs_type "hg"
        set repo_name (string replace -r "^$home_regex" '~' $hg_root)
        set subpath (string replace "$hg_root" '' $PWD | string trim -l -c /)
        test -z "$subpath" && set subpath "/"
    else
        set vcs_type ""
        set repo_name (string replace -r "^$home_regex" '~' $PWD)
        set subpath ""
    end

    set -l output
    set -l icon
    set -l pwd_ico "$tide_pwd_icon "

    if test "$vcs_type" = "git"
        set icon "$tide_git_icon "
        set output "$icon$repo_name"
    else if test "$vcs_type" = "jj"
        set icon "🥋"
        set output "$icon$repo_name"
    else if test "$vcs_type" = "hg"
        set icon "☿"
        set output "$icon$repo_name"
    else
        set output "$pwd_ico$repo_name"
    end

    if test -n "$subpath" -a "$subpath" != "/"
        set output "$output $pwd_ico$subpath"
    end

    _tide_print_item vcs_dir $output
end
