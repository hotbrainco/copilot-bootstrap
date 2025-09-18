# Iteration Workflow Starter

Quick Start (install into your project):

```bash
TAG=$(curl -fsSL https://api.github.com/repos/hotbrainco/copilot-bootstrap/releases/latest | awk -F '"' '/tag_name/ {print $4; exit}')
bash -c "$(curl -fsSL https://raw.githubusercontent.com/hotbrainco/copilot-bootstrap/${TAG}/copilot-bootstrap.sh)"
```

What this does:
- Copies `bootstrap/scripts/iterate.sh` and helpers into `./bootstrap/`
- Adds `.iterate.json`, `ROADMAP.md`, `.vscode/`, `.github/` (preserving existing files)
- Prints next-step commands to run the iteration loop
- Prompts you to confirm before copying files
- Guides you to set up git and a GitHub repo (init, connect existing URL, or create via `gh`) and only then offers to enable GitHub Pages

Doctor (preflight):

- What it is: a read-only check that detects your stack (package manager, docs, tests, git/gh) and prints what the iteration loop would do. It doesn’t change your repo.
- The installer runs doctor automatically after docs setup (controllable via `BOOTSTRAP_DEFAULT_RUN_DOCTOR_ON_INSTALL`). You can also run it any time:

```bash
bash bootstrap/scripts/iterate.sh doctor
```

Prefer a pinned version or no pipe-to-shell? See below.

## Troubleshooting

- Missing tools: enable strict mode to fail explicitly (`ITERATE_STRICT=true`), or install the required tool.
- Unexpected git behavior: ensure you're on a branch and have `origin` configured.
- PR step errors: verify you're authenticated with `gh auth login` and have push permissions.
- Note: The `iterate` task automatically creates a feature branch when run from `main`/`master` to avoid conflicts.

Latest release (auto) — no pipe-to-shell alternative:

```bash
TAG=$(curl -fsSL https://api.github.com/repos/hotbrainco/copilot-bootstrap/releases/latest | awk -F '"' '/tag_name/ {print $4; exit}')
curl -fsSL https://raw.githubusercontent.com/hotbrainco/copilot-bootstrap/${TAG}/copilot-bootstrap.sh -o copilot-bootstrap.sh
bash copilot-bootstrap.sh
```

Pinned version (optional; replace vX.Y.Z with a specific tag):

```bash
curl -fsSL https://raw.githubusercontent.com/hotbrainco/copilot-bootstrap/vX.Y.Z/copilot-bootstrap.sh -o copilot-bootstrap.sh
bash copilot-bootstrap.sh
```

Tip: To force interactive prompts (even when piping), set `BOOTSTRAP_INTERACTIVE=true`:

```bash
TAG=$(curl -fsSL https://api.github.com/repos/hotbrainco/copilot-bootstrap/releases/latest | awk -F '"' '/tag_name/ {print $4; exit}')
BOOTSTRAP_INTERACTIVE=true bash -c "$(curl -fsSL https://raw.githubusercontent.com/hotbrainco/copilot-bootstrap/${TAG}/copilot-bootstrap.sh)"
```

What gets installed
- Root: `.vscode/`, `.github/`, `.iterate.json`, `ROADMAP.md`
- Subfolder: `bootstrap/` (contains `scripts/iterate.sh`, `README.md`, `COPILOT_BOOTSTRAP.md`)

Your app’s README at repo root is not overwritten. Bootstrap docs live under `bootstrap/`.

## Setup Scripts


`copilot-bootstrap.sh` is a one-time setup helper for copying workflow files into a new app repo.

**Warning:** Do not use or reference `copilot-bootstrap.sh` after initial setup. It is not for app runtime, CI, or automation.

### Usage

1. Copy `copilot-bootstrap.sh` into your new app folder.
2. Run this in VS Code’s terminal:
  ```bash
  bash copilot-bootstrap.sh
  ```
  This will:
  - Download the latest workflow files from this repo.
  - Copy regular files (`scripts/`, `.iterate.json`, `ROADMAP.md`, `README.md`) into a `bootstrap/` subfolder.
  - Copy `.github/` and `.vscode/` into your repo root.
  - Make everything ready to use.

  Afterwards, you can immediately run:
  ```bash
  bash bootstrap/scripts/iterate.sh doctor
  bash bootstrap/scripts/iterate.sh iterate
  ```


A portable, stack-aware build–test–docs–git–PR loop you can drop into any repository. It adds VS Code tasks, a script to orchestrate common steps, and guidance to keep changes small and iterative.

## Quick Start

- Run in VS Code: open the Command Palette → "Tasks: Run Build Task" → select `iterate`.
- Or run the script directly:

```bash
bootstrap/scripts/iterate.sh iterate
```

This executes, in order: build → test → docs → commit/push → PR.

If you’re not using git yet or don’t have a remote, use:

```bash
# Skip git/PR steps
bootstrap/scripts/iterate.sh doctor
bootstrap/scripts/iterate.sh iterate
```

The script will automatically skip unavailable steps, and prints a preflight summary first.

### QoL Command Wrapper (Experimental)

You can use the lightweight `cb` dispatcher (installed at `bootstrap/scripts/cb`) to shorten commands:

```bash
# Make it executable (once)
chmod +x bootstrap/scripts/cb

# Add to PATH for current shell session
export PATH="$PWD/bootstrap/scripts:$PATH"

# Run iteration loop
cb iterate

# Individual steps
cb build
cb test
cb docs
cb git
cb pr
cb doctor

# Run internal bootstrap test suite (if present)
cb tests

# Safely tear down a test repo (NOT the copilot-bootstrap repo itself)
cb teardown --dry-run                # show plan only
cb teardown                          # interactive local delete
cb teardown --archive                # archive before delete
cb teardown --delete-remote          # ask to also remove remote
cb teardown --delete-remote --yes    # skip first confirmation
cb teardown --keep-dir --archive     # only archive, keep directory

# Dry-run convenience
cb dry-run iterate

# (Future) Feature toggles once features.sh lands
cb features list
cb features enable docs:mkdocs
```

During install (v0.4.0+) you will be prompted to add the `cb` dispatcher to your PATH (recommended; auto-detects your shell profile). If you skipped or are in a non-interactive install, you can still add it manually:

Persistent PATH suggestion (add to your shell profile):
```bash
echo 'export PATH="$HOME/path/to/your/repo/bootstrap/scripts:$PATH"' >> ~/.zshrc
```

If using Node tooling you can also expose it via an npm script:
```json
{
  "scripts": { "iterate": "bootstrap/scripts/cb iterate" }
}
```

Roadmap: shell completion (`cb <TAB>`), feature registry commands, and autoversion display.

## Feature Toggles (Modular Components)

You can enable or disable optional capabilities after initial bootstrap using the feature manager.

Current feature IDs:

- `docs:mkdocs` / `docs:vitepress` / `docs:docusaurus` / `docs:simple`
- `github:pages` (logical flag; Pages enabling still needs a docs workflow)
- `pr:auto` (controls whether PR creation runs during `iterate`)
- `sandbox` (always effectively present; toggle is informational)
- `changelog` (exposes changelog helper script)
- `update:script` (presence of update tooling)

States are stored in `.iterate.json` under `features{}`; env vars still override (e.g. `ITERATE_SKIP_DOCS`). If no docs feature is enabled, the docs step is skipped.

Commands:
```bash
# List features
cb features list

# Enable MkDocs docs (creates mkdocs.yml + docs/ scaffold if missing)
cb features enable docs:mkdocs

# Disable automatic PR step (iterate will skip pr)
cb features disable pr:auto

# Re-run iteration
cb iterate
```

Non-destructive disable: files are not deleted; you can remove them manually if you fully abandon a system.

## What’s Included

- `.vscode/tasks.json`: VS Code tasks to drive the flow.
- `.vscode/settings.json`: Enables Prompt Files for Copilot.
- `bootstrap/scripts/iterate.sh`: Stack-aware orchestration for build, test, docs, git, and PR.
- `.github/workflows/iterate-smoke.yml`: CI smoke that runs doctor, build, test, and docs (soft-skip) on PRs/pushes.
- `.github/prompts/iterate-workflow.prompt.md`: Per-chat prompt to guide iterative work.
- `.github/copilot-instructions.md`: Always-on Copilot repo instructions.
- `ROADMAP.md`: A simple roadmap that both humans and Copilot can use.

## Optional: Documentation Setup

This repo supports multiple documentation options to fit different preferences and tech stacks:

### MkDocs (Python-based)
Material theme, excellent for technical documentation:

```bash
# Install in local .venv (recommended)
bash bootstrap/scripts/install-mkdocs.sh

# Or activate existing environment
source .venv/bin/activate
mkdocs serve
```

### VitePress (Node.js-based)
Vue-powered, fast and modern:

```bash
# Setup VitePress docs
bash bootstrap/scripts/setup-docs.sh vitepress

# Install and run
npm add -D vitepress
npx vitepress dev docs
```

### Docusaurus (Node.js-based)
React-based, feature-rich platform:

```bash
# Setup Docusaurus (creates docs/ folder)
bash bootstrap/scripts/setup-docs.sh docusaurus

# Run development server
cd docs && npm start
```

### Simple Markdown
No dependencies, works with GitHub Pages:

```bash
# Creates docs/ with markdown files and GitHub Pages workflow
bash bootstrap/scripts/setup-docs.sh simple
```

### Build via iterate

The installer builds docs automatically after setup (controllable via `BOOTSTRAP_DEFAULT_BUILD_DOCS_ON_INSTALL`). You can also build via the iterate docs step:

```bash
bootstrap/scripts/iterate.sh docs
```

### Publish to GitHub Pages

This repo includes a GitHub Actions workflow at `.github/workflows/docs-pages.yml` that builds MkDocs and deploys to GitHub Pages on pushes to `main`. The workflow uses `actions/configure-pages` + `actions/upload-pages-artifact` + `actions/deploy-pages`.

One-time setup:
- When a Pages workflow is present, the installer will explicitly ask: "Enable GitHub Pages (publish docs via Actions)?" Default is No. You can control the default with `BOOTSTRAP_DEFAULT_ENABLE_PAGES_NOW`.
- Set `BOOTSTRAP_PAGES_SKIP=true` to skip entirely, or `BOOTSTRAP_PAGES_ENABLE=false` to disable programmatic enabling.
- If you’re using the iterate docs step later, it can also enable Pages automatically (and you can use the same env flags).

Optional verification:
- After enabling Pages (either during install or via iterate), the installer can verify that Pages is live by:
  - Polling the latest Pages build status via GitHub API, then
  - Probing the site URL until it returns HTTP 200/301/302.
  - A small spinner animation is shown while waiting (TTY only).
- Control this prompt via `BOOTSTRAP_DEFAULT_VERIFY_PAGES=Y|N` (default Y when interactive). Advanced tuning: see the env variables below for timeouts/intervals and spinner speed.

Manual fallback (if needed):
- With `gh`:
  ```bash
  REPO_SLUG="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
  gh api --method POST "repos/${REPO_SLUG}/pages" -f build_type=workflow || true
  gh api --method PUT  "repos/${REPO_SLUG}/pages" -f build_type=workflow
  ```
- With `curl` (needs `GITHUB_TOKEN` with `repo` scope):
  ```bash
  REPO_SLUG="owner/repo"  # e.g. myorg/myrepo
  API="https://api.github.com/repos/${REPO_SLUG}/pages"
  curl -fsS -X POST -H "Authorization: Bearer $GITHUB_TOKEN" -H "Accept: application/vnd.github+json" \
    -d '{"build_type":"workflow"}' "$API" || true
  curl -fsS -X PUT  -H "Authorization: Bearer $GITHUB_TOKEN" -H "Accept: application/vnd.github+json" \
    -d '{"build_type":"workflow"}' "$API"
  ```

## Upgrade

To update the bootstrap workflow in an existing project to the latest release (or a specific tag), use:

```bash
bash bootstrap/scripts/update.sh
# or pin a version
BOOTSTRAP_TAG=vX.Y.Z bash bootstrap/scripts/update.sh
```
This updates `bootstrap/scripts/*` (with a local backup) and adds any missing files under `.github/` and `.vscode/` without overwriting your changes.
## Behavior Overview

- Detects package manager: pnpm → yarn → npm.
- Detects docs: Docusaurus, MkDocs, Sphinx; or uses `docs:update` script if present.
- Runs tests only if present: package.json `test` script, or tools like `vitest`, `jest`, `pytest` (soft-skip on no tests), and Go tests (`go.mod` + `*_test.go`).
- Commits, pushes, and manages PRs only if inside a git repo with an `origin` remote and GitHub CLI (`gh`) available.
- Soft-fails by default: missing tools are warnings (unless strict mode is enabled).
- Safe preview: set `ITERATE_DRY_RUN=true` to see actions without changing your repo.

## Preflight & Doctor

Use the doctor to preview what will happen and what’s detected:

```bash
bootstrap/scripts/iterate.sh doctor
```

## Safe Sandbox Runs (no repo changes)

To exercise the iterate workflow without touching this repository, use the sandbox runner. It copies the repo into a temporary directory and runs there.

Quick commands:

```bash
# Doctor-only in sandbox (keeps temp folder for inspection)
bash bootstrap/scripts/sandbox.sh doctor --keep

# Full iterate in sandbox; disables git/PR by default
bash bootstrap/scripts/sandbox.sh iterate --keep

# Allow git in the sandbox (still isolated; no origin remote)
bash bootstrap/scripts/sandbox.sh iterate --enable-git --keep
```

VS Code tasks:
- `sandbox:doctor`: runs doctor in an isolated copy
- `sandbox:iterate`: runs the full loop in an isolated copy with git/PR disabled

Nothing in your working tree is modified by sandbox runs.

If you plan to use MkDocs for docs, install it with:

```bash
chmod +x bootstrap/scripts/install-mkdocs.sh
bash bootstrap/scripts/install-mkdocs.sh
```

## VS Code Tasks

- `iterate`: build → test → docs → git → pr (default build task)
- `iterate:no-git`: build → test → docs (useful for non-git repos)
- `iterate:no-pr`: full iterate but skips PR creation/update
- `iterate:doctor`: runs preflight detection and prints environment/tooling summary
- Subtasks: `iterate:build`, `iterate:test`, `iterate:docs`, `iterate:git`, `iterate:pr`

Run any task via the Command Palette → "Tasks: Run Task".

## Configuration

### Installer Config File (v0.4.1+)

Instead of editing the installer script or exporting many env vars, you can create a `.copilot-bootstrap.conf` file in the target repo BEFORE running the one‑liner. The installer loads it first, then its packaged `installer-defaults.conf`, then applies any environment variable overrides.

Precedence (highest first):
1. Explicit environment variables (`BOOTSTRAP_DEFAULT_*`)
2. Local `.copilot-bootstrap.conf`
3. Release `installer-defaults.conf`
4. Hardcoded fallbacks (only if all above unset)

Example `.copilot-bootstrap.conf`:
```bash
BOOTSTRAP_DEFAULT_PROCEED_INSTALL=Y
BOOTSTRAP_DEFAULT_INIT_GIT=Y
BOOTSTRAP_DEFAULT_CONNECT_GITHUB=Y
BOOTSTRAP_DEFAULT_SETUP_DOCS=Y
BOOTSTRAP_DEFAULT_DOCS_CHOICE=1   # MkDocs
BOOTSTRAP_DEFAULT_INSTALL_MKDOCS=Y
BOOTSTRAP_DEFAULT_COMMIT_DOCS=Y
BOOTSTRAP_DEFAULT_ENABLE_PAGES_NOW=N
BOOTSTRAP_DEFAULT_RUN_DOCTOR_ON_INSTALL=Y
BOOTSTRAP_DEFAULT_BUILD_DOCS_ON_INSTALL=Y
```

Then run (quick streaming form):
```bash
TAG=$(curl -fsSL https://api.github.com/repos/hotbrainco/copilot-bootstrap/releases/latest | awk -F '"' '/tag_name/ {print $4; exit}')
bash -c "$(curl -fsSL https://raw.githubusercontent.com/hotbrainco/copilot-bootstrap/${TAG}/copilot-bootstrap.sh)"
```

Or auditable form:
```bash
curl -fsSL https://raw.githubusercontent.com/hotbrainco/copilot-bootstrap/${TAG}/copilot-bootstrap.sh -o copilot-bootstrap.sh
bash copilot-bootstrap.sh
```

You can keep the config file for future updates; `update.sh` does not overwrite it.

The script supports environment variables and an optional `.iterate.json` file (requires `jq`) to tune behavior.
Default prompt choices can also be controlled via dedicated environment variables without editing the script:

- `BOOTSTRAP_DEFAULT_PROCEED_INSTALL`: Y|N (default Y)
- `BOOTSTRAP_DEFAULT_INIT_GIT`: Y|N (default Y)
- `BOOTSTRAP_DEFAULT_CONNECT_GITHUB`: Y|N (default Y)
- `BOOTSTRAP_DEFAULT_PUSH_INITIAL`: Y|N (default Y)
- `BOOTSTRAP_DEFAULT_SETUP_DOCS`: Y|N (default N)
- `BOOTSTRAP_DEFAULT_DOCS_CHOICE`: 1|2|3|4 (default 1)
- `BOOTSTRAP_DEFAULT_INSTALL_MKDOCS`: Y|N (default Y)
- `BOOTSTRAP_DEFAULT_COMMIT_DOCS`: Y|N (default Y)
 - `BOOTSTRAP_DEFAULT_RUN_DOCTOR_ON_INSTALL`: Y|N (default Y)
 - `BOOTSTRAP_DEFAULT_BUILD_DOCS_ON_INSTALL`: Y|N (default Y)
Behavior notes:
- Docs commit: when docs are created/updated during install, the script auto-commits and pushes them if `DEFAULT_COMMIT_DOCS=Y` (default). Set `BOOTSTRAP_DEFAULT_COMMIT_DOCS=N` to skip auto-commit.
- Pages verification: shows an animated spinner while waiting for the Pages build status and URL reachability check.

FAQ:
- Automatic doctor/docs after setup: the installer runs a quick preflight (doctor) to detect tools and settings, then builds the docs locally (e.g., `mkdocs build`). It doesn’t publish anything; it just validates your docs setup and generates the local `site/` folder. Control via `BOOTSTRAP_DEFAULT_RUN_DOCTOR_ON_INSTALL` and `BOOTSTRAP_DEFAULT_BUILD_DOCS_ON_INSTALL`.
- "🔎 Verifying GitHub Pages deployment and availability": after enabling Pages, the script checks that GitHub’s Pages build has completed and that your public site URL is reachable (HTTP 200/301/302). This confirms your docs are actually live on Pages.
- `BOOTSTRAP_DEFAULT_ENABLE_PAGES_INTERACTIVE`: Y|N (default N)
- `BOOTSTRAP_DEFAULT_ENABLE_PAGES_NOW`: Y|N (default N)
- `BOOTSTRAP_DEFAULT_RUN_DOCS_NOW`: Y|N (default N)
- `BOOTSTRAP_DEFAULT_REPO_VISIBILITY`: public|private (default private)
- `BOOTSTRAP_DEFAULT_VERIFY_PAGES`: Y|N (default Y)

Pages verification and spinner tuning:
- `BOOTSTRAP_PAGES_BUILD_TIMEOUT_SECONDS`: total seconds to wait for GitHub Pages build status (default 240)
- `BOOTSTRAP_PAGES_BUILD_INTERVAL_SECONDS`: seconds between build status polls (default 3)
- `BOOTSTRAP_PAGES_PROBE_TIMEOUT_SECONDS`: total seconds to probe the Pages URL (default 120)
- `BOOTSTRAP_PAGES_PROBE_INTERVAL_SECONDS`: seconds between URL probes (default 2)
- `BOOTSTRAP_SPINNER_DELAY_SECONDS`: delay per spinner frame in seconds (default 0.05)

Non-interactive automation:
- `BOOTSTRAP_INTERACTIVE=false` suppresses all prompts and auto-accepts the configured defaults (use `BOOTSTRAP_DEFAULT_*` vars to shape behavior). When false, docs choice uses `DEFAULT_DOCS_CHOICE` automatically, git init and remote creation proceed without user input.
- `BOOTSTRAP_REMOTE_URL` (optional) a git remote URL to add as `origin` in non-interactive mode instead of creating a repo with `gh repo create`.

Example fully unattended install that initializes git, uses existing remote, skips docs setup:
```bash
TAG=$(curl -fsSL https://api.github.com/repos/hotbrainco/copilot-bootstrap/releases/latest | awk -F '"' '/tag_name/ {print $4; exit}')
BOOTSTRAP_INTERACTIVE=false \
BOOTSTRAP_DEFAULT_INIT_GIT=Y \
BOOTSTRAP_DEFAULT_CONNECT_GITHUB=Y \
BOOTSTRAP_REMOTE_URL=git@github.com:myorg/myapp.git \
BOOTSTRAP_DEFAULT_SETUP_DOCS=N \
bash -c "$(curl -fsSL https://raw.githubusercontent.com/hotbrainco/copilot-bootstrap/${TAG}/copilot-bootstrap.sh)"
```

Example overrides:

```bash
BOOTSTRAP_DEFAULT_SETUP_DOCS=Y \
BOOTSTRAP_DEFAULT_DOCS_CHOICE=1 \
BOOTSTRAP_DEFAULT_INSTALL_MKDOCS=Y \
BOOTSTRAP_DEFAULT_COMMIT_DOCS=Y \
BOOTSTRAP_DEFAULT_RUN_DOCS_NOW=Y \
BOOTSTRAP_DEFAULT_REPO_VISIBILITY=public \
bash copilot-bootstrap.sh
```

Environment variables:

- `ITERATE_COMMIT_PREFIX`: commit message prefix (default `chore:`)
- `ITERATE_PR_TITLE_PREFIX`: PR title prefix (default `chore:`)
- `ITERATE_PR_DRAFT`: `true|false` (default `true`)
- `ITERATE_PR_BASE`: PR base branch (empty = repo default)
- `ITERATE_PR_REVIEWERS`: comma-separated GitHub handles
- `ITERATE_SKIP_DOCS`: `true` to skip docs
- `ITERATE_RUN_TESTS_IF_PRESENT`: `true` to run tests if detected (default `true`)
- `ITERATE_STRICT`: `true` to fail on missing tools (default `false`)
- `ITERATE_STRICT_DOCS`: override docs strictness (default inherits `ITERATE_STRICT`)
- `ITERATE_DRY_RUN`: `true` to print actions without running
- `ITERATE_SKIP_GIT`: `true` to skip commit/push
- `ITERATE_SKIP_PR`: `true` to skip PR creation/update
- `ITERATE_PAGES_ENABLE`: `true` to auto-enable GitHub Pages (Actions) during the docs step (requires `gh` and `origin`)

Optional `.iterate.json` example:

```json
{
  "commitPrefix": "chore:",
  "prTitlePrefix": "chore:",
  "prDraft": "true",
  "prBase": "main",
  "prReviewers": "octocat",
  "skipDocs": "false",
  "runTestsIfPresent": "true",
  "strict": "false",
  "strictDocs": "false",
  "dryRun": "false",
  "skipGit": "false",
  "skipPr": "true"
}
```

## Git & PR Behavior

- If not in a git repo: git and PR steps are skipped.
- If no `origin` remote: push and PR creation are skipped.
- If `gh` is not installed: prints a suggestion to install and skips PR.

Install GitHub CLI: https://cli.github.com/

## Adding to Any Repository

- Copy this folder structure into your repo:
  - `.vscode/` (tasks and settings)
  - `.github/` (prompts and instructions)
  - `bootstrap/scripts/iterate.sh`
  - `ROADMAP.md`
- Make the script executable (macOS/Linux):

```bash
chmod +x bootstrap/scripts/iterate.sh
```

- Open the repo in VS Code and run the `iterate` task.

## Tips for Monorepos

- Provide root `build`, `test`, and `docs:*` scripts that orchestrate subpackages.
- If that’s not possible yet, set `ITERATE_RUN_TESTS_IF_PRESENT=false` to avoid noisy failures.

## Troubleshooting

- Missing tools: enable strict mode to fail explicitly (`ITERATE_STRICT=true`), or install the required tool.
- Unexpected git behavior: ensure you’re on a branch and have `origin` configured.
- PR step errors: verify you’re authenticated with `gh auth login` and have push permissions.

- `iterate:pr` hangs or asks “Where should we push the 'main' branch?”:
  - Why: The PR step ran from `main`/`master`, which makes `gh` ask an interactive question.
  - Fix: Run PRs from a feature branch or skip PRs:
    - Create a branch then iterate:
      ```bash
      git checkout -b iter/$(date +%Y%m%d-%H%M%S)
      bootstrap/scripts/iterate.sh iterate
      ```
    - Or skip PR creation:
      ```bash
      ITERATE_SKIP_PR=true bootstrap/scripts/iterate.sh iterate
      ```
  - Note: The script intentionally skips PRs on `main/master` to avoid interactive prompts. If a VS Code task was started before this behavior, terminate it and re-run.

## Roadmap Workflow

- Use `ROADMAP.md` as the source of truth.
- Keep changes small; update tests and docs alongside code.
- After successful iterations, the script commits and can create/update a draft PR by default.

## Changelog

See `CHANGELOG.md` for a summarized history of releases (notably v0.2.0 which introduced non-interactive mode, Pages verification tuning, and spinner UX improvements). For full diffs use GitHub Releases or compare view.

Maintainers: after drafting a GitHub Release body locally (or copying the release body), you can append it automatically:
```bash
scripts/append-changelog.sh v0.2.1 -
# or pipe:
gh release view v0.2.1 --json body -q .body | scripts/append-changelog.sh v0.2.1 -
git add CHANGELOG.md && git commit -m "docs: update changelog for v0.2.1" && git push
```
