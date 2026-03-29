function copy
    # 1. Print OSC 52 header
    printf "\033]52;c;"
    
    # 2. Base64 encode stdin, strip newlines, and pipe directly to stdout
    #    (Using tr -d '\n' ensures a continuous string for the terminal)
    base64 | tr -d '\n'
    
    # 3. Print OSC 52 footer (Bell)
    printf "\a"
end
