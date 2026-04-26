function jj --wraps=jj --description "jj with shared dotfiles config"
    command jj --config-file "$DOTFILES/config/jj/config.toml" $argv
end
