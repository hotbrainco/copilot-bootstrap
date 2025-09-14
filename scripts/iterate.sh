#!/usr/bin/env bash
set -Eeuo pipefail

# ---------- Configuration via environment variables ----------
: "${ITERATE_COMMIT_PREFIX:=chore:}"
: "${ITERATE_PR_TITLE_PREFIX:=chore:}"
: "${ITERATE_PR_DRAFT:=true}"           # "true" | "false"
: "${ITERATE_PR_BASE:=}"                # If empty, gh picks default
: "${ITERATE_PR_REVIEWERS:=}"           # comma-separated GitHub handles
: "${ITERATE_SKIP_DOCS:=false}"         # "true" to skip docs step
: "${ITERATE_RUN_TESTS_IF_PRESENT:=true}" # only runs tests if a script or common tool exists
: "${ITERATE_STRICT:=false}"            # "true" to fail on missing tools
: "${ITERATE_STRICT_DOCS:=}"            # override docs strictness; defaults to ITERATE_STRICT
: "${ITERATE_DRY_RUN:=false}"           # "true" to only print actions

# ---------- Helpers ----------
die() { echo "ERROR: $*" >&2; exit 1; }
warn() { echo "WARN: $*" >&2; }

# Execute function/cmd or just echo when dry-run
run_cmd() {
	if [[ "${ITERATE_DRY_RUN}" == "true" ]]; then
		echo "DRY-RUN: $*"
	else
		"$@"
	fi
}

pm_detect() {
	if [[ -f pnpm-lock.yaml ]]; then echo "pnpm"; return; fi
	if [[ -f yarn.lock ]]; then echo "yarn"; return; fi
	echo "npm"
}

pm_run() {
	local pm="$1"; shift
	case "$pm" in
		pnpm) pnpm "$@";;
		yarn) yarn "$@";;
		npm) npm run "$@";;
		*) die "Unknown package manager: $pm";;
	esac
}

pm_exec() {
	# "dlx" style executables
	local pm="$1"; shift
	case "$pm" in
		pnpm) pnpm dlx "$@";;
		yarn) yarn dlx "$@";;
		npm) npx "$@";;
		*) die "Unknown package manager: $pm";;
	esac
}

have_cmd() { command -v "$1" >/dev/null 2>&1; }

has_pkg_script() {
	local name="$1"
	[[ -f package.json ]] && grep -q "\"$name\"\\s*:" package.json
}

	# Optional JSON config loader (.iterate.json). Requires jq if present.
	load_config() {
		local cfg=".iterate.json"
		[[ -f "$cfg" ]] || return 0
		if ! have_cmd jq; then
			warn "Found $cfg but jq is not installed; skipping config load"
			return 0
		fi

		# Helper to set var only if currently default/empty
		set_if_unset() {
			local var="$1" val
			val="$(jq -r ".${2}" "$cfg" 2>/dev/null)" || true
			[[ "$val" == "null" ]] && return 0
			# shellcheck disable=SC2086
			eval "cur=\"\${$var-}\""
			if [[ -z "${cur}" ]]; then
				# shellcheck disable=SC2140
				eval "export $var=\"$val\""
			fi
		}

		set_if_unset ITERATE_COMMIT_PREFIX commitPrefix
		set_if_unset ITERATE_PR_TITLE_PREFIX prTitlePrefix
		set_if_unset ITERATE_PR_DRAFT prDraft
		set_if_unset ITERATE_PR_BASE prBase
		set_if_unset ITERATE_PR_REVIEWERS prReviewers
		set_if_unset ITERATE_SKIP_DOCS skipDocs
		set_if_unset ITERATE_RUN_TESTS_IF_PRESENT runTestsIfPresent
		set_if_unset ITERATE_STRICT strict
		set_if_unset ITERATE_STRICT_DOCS strictDocs
		set_if_unset ITERATE_DRY_RUN dryRun
	}

detect_docs_system() {
	if [[ -f docusaurus.config.js || -f docusaurus.config.ts ]] || ( [[ -f package.json ]] && grep -q "@docusaurus/" package.json ); then
		echo "docusaurus"; return
	fi
	if [[ -f mkdocs.yml || -f mkdocs.yaml ]]; then
		echo "mkdocs"; return
	fi
	if [[ -f docs/conf.py || -f docs/source/conf.py ]] ; then
		echo "sphinx"; return
	fi
	echo "none"
}

	in_git_repo() {
		git rev-parse --is-inside-work-tree >/dev/null 2>&1
	}

	has_origin_remote() {
		git remote get-url origin >/dev/null 2>&1
	}

git_has_changes() {
	in_git_repo || return 1
	git update-index -q --refresh
	! git diff --quiet || ! git diff --cached --quiet
}

ensure_branch() {
	local current; current="$(git rev-parse --abbrev-ref HEAD)"
	if [[ "$current" == "HEAD" ]]; then
		echo "Detached HEAD; staying on current commit"
		return
	fi
	if [[ "$current" == "main" || "$current" == "master" ]]; then
		local ts; ts="$(date +%Y%m%d-%H%M%S)"
		local new="iter/${ts}"
		run_cmd git checkout -b "$new"
		echo "$new"
	else
		echo "$current"
	fi
}

should_strict_docs() {
	if [[ -n "${ITERATE_STRICT_DOCS}" ]]; then
		[[ "${ITERATE_STRICT_DOCS}" == "true" ]]
	else
		[[ "${ITERATE_STRICT}" == "true" ]]
	fi
}

preflight() {
	local pm docs git_repo remote gh_ok
	pm="$(pm_detect)"
	docs="$(detect_docs_system)"
	in_git_repo && git_repo="yes" || git_repo="no"
	has_origin_remote && remote="yes" || remote="no"
	have_cmd gh && gh_ok="yes" || gh_ok="no"
	echo "==> Preflight"
	echo "Package manager: $pm"
	echo "Docs system: $docs"
	echo "Git repo: $git_repo, origin remote: $remote"
	echo "GitHub CLI: $gh_ok"
	echo "Config: strict=${ITERATE_STRICT}, strictDocs=${ITERATE_STRICT_DOCS:-inherit}, dryRun=${ITERATE_DRY_RUN}, skipDocs=${ITERATE_SKIP_DOCS}, runTestsIfPresent=${ITERATE_RUN_TESTS_IF_PRESENT}"
}

# ---------- Steps ----------
step_build() {
	local pm; pm="$(pm_detect)"
	echo "==> Build using $pm"
	if has_pkg_script "build"; then
		run_cmd pm_run "$pm" build || die "Build failed"
	else
		echo "No build script found; skipping"
	fi
}

step_test() {
	local pm; pm="$(pm_detect)"
	if [[ "$ITERATE_RUN_TESTS_IF_PRESENT" != "true" ]]; then
		echo "==> Tests disabled by config"; return
	fi

	echo "==> Test using $pm (if available)"
	if has_pkg_script "test"; then
		case "$pm" in
				npm) run_cmd npm test --silent || run_cmd npm test;;
				pnpm) run_cmd pnpm test --silent || run_cmd pnpm test;;
				yarn) run_cmd yarn test --silent || run_cmd yarn test;;
		esac
	elif have_cmd "vitest"; then
			run_cmd vitest run
	elif have_cmd "jest"; then
			run_cmd jest --ci
	elif have_cmd "pytest"; then
		# Run pytest and treat exit code 5 (no tests collected) as a soft-skip
		set +e
		pytest -q
		code=$?
		set -e
		if [[ $code -eq 0 ]]; then
			:
		elif [[ $code -eq 5 ]]; then
			echo "No pytest tests collected; skipping"
		else
			exit $code
		fi
	elif have_cmd "go"; then
		if [[ -f go.mod ]]; then
			if find . -type f -name '*_test.go' -print -quit | grep -q .; then
				run_cmd go test ./...
			else
				echo "No Go tests detected; skipping"
			fi
		else
			echo "No go.mod found; skipping Go tests"
		fi
	else
		echo "No tests detected; skipping"
	fi
}

step_docs() {
	if [[ "$ITERATE_SKIP_DOCS" == "true" ]]; then
		echo "==> Docs step skipped by config"; return
	fi
	local pm; pm="$(pm_detect)"
	local system; system="$(detect_docs_system)"
	echo "==> Docs system: $system"

	case "$system" in
		docusaurus)
			if has_pkg_script "docs:build"; then
				run_cmd pm_run "$pm" docs:build
			elif has_pkg_script "build:docs"; then
				run_cmd pm_run "$pm" build:docs
			elif has_pkg_script "docs"; then
				run_cmd pm_run "$pm" docs
			else
				run_cmd pm_exec "$pm" docusaurus build
			fi
			;;
		mkdocs)
			if have_cmd "mkdocs"; then
				run_cmd mkdocs build
			else
				if should_strict_docs; then
					die "mkdocs not installed. Install with: pip install mkdocs or brew install mkdocs"
				else
					warn "mkdocs not installed; skipping docs"
				fi
			fi
			;;
		sphinx)
			if have_cmd "sphinx-build"; then
				local src="docs/source"; [[ -f docs/conf.py ]] && src="docs"
				run_cmd sphinx-build -b html "$src" docs/_build
			else
				if should_strict_docs; then
					die "sphinx-build not installed. Install with: pip install sphinx"
				else
					warn "sphinx-build not installed; skipping docs"
				fi
			fi
			;;
		none)
			if has_pkg_script "docs:update"; then
				run_cmd pm_run "$pm" docs:update
			else
				echo "No docs system detected and no 'docs:update' script; skipping docs"
			fi
			;;
	esac
}

step_git() {
	echo "==> Git commit and push"
	if ! in_git_repo; then
		echo "Not a git repository; skipping commit and push"
		return
	fi
	if ! has_origin_remote; then
		echo "No 'origin' remote configured; skipping push"
	fi
	if ! git_has_changes; then
		echo "No changes to commit"; return
	fi

	run_cmd git add -A

	# Build a conventional-like message from staged changes
	local msg="${ITERATE_COMMIT_PREFIX} update code and docs"
	if have_cmd "git"; then
		local summary
		summary="$(git diff --cached --name-only | sed 's/^/- /')"
		msg+=$'\n\nFiles changed:\n'"$summary"
	fi

		run_cmd git commit -m "$msg" || true

	local branch; branch="$(ensure_branch)"
		if has_origin_remote; then
			run_cmd git push -u origin "$branch"
		else
			warn "Push skipped (no origin remote)"
		fi
}

step_pr() {
	echo "==> Create or update PR"
	if ! in_git_repo; then
		echo "Not a git repository; skipping PR"
		return
	fi
	if [[ "${ITERATE_DRY_RUN}" == "true" ]]; then
		echo "DRY-RUN: gh pr create/update (skipped)"
		return
	fi
	if ! have_cmd "gh"; then
		echo "GitHub CLI (gh) not installed. Install from https://cli.github.com/ and rerun this step."
		return
	fi
	if ! has_origin_remote; then
		echo "No 'origin' remote configured; skipping PR"
		return
	fi

	local title="${ITERATE_PR_TITLE_PREFIX} iteration update"
	local flags=()
	[[ -n "${ITERATE_PR_BASE}" ]] && flags+=("--base" "$ITERATE_PR_BASE")

	if gh pr view >/dev/null 2>&1; then
		echo "PR already exists; adding a comment"
		gh pr comment --body "Automated iteration update."
	else
		if [[ "$ITERATE_PR_DRAFT" == "true" ]]; then flags+=("--draft"); fi
		if [[ -n "${ITERATE_PR_REVIEWERS}" ]]; then flags+=("--reviewer" "$ITERATE_PR_REVIEWERS"); fi
		gh pr create --title "$title" --fill "${flags[@]}"
	fi

	echo "PR URL:"
		run_cmd gh pr view --json url --jq .url || true
}

# ---------- Main ----------
load_config
cmd="${1:-help}"
case "$cmd" in
	build) step_build;;
	test) step_test;;
	docs) step_docs;;
	git) step_git;;
	pr) step_pr;;
	doctor)
		preflight
		;;
	all|iterate)
		preflight
		step_build
		step_test
		step_docs
		step_git
		step_pr
		;;
	help|*)
		cat <<EOF
Usage: scripts/iterate.sh [build|test|docs|git|pr|iterate|doctor]
Environment:
	ITERATE_COMMIT_PREFIX           default "chore:"
	ITERATE_PR_TITLE_PREFIX         default "chore:"
	ITERATE_PR_DRAFT                "true" | "false" (default "true")
	ITERATE_PR_BASE                 e.g. "main" (default gh's default base)
	ITERATE_PR_REVIEWERS            comma-separated handles
	ITERATE_SKIP_DOCS               "true" to skip docs step
	ITERATE_RUN_TESTS_IF_PRESENT    "true" (default) to run tests if detected
	ITERATE_STRICT                  "true" to error on missing tools
	ITERATE_STRICT_DOCS             override docs strictness (default inherit)
	ITERATE_DRY_RUN                 "true" to print actions without running

Config file:
	Optional .iterate.json (requires jq). Example keys:
		{"commitPrefix":"chore:", "skipDocs":"false", "dryRun":"false"}
EOF
		;;
esac
