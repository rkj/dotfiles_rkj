#!/bin/bash
# Get the directory where this script is located
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Find all .md files in that directory and pick one at random
find "$DIR" -maxdepth 1 -name "*.md" | shuf -n 1
