#!/bin/bash
set -eo pipefail

echo "Enforcing separate commits in the directory: $PATH_TO_CHECK"

# Get the current branch name
current_branch=$(git rev-parse --abbrev-ref HEAD)
# Fast-pass if the branch is 'merging'
if [[ "$current_branch" == "merging" ]]; then
  echo "We are borsing. Fast-passing the check."
  exit 0
fi

echo "Checking commits in branch $current_branch..."

commits=$(git rev-list master..HEAD)

echo "Beginning to check commits..."
echo "Commits to check: $commits"

for commit in $commits; do
  echo "Checking commit $commit..."

  changed_files=$(git diff-tree --no-commit-id --name-only -r "$commit")
  echo "Changed files: $changed_files"

  if [[ -z "$changed_files" ]]; then
    continue
  fi

  files=$(echo "$changed_files" | grep "${PATH_TO_CHECK}")
  echo "calculated files $files"
  other_files=$(echo "$changed_files" | grep -v "${PATH_TO_CHECK}")
  echo "calculated other files $other_files"

  if [[ -n $files ]]; then
    echo "Restricted directory files found in commit $commit."
  fi

  if [[ -n $other_files ]]; then
    echo "Other files found in commit $commit."
  fi

  if [[ -n "$files" && -n "$other_files" ]]; then
    echo "Error: Commit $commit is not clean."
    echo "Restricted directory files found batched together with other files. Please separate them into different commits."
    exit 1
  fi
done
# If all commits are clean, exit successfully

echo "All commits are clean. Exiting successfully."
exit 0
