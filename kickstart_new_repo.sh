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


# Create bootstrap subfolder for regular files
mkdir -p bootstrap
cp -r "$SRC/scripts" ./bootstrap/
cp "$SRC/.iterate.json" ./bootstrap/
cp "$SRC/ROADMAP.md" ./bootstrap/
cp "$SRC/README.md" ./bootstrap/

# Copy .github and .vscode to root
cp -r "$SRC/.vscode" .
cp -r "$SRC/.github" .

chmod +x ./bootstrap/scripts/iterate.sh

# Clean up temp
rm -rf "$TMPDIR"

echo "✅ Copilot Bootstrap files copied! You can now run:"
echo "  bash scripts/iterate.sh doctor"
echo "  bash scripts/iterate.sh iterate"
