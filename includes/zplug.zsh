source $DOTFILES/zplug/init.zsh
zplug "mafredri/zsh-async", from:"github", use:"async.zsh"
zplug load

# Install plugins if there are plugins that have not been installed
if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi

# Then, source plugins and add commands to $PATH
# zplug load --verbose
zplug load 

