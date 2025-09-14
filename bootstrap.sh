#!/usr/bin/env bash
## Copilot Bootstrap Setup Script
# One-time use only! Do not use or reference after initial setup.
# Not for app runtime, CI, or automation.
set -euo pipefail

# Download and extract the latest copilot-bootstrap release
REPO="hotbrainco/copilot-bootstrap"
TAG="v0.1.0"
ZIP_URL="https://github.com/$REPO/archive/refs/tags/$TAG.zip"
TMPDIR="$(mktemp -d)"

curl -L "$ZIP_URL" -o "$TMPDIR/cb.zip"
unzip -q "$TMPDIR/cb.zip" -d "$TMPDIR"
SRC="$TMPDIR/copilot-bootstrap-0.1.0"

# Copy workflow files into current directory
cp -r "$SRC/scripts" .
cp -r "$SRC/.vscode" .
cp -r "$SRC/.github" .
cp "$SRC/.iterate.json" .
cp "$SRC/ROADMAP.md" .
cp "$SRC/README.md" .

chmod +x scripts/iterate.sh

# Clean up temp
rm -rf "$TMPDIR"

echo "✅ Copilot Bootstrap files copied! You can now run:"
echo "  bash scripts/iterate.sh doctor"
echo "  bash scripts/iterate.sh iterate"
