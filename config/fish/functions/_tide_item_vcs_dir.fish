function _tide_item_vcs_dir
    set -l home_regex (string escape --style=regex $HOME)

    set -l text (_tide_item_vcs_status_text)
    
    # Determine background color based on status symbols
    if string match -q '*~*' "$text"
        set -g tide_vcs_dir_bg_color $tide_git_bg_color_urgent
    else if string match -r '[+!?]' "$text"
        set -g tide_vcs_dir_bg_color $tide_git_bg_color_unstable
    end

    # Print the item with branch color (black usually) and the text
    _tide_print_item vcs_dir (set_color $tide_git_color_branch; echo -ns "$text")
end
