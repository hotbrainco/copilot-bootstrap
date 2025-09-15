#!/usr/bin/env bash
## Copilot Bootstrap Setup Script
# One-time use only! Do not use or reference after initial setup.
# Not for app runtime, CI, or automation.
set -euo pipefail

REPO="hotbrainco/copilot-bootstrap"
TAG="${BOOTSTRAP_TAG:-v0.1.5}"
ZIP_URL="https://github.com/$REPO/archive/refs/tags/$TAG.zip"

# Interactive helpers
is_tty() { [[ "${BOOTSTRAP_INTERACTIVE:-}" == "true" ]] && return 0; [[ -t 1 || -t 0 ]] && return 0; [[ -r /dev/tty ]]; }
yesno() {
	local prompt="$1" default="${2:-Y}" ans
	local suffix=" [y/N]"
	[[ "$default" == "Y" || "$default" == "y" ]] && suffix=" [Y/n]"
	if [[ -r /dev/tty ]]; then
		# Prompt via the controlling terminal when available (works even when stdin is a pipe)
		read -r -p "$prompt$suffix " ans < /dev/tty || true
	elif [[ -t 0 || -t 1 ]]; then
		read -r -p "$prompt$suffix " ans || true
	else
		ans="$default"
	fi
	ans=${ans:-$default}
	[[ "$ans" == "y" || "$ans" == "Y" ]]
}

# Pre-install summary and confirmation (TTY or BOOTSTRAP_INTERACTIVE)
if is_tty; then
	echo "Copilot Bootstrap will install:"
	echo "  - bootstrap/scripts/* into ./bootstrap/"
	echo "  - Optional bootstrap docs (README, COPILOT_BOOTSTRAP) into ./bootstrap/"
	echo "  - .iterate.json and ROADMAP.md into repo root"
	echo "  - .vscode/ and .github/ (only missing files; existing files preserved)"
	echo "It may also:"
	echo "  - Patch VS Code tasks and CI workflow references to new script path"
	echo "  - Configure this repo to use GitHub CLI for git credentials (if gh + git repo)"
	echo ""
	if ! yesno "Proceed with installation?" Y; then
		echo "Aborted. No changes made."
		exit 0
	fi
fi

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

	# --- Git/GitHub setup walkthrough ---
	in_git_repo() { git rev-parse --is-inside-work-tree >/dev/null 2>&1; }
	has_origin_remote() { git remote get-url origin >/dev/null 2>&1; }
	git_has_commits() { git rev-parse HEAD >/dev/null 2>&1; }
	ensure_initial_commit() {
		if ! git_has_commits; then
			git add -A || true
			git commit -m "chore: bootstrap iteration workflow" || true
		fi
	}
	maybe_setup_git_and_origin() {
		is_tty || return 0
		if ! in_git_repo; then
			if yesno "Initialize a git repository here?" Y; then
				git init -b main 2>/dev/null || { git init || true; }
				# Ensure default branch is main before first commit when possible
				git symbolic-ref HEAD refs/heads/main 2>/dev/null || true
				ensure_initial_commit
				echo "✅ Initialized git repo (main) and created initial commit"
			fi
		fi
		if in_git_repo && ! has_origin_remote; then
			if yesno "Connect this repo to GitHub now?" Y; then
				read -r -p "Enter existing GitHub repo URL (ssh/https), or leave blank to create via gh: " GH_URL < /dev/tty || true
				if [[ -n "${GH_URL:-}" ]]; then
					git remote add origin "$GH_URL" 2>/dev/null || git remote set-url origin "$GH_URL" || true
					ensure_initial_commit
					if yesno "Push to origin now?" Y; then
						git push -u origin main || true
					fi
				elif command -v gh >/dev/null 2>&1; then
					DEFAULT_NAME="${PWD##*/}"
					read -r -p "New repo name [${DEFAULT_NAME}]: " NEW_NAME < /dev/tty || true
					NEW_NAME=${NEW_NAME:-$DEFAULT_NAME}
					read -r -p "Visibility (private/public) [private]: " VIS < /dev/tty || true
					VIS=${VIS:-private}
					ensure_initial_commit
					# Allow org/name input; gh uses current user if no owner provided
					gh repo create "$NEW_NAME" --source=. --push --"$VIS" -y || true
				else
					echo "gh CLI not found. You can create a repo later and run: git remote add origin <url>; git push -u origin main"
				fi
			fi
		fi
		# Re-apply gh credential helper now that repo may exist
		if command -v gh >/dev/null 2>&1 && in_git_repo; then
			git config --local --unset-all credential.helper 2>/dev/null || true
			git config --local credential.helper '!gh auth git-credential' || true
		fi
	}

	maybe_setup_git_and_origin

	# --- Optional interactive docs setup ---

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
		
		# Offer Pages enablement only when gh + origin are present
		if command -v gh >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1 && git remote get-url origin >/dev/null 2>&1; then
			if yesno "Enable GitHub Pages to publish docs (uses Actions)?" N; then
				enable_pages_via_gh || true
			fi
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
