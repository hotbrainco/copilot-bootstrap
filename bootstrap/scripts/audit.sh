#!/usr/bin/env bash
set -euo pipefail

have() { command -v "$1" >/dev/null 2>&1; }

echo "==> Git remote status"
if have git && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git remote -v || true
  echo "==> Fetching remotes (prune)..."
  git fetch --all --prune --quiet || true

  cur_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo HEAD)"
  default_branch="$(git remote show origin 2>/dev/null | sed -n '/HEAD branch/s/.*: //p' || true)"
  base_ref="origin/${default_branch:-main}"
  if git rev-parse --verify -q "$base_ref" >/dev/null; then
    echo "==> Divergence vs $base_ref"
    git rev-list --left-right --count "$base_ref"...HEAD | awk '{print "behind:"$1,"ahead:"$2}'
    echo "==> Diff stat vs $base_ref"
    git diff --stat "$base_ref"...HEAD || true
  else
    echo "No $base_ref found; showing short status instead."
  fi

  echo "==> Short status"
  git status -sb || true

  echo "==> Untracked files (safe preview)"
  git clean -nd || true

  echo "==> Ignored files (safe preview of ignored-only)"
  git clean -ndX || true

  echo "==> Files matched by ignore rules (sample)"
  git status --porcelain=v1 --ignored | sed -n '1,200p' || true

  echo "==> Check for conflict markers"
  if git grep -n "^(<<<<<<<|=======|>>>>>>>)" -E >/dev/null 2>&1; then
    git grep -n "^(<<<<<<<|=======|>>>>>>>)" -E || true
  else
    echo "No conflict markers found"
  fi

  echo "==> Large working-tree files (>5MB)"
  if have find; then
    find . -type f -size +5M -not -path "./.git/*" -print || true
  fi
else
  echo "Not a git repo; skipping git checks."
fi

echo "==> Workflow files present?"
ls -1 .github/workflows 2>/dev/null || echo "No workflows"

echo "==> Key files presence"
for f in .iterate.json mkdocs.yml docs/index.md .vscode/tasks.json bootstrap/scripts/iterate.sh; do
  [[ -e "$f" ]] && echo "OK: $f" || echo "MISSING: $f"
done

echo "==> Suggested .gitignore entries (verify you have these)"
cat <<'EOF'
.venv/
node_modules/
dist/
build/
site/
.DS_Store
*.log
EOF

echo "==> Done. All checks were read-only."
