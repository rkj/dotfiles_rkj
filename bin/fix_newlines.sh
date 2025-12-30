#!/bin/bash

for file in "$@"; do
    # Check if file exists and is not empty
    if [ -f "$file" ] && [ -s "$file" ]; then
        # Check if the last byte is a newline
        # 'tail -c 1' gets the last byte
        # 'wc -l' counts lines; if 0, the last byte wasn't a newline
        if [ "$(tail -c 1 "$file" | wc -l)" -eq 0 ]; then
            echo "" >> "$file"
            echo "Added newline to: $file"
        else
            echo "Skipped (newline exists): $file"
        fi
    fi
done
