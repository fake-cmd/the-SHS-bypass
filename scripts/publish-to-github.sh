#!/usr/bin/env bash
set -euo pipefail

REMOTE_URL="${1:-https://github.com/fake-cmd/the-SHS-bypass.git}"
TARGET_BRANCH="main"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: run this inside a git repository." >&2
  exit 1
fi

current_branch="$(git branch --show-current)"

if [[ -z "$(git status --porcelain)" ]]; then
  echo "Working tree is clean."
else
  echo "Error: you have uncommitted changes. Commit or stash before publishing." >&2
  exit 1
fi

if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "$REMOTE_URL"
else
  git remote add origin "$REMOTE_URL"
fi

if [[ "$current_branch" != "$TARGET_BRANCH" ]]; then
  git branch -M "$TARGET_BRANCH"
fi

echo "Pushing $TARGET_BRANCH to $REMOTE_URL ..."
git push -u origin "$TARGET_BRANCH"

echo "Done: https://github.com/fake-cmd/the-SHS-bypass/tree/main"
