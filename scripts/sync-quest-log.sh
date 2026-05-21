#!/bin/bash
# Syncs the quest-log skill from main → quest-log branch
# Run this from anywhere in the repo after updating the skill on main.

set -e

REPO_ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
SOURCE="$REPO_ROOT/plugins/val-personal/skills/quest-log/SKILL.md"
TARGET="skills/quest-log/SKILL.md"

# Must be on main
CURRENT=$(git -C "$REPO_ROOT" branch --show-current)
if [ "$CURRENT" != "main" ]; then
  echo "❌ Switch to main first: git checkout main"
  exit 1
fi

echo "📋 Copying updated SKILL.md..."
SKILL_CONTENT=$(cat "$SOURCE")

echo "🌿 Switching to quest-log branch..."
git -C "$REPO_ROOT" checkout quest-log

echo "$SKILL_CONTENT" > "$REPO_ROOT/$TARGET"
git -C "$REPO_ROOT" add "$TARGET"

if git -C "$REPO_ROOT" diff --cached --quiet; then
  echo "✅ quest-log branch already up to date — nothing to sync."
else
  git -C "$REPO_ROOT" commit -m "sync: update quest-log skill from main"
  git -C "$REPO_ROOT" push origin quest-log
  echo "✅ Synced and pushed to quest-log branch!"
fi

echo "🔙 Switching back to main..."
git -C "$REPO_ROOT" checkout main
