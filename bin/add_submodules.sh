#!/bin/bash

# Check if .hgsub file exists
if [ ! -f .hgsub ]; then
  echo ".hgsub file not found!"
  exit 1
fi

# Read the .hgsub file line by line
while IFS= read -r line
do
  # Skip empty lines
  if [ -z "$line" ]; then
    continue
  fi

  # Extract path and URL from the line
  path=$(echo $line | awk -F' =' '{print $1}' | xargs)
  url=$(echo $line | awk -F'=' '{print $2}' | xargs)

  # Remove [git] prefix from the URL
  url=${url/\[git\]/}

  # Generate and execute the git submodule add command
  echo "git submodule add $url $path"
  git submodule add --force $url $path
done < .hgsub
