function jjx --wraps="jj diff --from main --name-only | fzf --preview 'jj diff --from main --color always {}' --bind 'enter:execute(hx {})'" --description "alias jjx jj diff --from main --name-only | fzf --preview 'jj diff --from main --color always {}' --bind 'enter:execute(hx {})'"
    jj diff --from main --name-only | fzf --preview 'jj diff --from main --color always {}' --bind 'enter:execute(hx {})' $argv
end
