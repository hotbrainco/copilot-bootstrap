# Copilot Bootstrap: Create and Wire Up the Iteration Workflow

You (GitHub Copilot in VS Code) will read this file and perform the setup end-to-end.

Your goals:
1) Create or update all files listed below exactly as provided.
2) If any file exists, merge minimally and explain what changed.
3) Make the script executable (chmod +x scripts/iterate.sh).
4) Detect the project stack (package manager, docs system) and note what you detected.
5) Run the VS Code task "iterate" to validate the loop.
6) If anything fails, propose the smallest fix, apply it, and re-run "iterate" until green.
7) Summarize what changed and provide the PR URL if created.

Safety/confirmation rules:
- Ask before running shell commands, git operations, or creating a PR.
- If GitHub CLI (gh) is not installed, tell the user how to install it and skip PR creation.

What this setup gives the user:
- A repeatable “iterate” loop that: build → test → docs → commit → push → create/view PR.
- Repo-level instructions that tell Copilot to use the loop and to work from ROADMAP.md.
- A reusable Prompt File to attach per-chat for iteration.

Stack detection you should use:
- Package manager: pnpm if pnpm-lock.yaml exists; else yarn if yarn.lock exists; else npm.
- Docs system (in priority order):
  1) Docusaurus if docusaurus.config.js|ts exists or package.json contains "@docusaurus/"
  2) MkDocs if mkdocs.yml|yaml exists
  3) Sphinx if docs/conf.py or docs/source/conf.py exists
  4) Otherwise, if a script "docs:update" exists in package.json, use it; else skip docs with a notice.

After creating files:
- Run: VS Code task "iterate"
- If the task is not found, verify .vscode/tasks.json and scripts/iterate.sh paths, then retry.

Below are the files to create. Write them exactly as shown.

---

## 1) VS Code settings (enable Prompt Files)

```json name=.vscode/settings.json
{
  "chat.promptFiles": true
}
```

---

## 2) VS Code tasks (compound sequence + sub-steps)

```json name=.vscode/tasks.json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "iterate:build",
      "type": "shell",
      "command": "scripts/iterate.sh",
      "args": ["build"],
      "options": {
        "shell": {
          "executable": "bash",
          "args": ["-lc"]
        }
      },
      "problemMatcher": [],
      "presentation": {
        "reveal": "silent",
        "panel": "dedicated",
        "clear": true
      }
    },
    {
      "label": "iterate:test",
      "type": "shell",
      "command": "scripts/iterate.sh",
      "args": ["test"],
      "options": {
        "shell": {
          "executable": "bash",
          "args": ["-lc"]
        }
      },
      "problemMatcher": [],
      "presentation": {
        "reveal": "silent",
        "panel": "dedicated"
      }
    },
    {
      "label": "iterate:docs",
      "type": "shell",
      "command": "scripts/iterate.sh",
      "args": ["docs"],
      "options": {
        "shell": {
          "executable": "bash",
          "args": ["-lc"]
        }
      },
      "problemMatcher": [],
      "presentation": {
        "reveal": "silent",
        "panel": "dedicated"
      }
    },
    {
      "label": "iterate:git",
      "type": "shell",
      "command": "scripts/iterate.sh",
      "args": ["git"],
      "options": {
        "shell": {
          "executable": "bash",
          "args": ["-lc"]
        }
      },
      "problemMatcher": [],
      "presentation": {
        "reveal": "silent",
        "panel": "dedicated"
      }
    },
    {
      "label": "iterate:pr",
      "type": "shell",
      "command": "scripts/iterate.sh",
      "args": ["pr"],
      "options": {
        "shell": {
          "executable": "bash",
          "args": ["-lc"]
        }
      },
      "problemMatcher": [],
      "presentation": {
        "reveal": "silent",
        "panel": "dedicated"
      }
    },
    {
      "label": "iterate",
      "dependsOrder": "sequence",
      "dependsOn": [
        "iterate:build",
        "iterate:test",
        "iterate:docs",
        "iterate:git",
        "iterate:pr"
      ],
      "group": {
        "kind": "build",
        "isDefault": true
      },
      "problemMatcher": []
    }
  ]
}
```

---

## 3) Orchestration script (stack-aware)

```bash name=scripts/iterate.sh
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

# ---------- Helpers ----------
die() { echo "ERROR: $*" >&2; exit 1; }

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

git_has_changes() {
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
    git checkout -b "$new"
    echo "$new"
  else
    echo "$current"
  fi
}

# ---------- Steps ----------
step_build() {
  local pm; pm="$(pm_detect)"
  echo "==> Build using $pm"
  if has_pkg_script "build"; then
    pm_run "$pm" build || die "Build failed"
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
      npm) npm test --silent || npm test;;
      pnpm) pnpm test --silent || pnpm test;;
      yarn) yarn test --silent || yarn test;;
    esac
  elif have_cmd "vitest"; then
    vitest run
  elif have_cmd "jest"; then
    jest --ci
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
      if has_pkg_script "docs:build"; then pm_run "$pm" docs:build
      elif has_pkg_script "build:docs"; then pm_run "$pm" build:docs
      elif has_pkg_script "docs"; then pm_run "$pm" docs
      else pm_exec "$pm" docusaurus build
      fi
      ;;
    mkdocs)
      if have_cmd "mkdocs"; then mkdocs build
      else die "mkdocs not installed. Install with: pip install mkdocs or brew install mkdocs"
      fi
      ;;
    sphinx)
      if have_cmd "sphinx-build"; then
        local src="docs/source"; [[ -f docs/conf.py ]] && src="docs"
        sphinx-build -b html "$src" docs/_build
      else die "sphinx-build not installed. Install with: pip install sphinx"
      fi
      ;;
    none)
      if has_pkg_script "docs:update"; then
        pm_run "$pm" docs:update
      else
        echo "No docs system detected and no 'docs:update' script; skipping docs"
      fi
      ;;
  esac
}

step_git() {
  echo "==> Git commit and push"
  if ! git_has_changes; then
    echo "No changes to commit"; return
  fi

  git add -A

  # Build a conventional-like message from staged changes
  local msg="${ITERATE_COMMIT_PREFIX} update code and docs"
  if have_cmd "git"; then
    local summary
    summary="$(git diff --cached --name-only | sed 's/^/- /')"
    msg+=$'\n\nFiles changed:\n'"$summary"
  fi

  git commit -m "$msg" || true

  local branch; branch="$(ensure_branch)"
  git push -u origin "$branch"
}

step_pr() {
  echo "==> Create or update PR"
  if ! have_cmd "gh"; then
    echo "GitHub CLI (gh) not installed. Install from https://cli.github.com/ and rerun this step."
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
  gh pr view --json url --jq .url || true
}

# ---------- Main ----------
cmd="${1:-help}"
case "$cmd" in
  build) step_build;;
  test) step_test;;
  docs) step_docs;;
  git) step_git;;
  pr) step_pr;;
  all|iterate)
    step_build
    step_test
    step_docs
    step_git
    step_pr
    ;;
  help|*)
    cat <<EOF
Usage: scripts/iterate.sh [build|test|docs|git|pr|iterate]
Environment:
  ITERATE_COMMIT_PREFIX           default "chore:"
  ITERATE_PR_TITLE_PREFIX         default "chore:"
  ITERATE_PR_DRAFT                "true" | "false" (default "true")
  ITERATE_PR_BASE                 e.g. "main" (default gh's default base)
  ITERATE_PR_REVIEWERS            comma-separated handles
  ITERATE_SKIP_DOCS               "true" to skip docs step
  ITERATE_RUN_TESTS_IF_PRESENT    "true" (default) to run tests if detected
EOF
    ;;
esac
```

After writing, make it executable:
- macOS/Linux: run: chmod +x scripts/iterate.sh
- Windows: run the above in Git Bash or WSL.

---

## 4) Copilot Prompt File (attach per chat)

```markdown name=.github/prompts/iterate-workflow.prompt.md
Title: Iterative build-test-docs-PR loop

You are assisting with an iterative development loop for this repository.

Guidelines:
- Keep code changes minimal and well-explained.
- Always keep documentation in sync with behavior changes.
- Prefer conventional commit styles: feat/fix/chore/docs/test/refactor.

Process:
1) Propose and apply the smallest viable code change(s).
2) Run the VS Code task "iterate".
   - This triggers build, test, docs, commit, push, and PR steps via scripts/iterate.sh.
3) If a step fails:
   - Paste the relevant errors.
   - Propose the smallest targeted fix and apply it.
   - Re-run the "iterate" task.
4) When the iteration is green:
   - Summarize what changed (files, tests, docs).
   - Link to the PR.
   - Ask if we should continue to iterate.

Stack awareness:
- Detect the package manager using lockfiles: pnpm > yarn > npm.
- Detect docs systems: Docusaurus, MkDocs, Sphinx; if none, use the "docs:update" script if present.
- Respect env toggles (e.g., ITERATE_PR_DRAFT, ITERATE_SKIP_DOCS).
```

---

## 5) Copilot Repository Instructions (always-on + roadmap-aware)

```markdown name=.github/copilot-instructions.md
Repository custom instructions for GitHub Copilot

Core workflow
- After applying code edits, run the VS Code task "iterate". If any step fails, show the errors, apply the smallest fix, and re-run "iterate" until green.

Roadmap-driven work
- Treat #file:ROADMAP.md as the source of truth for priorities and acceptance criteria.
- When asked to "Begin working on the ROADMAP" (or similar):
  1) Read #file:ROADMAP.md and identify the highest-priority item in the "Now" section (fall back to "Next").
  2) Propose a short plan for the first small, end-to-end change (1–2 sentences). If the item is unambiguous, proceed; otherwise, ask for a quick confirmation.
  3) Create or use a branch named roadmap/<short-slug>.
  4) Make minimal, well-scoped changes; keep tests and docs in sync.
  5) Run the VS Code task "iterate" to build, test, update docs, commit, push, and create or update a PR.
  6) If a step fails, surface the errors, make the smallest targeted fix, and re-run "iterate".
  7) Update #file:ROADMAP.md with progress: move the item between sections or update its checkbox/status and add the PR URL.
  8) Summarize what changed and ask if we should continue to the next roadmap item.

Conventions
- Keep diffs small and focused. Prefer conventional commits (feat/fix/chore/docs/test/refactor).
- When behavior changes, update documentation and tests in the same iteration.
- Prefer using GitHub CLI (gh) for PR actions. If gh is not installed, explain how to install it (https://cli.github.com/) or use the IDE’s PR flow.
- Respect repository conventions in #file:CONTRIBUTING.md, #file:README.md, and any files in .github/ when present.

Notes
- If the "iterate" task is missing, check this bootstrap file and offer to (re)create .vscode/tasks.json and scripts/iterate.sh.
- If #file:ROADMAP.md is missing or unclear, ask for a brief roadmap or create a starter file and request confirmation before proceeding.
```

---

## 6) Project roadmap (starter)

```markdown name=ROADMAP.md
# Roadmap

This file is the source of truth for what to build next. Copilot and humans should both use it.

How to use
- Humans: Edit items below. Keep acceptance criteria concise and concrete.
- Copilot: Pick the top item under “Now” (or the first in “Next” if “Now” is empty). Work in small, end-to-end increments and update this file with status and PR links.

Status buckets
- Now: Highest priority. Take one small slice at a time.
- Next: Upcoming work, not yet started.
- Later: Nice-to-have or blocked items.
- Done: Completed items with links to PRs.

## Now
- [ ] Feature/Task: Short, imperative title
  - Why: One sentence on value/impact
  - Acceptance:
    - [ ] Criterion 1
    - [ ] Criterion 2
  - Tech notes: Key constraints, file pointers, or follow-ups (optional)
  - Tests: What should be covered by tests (optional)

## Next
- [ ] Example: Improve error handling in engine-runner
  - Acceptance:
    - [ ] Return structured error codes
    - [ ] Add integration test covering parity:local failure path

## Later
- [ ] Example: Migrate docs to Docusaurus v3

## Done
- [ ] (autofilled by humans/Copilot when items complete; include PR URL)
```

---

## Final steps for Copilot (run these now)

1) Make scripts/iterate.sh executable:
   - macOS/Linux: run: chmod +x scripts/iterate.sh
   - Windows: run the above in Git Bash or WSL.

2) Detect the stack (package manager, docs system) and report what you found.

3) Run the VS Code task "iterate".
   - If a step fails, show errors, apply the smallest fix, and re-run until green.

4) Offer to create a PR (draft by default). If gh is unavailable, show install instructions: https://cli.github.com/

5) Summarize:
   - Files created/updated
   - Detected stack
   - Task result (pass/fail) and PR URL if created
   - Next suggested iteration