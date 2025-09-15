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
- Run it right after install:

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

Pinned version (replace vX.Y.Z with a specific tag):

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

For any docs system, you can also build via the iterate docs step:

```bash
bootstrap/scripts/iterate.sh docs
```

### Publish to GitHub Pages

This repo includes a GitHub Actions workflow at `.github/workflows/docs-pages.yml` that builds MkDocs and deploys to GitHub Pages on pushes to `main`.

One-time setup:
- In your repo settings → Pages, set "Source" = GitHub Actions.
- Push to `main` to trigger a build, or run the workflow manually.

Tip: To auto-enable GitHub Pages via the docs step (when `gh` and `origin` are available), set:

```bash
ITERATE_PAGES_ENABLE=true bootstrap/scripts/iterate.sh docs
```

## Upgrade

To update the bootstrap workflow in an existing project to the latest release (or a specific tag), use:

```bash
bash bootstrap/scripts/update.sh
# or pin a version
BOOTSTRAP_TAG=v0.1.10 bash bootstrap/scripts/update.sh
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

The script supports environment variables and an optional `.iterate.json` file (requires `jq`) to tune behavior.

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
