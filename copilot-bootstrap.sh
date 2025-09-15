#!/usr/bin/env bash
## Copilot Bootstrap Setup Script
# One-time use only! Do not use or reference after initial setup.
# Not for app runtime, CI, or automation.
set -euo pipefail

REPO="hotbrainco/copilot-bootstrap"
TAG="${BOOTSTRAP_TAG:-v0.1.1}"
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

# Patch references in copied config to new bootstrap path (back-compat)
if [[ -f ./.vscode/tasks.json ]]; then
	if command -v sed >/dev/null 2>&1; then
		sed -i.bak 's#"scripts/iterate.sh"#"bootstrap/scripts/iterate.sh"#g' ./.vscode/tasks.json || true
		rm -f ./.vscode/tasks.json.bak || true
	fi
fi

if [[ -f ./.github/workflows/iterate-smoke.yml ]]; then
	if command -v sed >/dev/null 2>&1; then
		sed -i.bak 's#bash scripts/iterate.sh#bash bootstrap/scripts/iterate.sh#g' ./.github/workflows/iterate-smoke.yml || true
		# Also update branch name if workflow still references master
		sed -i.bak 's#branches: \[ master \]#branches: [ main ]#g' ./.github/workflows/iterate-smoke.yml || true
		rm -f ./.github/workflows/iterate-smoke.yml.bak || true
	fi
fi

# Create a placeholder README if one doesn't exist
if [[ ! -f README.md ]]; then
	cat > README.md <<'EOF'
# My Project

_Replace this with a real README!_

This project was set up with the [Copilot Bootstrap](https://github.com/hotbrainco/copilot-bootstrap) iteration workflow.

## Quick Start

To run the automated development loop:

1.  Open the Command Palette in VS Code (`Cmd+Shift+P` or `Ctrl+Shift+P`).
2.  Run the "Tasks: Run Build Task" command.
3.  Select `iterate`.

This will build, test, update docs, commit, push, and create a PR.

See `bootstrap/README.md` for more details on the workflow.
EOF
	echo "📝 Created placeholder README.md. You should edit it!"
fi

# Clean up temp
rm -rf "$TMPDIR"

echo "✅ Copilot Bootstrap installed. Next steps:"
echo "  bash bootstrap/scripts/iterate.sh doctor"
echo "  ITERATE_DRY_RUN=true bash bootstrap/scripts/iterate.sh iterate"
echo "  bash bootstrap/scripts/iterate.sh iterate"
