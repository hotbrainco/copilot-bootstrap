#!/usr/bin/env bash
set -euo pipefail
# Append (actually insert after header) a release body into CHANGELOG.md.
# Usage:
#   scripts/append-changelog.sh v0.2.1 release-notes.md
# If release-notes.md is '-', read from stdin.

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <tag> <body-file|- (stdin)>" >&2
  exit 1
fi
TAG="$1"; BODY_SRC="$2"
DATE=$(date +%Y-%m-%d)
CHANGELOG="CHANGELOG.md"

if [[ ! -f "$CHANGELOG" ]]; then
  echo "# Changelog" > "$CHANGELOG"
  echo >> "$CHANGELOG"
fi

# Read body
if [[ "$BODY_SRC" == "-" ]]; then
  BODY_CONTENT=$(cat)
else
  BODY_CONTENT=$(cat "$BODY_SRC")
fi

# Strip leading title lines like "# vX.Y.Z" or "## vX.Y.Z"
BODY_CONTENT=$(printf "%s" "$BODY_CONTENT" | sed -E '1{/^#{1,3} v?[0-9]+\.[0-9]+\.[0-9]+/d;}')
# Trim leading blank lines
BODY_CONTENT=$(printf "%s" "$BODY_CONTENT" | sed -E '/./,$!d')
# Ensure ends with single newline
BODY_CONTENT=$(printf "%s" "$BODY_CONTENT" | sed -E ':a;N;$!ba;s/\n{3,}/\n\n/g')

# If section already exists, abort silently
if grep -q "^## \[$TAG\]" "$CHANGELOG"; then
  echo "Section $TAG already present; not modifying." >&2
  exit 0
fi

NEW_SECTION="## [$TAG] - $DATE\n${BODY_CONTENT}\n"

# Insert after first line beginning with # Changelog
awk -v section="$NEW_SECTION" 'NR==1{print;printed=1;next} NR==2 && printed {print section; printed=0} NR>1{print}' "$CHANGELOG" > "$CHANGELOG.tmp"
# Fallback if the simplistic insertion failed (no header match)
if ! grep -q "^## \[$TAG\]" "$CHANGELOG.tmp"; then
  printf "# Changelog\n\n%s\n" "$NEW_SECTION" > "$CHANGELOG.tmp"
  grep -v "^# Changelog" "$CHANGELOG" >> "$CHANGELOG.tmp" || true
fi
mv "$CHANGELOG.tmp" "$CHANGELOG"

echo "Added $TAG to CHANGELOG.md"