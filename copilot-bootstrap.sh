#!/usr/bin/env bash
## Copilot Bootstrap Setup Script
# One-time use only! Do not use or reference after initial setup.
# Not for app runtime, CI, or automation.
set -euo pipefail

REPO="hotbrainco/copilot-bootstrap"
TAG="${BOOTSTRAP_TAG:-v0.1.5}"
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


# Prefer GitHub CLI for git credentials in this repo to avoid Keychain prompts
if command -v gh >/dev/null 2>&1; then
	if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		# Configure at repo scope; do not modify global user config
		git config --local --unset-all credential.helper 2>/dev/null || true
		git config --local credential.helper '!gh auth git-credential' || true
		echo "🔐 Configured git to use GitHub CLI credentials for this repo"
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

	# --- Optional interactive docs setup ---
	is_tty() { [[ "${BOOTSTRAP_INTERACTIVE:-}" == "true" ]] && return 0; [[ -t 0 && -t 1 ]]; }
	yesno() {
		local prompt="$1" default="${2:-N}" ans
		if ! is_tty; then return 1; fi
		read -r -p "$prompt [y/N] " ans || true
		ans=${ans:-$default}
		[[ "$ans" == "y" || "$ans" == "Y" ]]
	}

	maybe_copy_docs_starter() {
		local copied="false"
		if [[ -f "$SRC/mkdocs.yml" ]]; then
			if [[ ! -f mkdocs.yml ]]; then
				cp "$SRC/mkdocs.yml" ./
				copied="true"
			fi
		fi
		if [[ -d "$SRC/docs" ]]; then
			if [[ ! -d ./docs ]]; then
				cp -R "$SRC/docs" ./
				copied="true"
			fi
		fi
		[[ "$copied" == "true" ]] && echo "✅ Added MkDocs starter (mkdocs.yml, docs/)" || true
	}

	enable_pages_via_gh() {
		command -v gh >/dev/null 2>&1 || { echo "gh not installed; skipping Pages enable"; return 1; }
		git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "Not a git repo; skipping Pages enable"; return 1; }
		git remote get-url origin >/dev/null 2>&1 || { echo "No origin remote; skipping Pages enable"; return 1; }
		local url slug
		url=$(git remote get-url origin)
		case "$url" in
			git@github.com:*) slug="${url#git@github.com:}"; slug="${slug%.git}" ;;
			https://github.com/*) slug="${url#https://github.com/}"; slug="${slug%.git}" ;;
			*) echo "Unrecognized origin; skipping Pages enable"; return 1 ;;
		esac
		gh api --method PUT "repos/${slug}/pages" -f build_type=workflow && echo "✅ Enabled GitHub Pages (Actions)" || echo "WARN: Failed to enable Pages"
	}

	if yesno "Set up documentation now?" N; then
		echo ""
		echo "📚 Documentation options:"
		echo "  1. MkDocs (Python) - Material theme, great for technical docs"
		echo "  2. VitePress (Node.js) - Vue-based, fast and modern"
		echo "  3. Docusaurus (Node.js) - React-based, feature-rich"
		echo "  4. Simple Markdown - No dependencies, works with GitHub Pages"
		echo ""
		read -r -p "Choose option (1-4) [1]: " docs_choice
		docs_choice=${docs_choice:-1}
		
		case "$docs_choice" in
			1)
				echo "🐍 Setting up MkDocs..."
				maybe_copy_docs_starter
				chmod +x ./bootstrap/scripts/install-mkdocs.sh || true
				if yesno "Install MkDocs in .venv now?" Y; then
					bash ./bootstrap/scripts/install-mkdocs.sh || true
				fi
				;;
			2)
				echo "⚡ Setting up VitePress..."
				chmod +x ./bootstrap/scripts/setup-docs.sh || true
				bash ./bootstrap/scripts/setup-docs.sh vitepress || true
				;;
			3)
				echo "⚛️ Setting up Docusaurus..."
				chmod +x ./bootstrap/scripts/setup-docs.sh || true
				bash ./bootstrap/scripts/setup-docs.sh docusaurus || true
				;;
			4)
				echo "📝 Setting up simple markdown docs..."
				chmod +x ./bootstrap/scripts/setup-docs.sh || true
				bash ./bootstrap/scripts/setup-docs.sh simple || true
				;;
			*)
				echo "Invalid choice, skipping docs setup."
				;;
		esac
		
		if yesno "Enable GitHub Pages to publish docs (requires gh + origin)?" N; then
			enable_pages_via_gh || true
		fi
		
		if [[ "$docs_choice" == "1" ]] && yesno "Run doctor and build docs now?" N; then
			bash bootstrap/scripts/iterate.sh doctor || true
			ITERATE_PAGES_ENABLE=true bash bootstrap/scripts/iterate.sh docs || true
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
