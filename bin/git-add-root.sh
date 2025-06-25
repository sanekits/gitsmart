#!/bin/bash
# git-add-root.sh - Create a new Git root commit on a new orphan branch

show_help() {
  echo "Usage: $0 [OPTIONS] <branch-name>"
  echo
  echo "Create a new Git root commit on a new orphan branch."
  echo
  echo "Options:"
  echo "  -h, --help     Show this help message and exit"
  echo "  -m, --message  Commit message (default: \"New root commit\")"
  echo
  echo "Example:"
  echo "  $0 new-root"
  echo "  $0 -m \"My custom root commit\" custom-branch"
}

# Default commit message
message="New root commit"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      exit 0
      ;;
    -m|--message)
      message="$2"
      shift 2
      ;;
    *)
      branch_name="$1"
      shift
      ;;
  esac
done

# Check if branch name was provided
if [ -z "$branch_name" ]; then
  echo "Error: Branch name is required"
  show_help
  exit 1
fi

# Create a new orphan branch
git checkout --orphan "$branch_name"

# Unstage all files without removing them from the working directory
git reset

# Create an empty commit as the new root
git commit --allow-empty -m "$message"

echo "Successfully created new root commit on branch '$branch_name'"
