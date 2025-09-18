#!/usr/bin/env bash
## Copilot Bootstrap Setup Script
# One-time use only! Do not use or reference after initial setup.
# Not for app runtime, CI, or automation.
set -euo pipefail

REPO="hotbrainco/copilot-bootstrap"
TAG="${BOOTSTRAP_TAG:-}"
if [[ -z "$TAG" ]]; then
	# Resolve latest release tag dynamically to avoid stale defaults
	TAG="$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" | awk -F '"' '/tag_name/ {print $4; exit}')"
fi
if [[ -z "$TAG" ]]; then
	echo "ERROR: Failed to determine release tag. Set BOOTSTRAP_TAG to a version like v0.1.13." >&2
	exit 1
fi
ZIP_URL="https://github.com/$REPO/archive/refs/tags/$TAG.zip"

# ----------------------------------------------------------------------
# Externalized defaults sourcing (single source of truth)
# Order of precedence (highest first):
#   1. Explicit environment variables (BOOTSTRAP_DEFAULT_*)
#   2. Local repo config .copilot-bootstrap.conf (if present before run)
#   3. installer-defaults.conf bundled with release archive
#   4. Hard fallback literals below (only used if nothing set)
# Users should customize by creating .copilot-bootstrap.conf with KEY=VALUE lines.
# ----------------------------------------------------------------------

# Initialize BOOTSTRAP_DEFAULT_* vars safely (avoid indirect expansion with set -u)
: "${BOOTSTRAP_DEFAULT_PROCEED_INSTALL:=}"
: "${BOOTSTRAP_DEFAULT_INIT_GIT:=}"
: "${BOOTSTRAP_DEFAULT_CONNECT_GITHUB:=}"
: "${BOOTSTRAP_DEFAULT_PUSH_INITIAL:=}"
: "${BOOTSTRAP_DEFAULT_SETUP_DOCS:=}"
: "${BOOTSTRAP_DEFAULT_DOCS_CHOICE:=}"
: "${BOOTSTRAP_DEFAULT_INSTALL_MKDOCS:=}"
: "${BOOTSTRAP_DEFAULT_COMMIT_DOCS:=}"
: "${BOOTSTRAP_DEFAULT_ENABLE_PAGES_INTERACTIVE:=}"
: "${BOOTSTRAP_DEFAULT_RUN_DOCS_NOW:=}"
: "${BOOTSTRAP_DEFAULT_REPO_VISIBILITY:=}"
: "${BOOTSTRAP_DEFAULT_VERIFY_PAGES:=}"
: "${BOOTSTRAP_DEFAULT_ENABLE_PAGES_NOW:=}"
: "${BOOTSTRAP_DEFAULT_RUN_DOCTOR_ON_INSTALL:=}"
: "${BOOTSTRAP_DEFAULT_BUILD_DOCS_ON_INSTALL:=}"
: "${BOOTSTRAP_DEFAULT_ENABLE_CHANGELOG_AUTO:=}"

# Source user-provided config first if present
if [[ -f .copilot-bootstrap.conf ]]; then
	# shellcheck disable=SC1091
	. ./.copilot-bootstrap.conf || true
fi

# Later we'll copy installer-defaults.conf; source it after extraction (see below) if values still unset.

# Function to finalize defaults after potential sourcing of packaged defaults
finalize_defaults() {
	DEFAULT_PROCEED_INSTALL="${BOOTSTRAP_DEFAULT_PROCEED_INSTALL:-Y}"
	DEFAULT_INIT_GIT="${BOOTSTRAP_DEFAULT_INIT_GIT:-Y}"
	DEFAULT_CONNECT_GITHUB="${BOOTSTRAP_DEFAULT_CONNECT_GITHUB:-Y}"
	DEFAULT_PUSH_INITIAL="${BOOTSTRAP_DEFAULT_PUSH_INITIAL:-Y}"
	DEFAULT_SETUP_DOCS="${BOOTSTRAP_DEFAULT_SETUP_DOCS:-N}"
	DEFAULT_DOCS_CHOICE="${BOOTSTRAP_DEFAULT_DOCS_CHOICE:-1}"
	DEFAULT_INSTALL_MKDOCS="${BOOTSTRAP_DEFAULT_INSTALL_MKDOCS:-Y}"
	DEFAULT_COMMIT_DOCS="${BOOTSTRAP_DEFAULT_COMMIT_DOCS:-Y}"
	DEFAULT_ENABLE_PAGES_INTERACTIVE="${BOOTSTRAP_DEFAULT_ENABLE_PAGES_INTERACTIVE:-N}"
	DEFAULT_RUN_DOCS_NOW="${BOOTSTRAP_DEFAULT_RUN_DOCS_NOW:-N}"
	DEFAULT_REPO_VISIBILITY="${BOOTSTRAP_DEFAULT_REPO_VISIBILITY:-private}"
	DEFAULT_VERIFY_PAGES="${BOOTSTRAP_DEFAULT_VERIFY_PAGES:-Y}"
	DEFAULT_ENABLE_PAGES_NOW="${BOOTSTRAP_DEFAULT_ENABLE_PAGES_NOW:-N}"
	DEFAULT_RUN_DOCTOR_ON_INSTALL="${BOOTSTRAP_DEFAULT_RUN_DOCTOR_ON_INSTALL:-Y}"
	DEFAULT_BUILD_DOCS_ON_INSTALL="${BOOTSTRAP_DEFAULT_BUILD_DOCS_ON_INSTALL:-Y}"
	DEFAULT_ENABLE_CHANGELOG_AUTO="${BOOTSTRAP_DEFAULT_ENABLE_CHANGELOG_AUTO:-Y}"
}

# Pages verification tuning (overridable via env)
# Seconds to wait and poll intervals for build status and URL probe
VERIFY_PAGES_BUILD_TIMEOUT="${BOOTSTRAP_PAGES_BUILD_TIMEOUT_SECONDS:-240}"
VERIFY_PAGES_BUILD_INTERVAL="${BOOTSTRAP_PAGES_BUILD_INTERVAL_SECONDS:-3}"
VERIFY_PAGES_PROBE_TIMEOUT="${BOOTSTRAP_PAGES_PROBE_TIMEOUT_SECONDS:-120}"
VERIFY_PAGES_PROBE_INTERVAL="${BOOTSTRAP_PAGES_PROBE_INTERVAL_SECONDS:-2}"

# Interactive helpers
is_tty() {
	[[ "${BOOTSTRAP_INTERACTIVE:-}" == "false" ]] && return 1
	[[ "${BOOTSTRAP_INTERACTIVE:-}" == "true" ]] && return 0
	[[ -t 1 || -t 0 ]] && return 0
	[[ -r /dev/tty ]]
}
yesno() {
	local prompt="$1" default="${2:-Y}" ans
	local suffix=" [y/N]"
	[[ "$default" == "Y" || "$default" == "y" ]] && suffix=" [Y/n]"
	if [[ "${BOOTSTRAP_INTERACTIVE:-}" == "false" ]]; then
		ans="$default"
	elif [[ -r /dev/tty ]]; then
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

TMPDIR="$(mktemp -d)"

curl -fsSL "$ZIP_URL" -o "$TMPDIR/cb.zip"
unzip -q "$TMPDIR/cb.zip" -d "$TMPDIR"
# Strip leading 'v' from tag for extracted folder naming
TAG_DIR="${TAG#v}"
SRC="$TMPDIR/copilot-bootstrap-$TAG_DIR"

# Source packaged installer-defaults.conf if present and user has not defined variables
if [[ -f "$SRC/installer-defaults.conf" ]]; then
	# shellcheck disable=SC1091
	. "$SRC/installer-defaults.conf" || true
fi

# Now resolve final defaults
finalize_defaults

# Pre-install summary and confirmation (after defaults resolved)
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
	if ! yesno "Proceed with installation?" "$DEFAULT_PROCEED_INSTALL"; then
		echo "Aborted. No changes made."
		rm -rf "$TMPDIR"
		exit 0
	fi
fi


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
		# In non-interactive mode we still perform git/origin setup using defaults
		if ! in_git_repo; then
			if yesno "Initialize a git repository here?" "$DEFAULT_INIT_GIT"; then
				git init -b main 2>/dev/null || { git init || true; }
				# Ensure default branch is main before first commit when possible
				git symbolic-ref HEAD refs/heads/main 2>/dev/null || true
				ensure_initial_commit
				is_tty && echo "✅ Initialized git repo (main) and created initial commit" || true
			fi
		fi
			if in_git_repo && ! has_origin_remote; then
				if yesno "Connect this repo to GitHub now?" "$DEFAULT_CONNECT_GITHUB"; then
					if [[ "${BOOTSTRAP_INTERACTIVE:-}" == "false" ]]; then
						GH_URL="${BOOTSTRAP_REMOTE_URL:-}"
					else
						read -r -p "Enter existing GitHub repo URL (ssh/https), or leave blank to create via gh: " GH_URL < /dev/tty || true
					fi
				# Validate that GH_URL looks like a git URL, not literal text like "leave blank"
				if [[ -n "${GH_URL:-}" ]] && [[ "$GH_URL" =~ ^(git@|https?://) ]]; then
					git remote add origin "$GH_URL" 2>/dev/null || git remote set-url origin "$GH_URL" || true
					ensure_initial_commit
					if yesno "Push to origin now?" "$DEFAULT_PUSH_INITIAL"; then
						git push -u origin main || true
					fi
				elif command -v gh >/dev/null 2>&1; then
					DEFAULT_NAME="${PWD##*/}"
					if [[ "${BOOTSTRAP_INTERACTIVE:-}" == "false" ]]; then
						NEW_NAME="$DEFAULT_NAME"
						VIS="$DEFAULT_REPO_VISIBILITY"
					else
						read -r -p "New repo name [${DEFAULT_NAME}]: " NEW_NAME < /dev/tty || true
						NEW_NAME=${NEW_NAME:-$DEFAULT_NAME}
						read -r -p "Visibility (private/public) [${DEFAULT_REPO_VISIBILITY}]: " VIS < /dev/tty || true
						VIS=${VIS:-$DEFAULT_REPO_VISIBILITY}
					fi
					ensure_initial_commit
					# Allow org/name input; gh uses current user if no owner provided
					# Note: --confirm/-y is deprecated in newer gh; run interactively without it
					gh repo create "$NEW_NAME" --source=. --push --"$VIS" || true
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
		# Determine visibility for private-repo handling
		local visibility
		visibility=$(gh repo view --json visibility -q .visibility 2>/dev/null || echo "unknown")

		# Helper to interpret a failed API call and provide a friendly message
		local _out _status
		try_put_create() {
			_out=$(gh api --method PUT "repos/${slug}/pages" -f build_type=workflow 2>&1); _status=$?
			if [[ $_status -eq 0 ]]; then
				echo "✅ GitHub Pages enabled (Actions workflow)"; return 0
			fi
			# Try create then configure
			_out=$(gh api --method POST "repos/${slug}/pages" -f build_type=workflow 2>&1); _status=$?
			if [[ $_status -eq 0 ]]; then
				_out=$(gh api --method PUT "repos/${slug}/pages" -f build_type=workflow 2>&1); _status=$?
				if [[ $_status -eq 0 ]]; then
					echo "✅ GitHub Pages created and configured (Actions workflow)"; return 0
				fi
			fi
			return 1
		}

		# If repo is private and not forced, attempt and detect plan limitation cleanly
		if [[ "${BOOTSTRAP_PAGES_FORCE:-false}" != "true" && "$visibility" != "PUBLIC" ]]; then
			if ! try_put_create; then
				if echo "$_out" | grep -qi "does not support GitHub Pages"; then
					echo "Private repo detected and current plan does not support Pages. Skipping enablement."
				else
					echo "Skipping Pages enable (private repo) — set BOOTSTRAP_PAGES_FORCE=true to attempt anyway."
				fi
				return 1
			fi
			return 0
		fi

		# Public repos or forced: proceed
		if try_put_create; then return 0; fi
		echo "WARN: Failed to create or enable Pages (see: gh api repos/${slug}/pages)"
		return 1
	}

	# Verify Pages deployment and availability
	spinner_init() {
		# Usage: spinner_init "Label"
		SPINNER_FRAMES=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
		SPINNER_INDEX=0
		SPINNER_LABEL="$1"
	}
	spinner_step() {
		# Only animate on a TTY to avoid noisy CI logs
		[[ -t 1 ]] || return 0
		local f=${SPINNER_FRAMES[$SPINNER_INDEX]}
		printf "\r%s %s" "$f" "$SPINNER_LABEL"
		# Small delay to increase perceived speed; overridable via BOOTSTRAP_SPINNER_DELAY_SECONDS
		local delay="${BOOTSTRAP_SPINNER_DELAY_SECONDS:-0.05}"
		SPINNER_INDEX=$(((SPINNER_INDEX+1) % ${#SPINNER_FRAMES[@]}))
		# Use sleep only if delay > 0
		awk -v d="$delay" 'BEGIN { if (d+0 > 0) { system("sleep " d) } }' >/dev/null 2>&1 || true
	}
	spinner_end() {
		[[ -t 1 ]] || return 0
		printf "\r    \r"
	}
	pages_slug_from_origin() {
		git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 1
		git remote get-url origin >/dev/null 2>&1 || return 1
		local url slug
		url=$(git remote get-url origin)
		case "$url" in
			git@github.com:*) slug="${url#git@github.com:}"; slug="${slug%.git}" ;;
			https://github.com/*) slug="${url#https://github.com/}"; slug="${slug%.git}" ;;
			*) return 1 ;;
		esac
		printf "%s" "$slug"
	}

	resolve_pages_url() {
		command -v gh >/dev/null 2>&1 || return 1
		local slug owner repo url
		slug=$(pages_slug_from_origin) || return 1
		owner="${slug%%/*}"
		repo="${slug##*/}"
		# Try API for canonical URL; fallback to default project pages URL
		url=$(gh api -H "Accept: application/vnd.github+json" "repos/${slug}/pages" -q .html_url 2>/dev/null || true)
		if [[ -z "$url" || "$url" == "null" ]]; then
			url="https://${owner}.github.io/${repo}/"
		fi
		printf "%s" "$url"
	}

	pages_enabled() {
		command -v gh >/dev/null 2>&1 || return 1
		local slug
		slug=$(pages_slug_from_origin) || return 1
		gh api -H "Accept: application/vnd.github+json" "repos/${slug}/pages" >/dev/null 2>&1
	}

	wait_for_pages_build() {
		command -v gh >/dev/null 2>&1 || return 1
		local slug status tries=0
		local max_tries interval
		slug=$(pages_slug_from_origin) || return 1
		# Derive tries from timeout/interval, with sane fallbacks
		interval=${VERIFY_PAGES_BUILD_INTERVAL:-3}
		[[ "$interval" -gt 0 ]] || interval=3
		local total=${VERIFY_PAGES_BUILD_TIMEOUT:-240}
		[[ "$total" -gt 0 ]] || total=240
		max_tries=$(( total / interval ))
		(( max_tries > 0 )) || max_tries=80
		spinner_init "Waiting for Pages build (1–2 min)…"
		while (( tries < max_tries )); do
			status=$(gh api -H "Accept: application/vnd.github+json" "repos/${slug}/pages/builds/latest" -q .status 2>/dev/null || echo "unknown")
			if [[ "$status" == "built" ]]; then
				spinner_end
				return 0
			fi
			if [[ "$status" == "errored" ]]; then
				spinner_end
				echo "Pages build errored (check Actions logs)."
				return 1
			fi
			spinner_step
			sleep "$interval"
			tries=$((tries+1))
		done
		spinner_end
		# Do not emit a scary timeout yet; the site may already be live.
		return 1
	}

	verify_pages_reachable() {
		local url status tries=0
		local max_tries interval total
		url=$(resolve_pages_url) || return 1
		interval=${VERIFY_PAGES_PROBE_INTERVAL:-2}
		[[ "$interval" -gt 0 ]] || interval=2
		total=${VERIFY_PAGES_PROBE_TIMEOUT:-120}
		[[ "$total" -gt 0 ]] || total=120
		max_tries=$(( total / interval ))
		(( max_tries > 0 )) || max_tries=60
		spinner_init "Probing Pages URL (a few seconds)…"
		while (( tries < max_tries )); do
			status=$(curl -sSIf "$url" -o /dev/null -w "%{http_code}" || echo "000")
			case "$status" in
				200|301|302)
					spinner_end
					echo "✅ GitHub Pages is live at: $url"
					return 0
					;;
			esac
			spinner_step
			sleep "$interval"
			tries=$((tries+1))
		done
		spinner_end
		echo "WARN: Could not confirm Pages is live yet. Try again soon: $url"
		return 1
	}

	if yesno "Set up documentation now?" "$DEFAULT_SETUP_DOCS"; then
		echo ""
		echo "📚 Documentation options:"
		echo "  1. MkDocs (Python) - Material theme, great for technical docs"
		echo "  2. VitePress (Node.js) - Vue-based, fast and modern"
		echo "  3. Docusaurus (Node.js) - React-based, feature-rich"
		echo "  4. Simple Markdown - No dependencies, works with GitHub Pages"
		echo ""
	if [[ "${BOOTSTRAP_INTERACTIVE:-}" == "false" ]]; then
		docs_choice="$DEFAULT_DOCS_CHOICE"
	else
		read -r -p "Choose option (1-4) [${DEFAULT_DOCS_CHOICE}]: " docs_choice
		docs_choice=${docs_choice:-$DEFAULT_DOCS_CHOICE}
	fi
		
		case "$docs_choice" in
			1)
				echo "🐍 Setting up MkDocs..."
				maybe_copy_docs_starter
				chmod +x ./bootstrap/scripts/install-mkdocs.sh || true
				if yesno "Install MkDocs in .venv now?" "$DEFAULT_INSTALL_MKDOCS"; then
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
		
		# Auto-commit any newly created documentation files (controlled by DEFAULT_COMMIT_DOCS)
		if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
			if [[ -n "$(git status --porcelain)" ]]; then
				if [[ "$DEFAULT_COMMIT_DOCS" == "Y" || "$DEFAULT_COMMIT_DOCS" == "y" ]]; then
					echo "💾 Committing documentation files"
					git add -A || true
					git commit -m "docs: add initial documentation files" || true
					if git remote get-url origin >/dev/null 2>&1; then
						git push -u origin "$(git rev-parse --abbrev-ref HEAD)" || true
					fi
				else
					echo "Skipping docs commit (DEFAULT_COMMIT_DOCS not enabled)"
				fi
			fi
		fi


		# Offer to enable GitHub Pages when a Pages workflow is present
		if command -v gh >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1 && git remote get-url origin >/dev/null 2>&1; then
			if [[ -f .github/workflows/docs-pages.yml ]] || grep -R "deploy-pages@" -n .github/workflows >/dev/null 2>&1; then
				if [[ "${BOOTSTRAP_PAGES_SKIP:-}" == "true" ]]; then
					echo "Skipping Pages enable (BOOTSTRAP_PAGES_SKIP=true)"
				elif [[ "${BOOTSTRAP_PAGES_ENABLE:-}" == "false" ]]; then
					echo "Pages enable disabled (BOOTSTRAP_PAGES_ENABLE=false)"
				else
					if pages_enabled; then
						echo "GitHub Pages is already enabled for this repository."
					else
						if yesno "Enable GitHub Pages (publish docs via Actions)?" "$DEFAULT_ENABLE_PAGES_NOW"; then
							echo "🔄 Enabling GitHub Pages for this repo (Actions build)"
							enable_pages_via_gh || true
						else
							echo "GitHub Pages not enabled. You can enable later in repo settings or via gh."
						fi
					fi
				fi
			else
				# Offer interactive enable if a different docs system added a Pages workflow later
				if is_tty && yesno "Enable GitHub Pages to publish docs (uses Actions)?" "$DEFAULT_ENABLE_PAGES_INTERACTIVE"; then
					enable_pages_via_gh || true
				fi
			fi
		fi
		
		# Automatically run doctor and build docs (no prompt), controllable via env defaults
		if [[ "$DEFAULT_RUN_DOCTOR_ON_INSTALL" =~ ^[Yy]$ ]]; then
			bash bootstrap/scripts/iterate.sh doctor || true
		fi

		if [[ "$DEFAULT_BUILD_DOCS_ON_INSTALL" =~ ^[Yy]$ ]]; then
			if [[ -d .venv && "$docs_choice" == "1" ]]; then
				source .venv/bin/activate
				ITERATE_PAGES_ENABLE=true bash bootstrap/scripts/iterate.sh docs || true
				deactivate || true
			else
				ITERATE_PAGES_ENABLE=true bash bootstrap/scripts/iterate.sh docs || true
			fi
		fi

		# Optional verification that GitHub Pages is live
		if pages_enabled; then
			if yesno "Verify GitHub Pages is live now?" "$DEFAULT_VERIFY_PAGES"; then
				echo "🔎 Verifying GitHub Pages deployment and availability"
				# First, try to wait for the Pages build to report built; if this times out,
				# we'll still probe the URL below and only warn if the probe also fails.
				if ! wait_for_pages_build; then
					: # build polling timed out or not available
				fi
				if ! verify_pages_reachable; then
					echo "Timed out waiting for Pages build to complete."  # only shown if probe also failed
				fi
			fi
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

add_cb_to_path_prompt() {
	# Offer to append export line for cb dispatcher to user's shell profile.
	# Skip in non-interactive mode or if already on PATH.
	local repo_dir path_entry shell_name profile export_line
	repo_dir="$(pwd)"
	path_entry="${repo_dir}/bootstrap/scripts"
	# If cb already directly runnable, skip.
	if command -v cb >/dev/null 2>&1; then
		# Heuristic: ensure the resolved path matches our repo; if not, still offer
		local existing
		existing="$(command -v cb || true)"
		if [[ "$existing" == "$path_entry/cb" ]]; then
			return 0
		fi
	fi
	is_tty || return 0
	shell_name="$(basename "${SHELL:-sh}")"
	# Choose a profile file based on shell
	case "$shell_name" in
		zsh) profile="$HOME/.zshrc" ;;
		bash)
			if [[ "$(uname -s)" == "Darwin" ]]; then
				profile="$HOME/.bash_profile"
			else
				profile="$HOME/.bashrc"
			fi
			;;
		fish) profile="$HOME/.config/fish/config.fish" ;;
		*) profile="$HOME/.profile" ;;
	esac
	export_line="export PATH=\"$path_entry:\$PATH\""
	# Already present?
	if [[ -f "$profile" ]] && grep -F "$path_entry" "$profile" >/dev/null 2>&1; then
		return 0
	fi
	if yesno "Add 'cb' (bootstrap dispatcher) to your PATH now? (Recommended)" "Y"; then
		# Ensure directory exists for fish config
		mkdir -p "$(dirname "$profile")" 2>/dev/null || true
		{
			echo ""
					echo "# Added by copilot-bootstrap v0.6.1 to expose cb dispatcher"
			if [[ "$shell_name" == "fish" ]]; then
				echo "set -gx PATH $path_entry \$PATH"
			else
				echo "$export_line"
			fi
		} >> "$profile"
		# Apply to current session where possible (POSIX shells)
		if [[ "$shell_name" != "fish" ]]; then
			export PATH="$path_entry:$PATH"
		fi
		echo "✅ Added $path_entry to PATH via $profile"
		echo "   Restart your shell or 'source $profile' to persist."
	else
		echo "Skipped adding cb to PATH. You can add later with:"
		echo "  echo '$export_line' >> $profile && source $profile"
	fi
}

add_cb_to_path_prompt || true

if yesno "Enable automated changelog updates from Releases?" "$DEFAULT_ENABLE_CHANGELOG_AUTO"; then
	# Ensure workflow directory exists
	mkdir -p .github/workflows
	# Copy workflow if present in source and not already existing
	if [[ -f "$SRC/.github/workflows/update-changelog.yml" ]]; then
		if [[ ! -f ./.github/workflows/update-changelog.yml ]]; then
			cp "$SRC/.github/workflows/update-changelog.yml" ./.github/workflows/
		fi
	fi
	# Copy helper script into bootstrap scripts namespace for portability
	if [[ -f "$SRC/scripts/append-changelog.sh" ]]; then
		mkdir -p ./bootstrap/scripts
		cp "$SRC/scripts/append-changelog.sh" ./bootstrap/scripts/
		chmod +x ./bootstrap/scripts/append-changelog.sh || true
	fi
	echo "🧾 Auto-changelog workflow enabled (updates CHANGELOG.md on release)."
else
	# If user declines and file exists from a prior run, leave it but inform
	if [[ -f ./.github/workflows/update-changelog.yml ]]; then
		echo "(Keeping existing update-changelog workflow; disable manually if undesired)"
	fi
fi

echo "✅ Copilot Bootstrap installed. Next steps:"
echo "  bash bootstrap/scripts/iterate.sh doctor"
echo "  ITERATE_DRY_RUN=true bash bootstrap/scripts/iterate.sh iterate"
echo "  bash bootstrap/scripts/iterate.sh iterate"
