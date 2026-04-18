function _tide_item_vcs_dir
    set -l text (_tide_item_vcs_status_text)
    
    # Determine background color based on status symbols
    # Conflict marker is ' ~' followed by a number.
    # Status markers are ' +', ' !', ' ?'
    # Repo icons are at the start: , 🥋, ☿
    
    if string match -qr ' ~[0-9]' "$text"
        set -g tide_vcs_dir_bg_color $tide_git_bg_color_urgent
    else if string match -qr ' [+!?]' "$text"
        set -g tide_vcs_dir_bg_color $tide_git_bg_color_unstable
    else if string match -qr '^[🥋☿]' "$text"
        set -g tide_vcs_dir_bg_color $tide_git_bg_color
    else
        set -g tide_vcs_dir_bg_color $tide_pwd_bg_color
    end

    _tide_print_item vcs_dir (set_color $tide_git_color_branch; echo -ns "$text")
end
