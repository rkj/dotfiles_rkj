function _tide_item_shpool
    if set -q SHPOOL_SESSION_NAME
        set -l shpool_icon "🧵 "
        _tide_print_item shpool "$shpool_icon$SHPOOL_SESSION_NAME"
    end
end
