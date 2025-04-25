#!/bin/bash
# git-binary-filechange-search.sh
#  If you know a good commit and the path of the file, we will load a vscode --diff viewer in 
# binary search mode to find the traitor commit.

set -e

usage() {
  echo "Usage: $0 <path/to/file> <known-good-commit>"
  exit 1
}

# Require exactly 2 arguments
if [ $# -ne 2 ]; then
  usage
fi

FILE="$1"
GOOD_COMMIT="$2"

# Check file exists in working tree
if [ ! -f "$FILE" ]; then
  echo "Error: File '$FILE' does not exist in the working directory."
  exit 1
fi

# Check if good commit is valid
if ! git cat-file -e "$GOOD_COMMIT^{commit}" 2>/dev/null; then
  echo "Error: '$GOOD_COMMIT' is not a valid commit hash."
  exit 1
fi

echo "Starting git bisect..."
git bisect start
git bisect bad
git bisect good "$GOOD_COMMIT"

git bisect run bash -c '
  FILE="'"$FILE"'"
  git show HEAD^:"$FILE" > /tmp/prev.txt 2>/dev/null || > /tmp/prev.txt
  git show HEAD:"$FILE" > /tmp/next.txt 2>/dev/null || > /tmp/next.txt
  code --diff /tmp/prev.txt /tmp/next.txt
  read -p "Is the bug in this version? (y/n): " ANSWER
  if [ "$ANSWER" = "y" ]; then
    exit 1
  else
    exit 0
  fi
'

git bisect reset
