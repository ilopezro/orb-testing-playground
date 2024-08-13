#!/bin/bash
set -eo pipefail

echo "Enforcing separate commits in the directory: $PATH_TO_CHECK"

# Get the current branch name
current_branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$current_branch" == "merging" ]]; then
  echo "We are borsing. Fast-passing the check."
  exit 0
fi

echo "Checking commits in branch $current_branch..."

commits=$(git rev-list master..HEAD)
echo "Commits to check: $commits"

for commit in $commits; do
  echo "Checking commit $commit..."
  changed_files=$(git diff-tree --no-commit-id --name-only -r "$commit")
  echo "Changed files: $changed_files"

  if [[ -z "$changed_files" ]]; then
    continue
  fi

  # Match files in the specific path using ERE
  files=$(echo "$changed_files" | grep -E "${PATH_TO_CHECK}")
  echo "Matched restricted files: $files"

  # Match files that are not in the specific path using ERE
  other_files=$(echo "$changed_files" | grep -v -E "${PATH_TO_CHECK}")
  echo "Matched other files: $other_files"

  if [[ -n "$files" && -n "$other_files" ]]; then
    echo "Error: Commit $commit is not clean."
    exit 1
  fi
done

echo "All commits are clean. Exiting successfully."
exit 0
