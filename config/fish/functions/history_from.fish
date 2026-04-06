function history_from
    # Note: fish history is different from bash fc, but this approximates the intent
    history --since $argv | sort
end
