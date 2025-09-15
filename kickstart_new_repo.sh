#!/usr/bin/env bash
## Copilot Bootstrap Setup Script
# One-time use only! Do not use or reference after initial setup.
# Not for app runtime, CI, or automation.
set -euo pipefail

REPO="hotbrainco/copilot-bootstrap"
TAG="${BOOTSTRAP_TAG:-v0.1.0}"
ZIP_URL="https://github.com/$REPO/archive/refs/tags/$TAG.zip"
TMPDIR="$(mktemp -d)"

curl -fsSL "$ZIP_URL" -o "$TMPDIR/cb.zip"
unzip -q "$TMPDIR/cb.zip" -d "$TMPDIR"
# Strip leading 'v' from tag for extracted folder naming
TAG_DIR="${TAG#v}"
SRC="$TMPDIR/copilot-bootstrap-$TAG_DIR"


# Create bootstrap subfolder for scripts and docs
mkdir -p bootstrap
if [[ -d "$SRC/bootstrap/scripts" ]]; then
	cp -R "$SRC/bootstrap/scripts" ./bootstrap/
else
	# Back-compat for older releases where scripts lived at repo root
	cp -R "$SRC/scripts" ./bootstrap/
fi
# Optional bootstrap docs
[[ -f "$SRC/bootstrap/README.md" ]] && cp "$SRC/bootstrap/README.md" ./bootstrap/ || true
[[ -f "$SRC/bootstrap/COPILOT_BOOTSTRAP.md" ]] && cp "$SRC/bootstrap/COPILOT_BOOTSTRAP.md" ./bootstrap/ || true

# Copy config and roadmap to root
cp "$SRC/.iterate.json" .
cp "$SRC/ROADMAP.md" .

# Copy .github and .vscode to root (merge without clobbering existing files)
if command -v rsync >/dev/null 2>&1; then
	[[ -d "$SRC/.vscode" ]] && rsync -a --ignore-existing "$SRC/.vscode/" ./.vscode/
	[[ -d "$SRC/.github" ]] && rsync -a --ignore-existing "$SRC/.github/" ./.github/
else
	[[ -d "$SRC/.vscode" ]] && cp -R "$SRC/.vscode/." ./.vscode/
	[[ -d "$SRC/.github" ]] && cp -R "$SRC/.github/." ./.github/
fi

chmod +x ./bootstrap/scripts/iterate.sh || true

# Clean up temp
rm -rf "$TMPDIR"

echo "✅ Copilot Bootstrap installed. Next steps:"
echo "  bash bootstrap/scripts/iterate.sh doctor"
echo "  ITERATE_DRY_RUN=true bash bootstrap/scripts/iterate.sh iterate"
echo "  bash bootstrap/scripts/iterate.sh iterate"
