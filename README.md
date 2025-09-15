# Iteration Workflow Starter

## 1. Copy `copilot-bootstrap.sh` into your new app folder.
2. Run this in VS Code's terminal:
  ```bash
  bash copilot-bootstrap.sh
  ```

Run this from the root of your app’s repository (new or existing). This copies only the needed files into your repo.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/hotbrainco/copilot-bootstrap/v0.1.3/copilot-bootstrap.sh)"
```

No pipe-to-shell alternative:

```bash
curl -fsSL https://raw.githubusercontent.com/hotbrainco/copilot-bootstrap/v0.1.3/copilot-bootstrap.sh -o copilot-bootstrap.sh
bash copilot-bootstrap.sh
```

Tip: To force interactive prompts (even when piping), set `BOOTSTRAP_INTERACTIVE=true`:

```bash
BOOTSTRAP_INTERACTIVE=true bash -c "$(curl -fsSL https://raw.githubusercontent.com/hotbrainco/copilot-bootstrap/v0.1.3/copilot-bootstrap.sh)"
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

## Optional: Docs Starter (MkDocs)

This repo includes an optional MkDocs starter (`mkdocs.yml` + `docs/index.md`). If you want a documentation site:

```bash
chmod +x bootstrap/scripts/install-mkdocs.sh
bash bootstrap/scripts/install-mkdocs.sh
mkdocs serve
```

Or build via the iterate docs step:

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

The preflight runs automatically when you use `iterate`.

You can also run it via VS Code task: `iterate:doctor`.

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

## Roadmap Workflow

- Use `ROADMAP.md` as the source of truth.
- Keep changes small; update tests and docs alongside code.
- After successful iterations, the script commits and can create/update a draft PR by default.
