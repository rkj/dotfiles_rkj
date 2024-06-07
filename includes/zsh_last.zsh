# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
[[ ! -f ~/.p10k_extra.zsh ]] || source ~/.p10k_extra.zsh
(( ! ${+functions[p10k]} )) || p10k finalize
