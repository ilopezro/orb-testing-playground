#!/bin/bash
set -eo pipefail

echo "Enforcing separate commits in the directory: $PATH_TO_ENFORCE"

# Get the current branch name
current_branch=$(git rev-parse --abbrev-ref HEAD)
# Fast-pass if the branch is 'merging'
if [[ "$current_branch" == "merging" ]]; then
  echo "We are borsing. Fast-passing the check."
  exit 0
fi

echo "Checking commits in branch $current_branch..."

# Get the list of commits that are in the current branch but not in master
commits=$(git rev-list master..HEAD)

# Iterate over each commit and check for "cleanliness"
for commit in $commits; do
  # Get the list of files changed in this commit
  changed_files=$(git diff-tree --no-commit-id --name-only -r "$commit")
  # Check if any files from the directory are in this commit
  files=$(echo "$changed_files" | grep "${PATH_TO_ENFORCE}")
  # Check if there are other files in this commit
  other_files=$(echo "$changed_files" | grep -v "${PATH_TO_ENFORCE}")
  # If both files and other_files are not empty, fail the build
  if [[ -n "$files" && -n "$other_files" ]]; then
    echo "Error: Commit $commit is not clean."
    echo "Restricted directory files found batched together with other files. Please separate them into different commits."
    exit 1
  fi
done
# If all commits are clean, exit successfully

echo "All commits are clean. Exiting successfully."
exit 0
