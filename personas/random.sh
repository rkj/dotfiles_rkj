#!/bin/bash
# Get the directory where this script is located
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Find all .md files in that directory, pick one at random, and output its contents
FILE=$(find "$DIR" -maxdepth 1 -name "*.md" | shuf -n 1)
cat "$FILE"
