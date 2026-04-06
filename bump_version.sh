#!/bin/bash
set -e

GODOT_FILE="project.godot"
BUMP_TYPE="${1:-patch}"

current=$(grep 'config/version=' "$GODOT_FILE" | sed 's/config\/version="v\(.*\)"/\1/')
if [[ -z "$current" ]]; then
  echo "Error: could not find config/version in $GODOT_FILE" >&2
  exit 1
fi

IFS='.' read -r major minor patch <<< "$current"

case "$BUMP_TYPE" in
  major) major=$((major + 1)); minor=0; patch=0 ;;
  minor) minor=$((minor + 1)); patch=0 ;;
  patch) patch=$((patch + 1)) ;;
  *)
    echo "Usage: $0 [major|minor|patch]" >&2
    exit 1
    ;;
esac

new="v${major}.${minor}.${patch}"
sed -i '' "s/config\/version=\"v${current}\"/config\/version=\"${new}\"/" "$GODOT_FILE"

echo ""
echo "  bump type : $BUMP_TYPE"
echo "  old       : v${current}"
echo "  new       : ${new}"
echo ""
echo "  Done. $GODOT_FILE updated."
echo ""
