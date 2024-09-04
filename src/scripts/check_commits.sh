#!/bin/bash
set -eo pipefail

echo -e "Enforcing separate commits in the directory: $PATH_TO_ENFORCE\n"

# Get the current branch name
if [[ "$CIRCLE_BRANCH" == "merging" ]]; then
  echo "We are borsing. Fast-passing the check."
  exit 0
fi

default_branch=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')

echo "Checking commits in branch $CIRCLE_BRANCH..."
echo -e "Checking commits against $default_branch...\n"

commits=$(git rev-list "$default_branch"..HEAD)

for commit in $commits; do
  short_commit=$(echo "$commit" | cut -c 1-8)
  echo "Checking commit $short_commit..."
  changed_files=$(git diff-tree --no-commit-id --name-only -r "$commit")

  # Matching files in the restricted directory
  files=$(echo "$changed_files" | grep -E "${PATH_TO_ENFORCE}" || true)

  # Matching files outside the restricted directory
  other_files=$(echo "$changed_files" | grep -v -E "${PATH_TO_ENFORCE}" || true)

  # If both files and other_files are not empty, then the commit is not clean
  if [[ -n "$files" && -n "$other_files" ]]; then
    echo "Error: Commit $short_commit is not clean."
    echo -e "Restricted directory files found batched together with other files. Please separate them into different commits.\n"

    echo "Split the following files into their own commit:"
    for file in $files; do
      echo "  - $file"
    done
    exit 1
  fi
  echo -e "Commit is clean. Continuing.\n"
done

echo "All commits are clean. Exiting successfully."
exit 0
