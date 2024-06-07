#!/bin/bash

# Directory to search for existing Git repositories
SEARCH_DIR=$1

if [ -z "$SEARCH_DIR" ]; then
  echo "Usage: $0 <directory>"
  exit 1
fi

# Function to check if a directory is a Git repository
is_git_repo() {
  git -C "$1" rev-parse 2> /dev/null
}

# Find all Git repositories in the search directory
find "$SEARCH_DIR" -type d -name .git | while read -r gitdir
do
  # Get the directory containing the .git folder
  repo_dir=$(dirname "$gitdir")
  
  # Check if it's a valid Git repository
  if is_git_repo "$repo_dir"; then
    # Get the remote URL of the Git repository
    url=$(git -C "$repo_dir" remote get-url origin)
    
    # Get the relative path of the repository
    relative_path=$(realpath --relative-to="$PWD" "$repo_dir")

    # Generate and execute the git submodule add command
    echo "git submodule add $url $relative_path"
    git submodule add "$url" "$relative_path"
  fi
done

