#!/usr/bin/env bash
set -euo pipefail
# Smoke test: ensure update-changelog workflow logic & append script behave when CHANGELOG.md is absent.
# Strategy:
# 1. Create a temp repo clone (copy current repo files) excluding existing CHANGELOG.md
# 2. Run append-changelog.sh with a dummy release body; expect it to create CHANGELOG.md
# 3. Re-run with same tag: expect no duplicate insertion (idempotent)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

echo "[smoke] Using temp dir $WORK"
rsync -a --exclude CHANGELOG.md "$ROOT_DIR/" "$WORK/repo" >/dev/null 2>&1 || cp -R "$ROOT_DIR" "$WORK/repo"
cd "$WORK/repo"

TAG="v0.0.test"
BODY=$'### Added\n- Test entry'
printf '%s\n' "$BODY" > body.md

if [[ ! -x scripts/append-changelog.sh ]]; then
  echo "append-changelog.sh not executable" >&2; exit 1
fi

./scripts/append-changelog.sh "$TAG" body.md
[[ -f CHANGELOG.md ]] || { echo "FAIL: CHANGELOG.md not created" >&2; exit 1; }
grep -q "^## \[$TAG\]" CHANGELOG.md || { echo "FAIL: Tag section missing" >&2; head -n50 CHANGELOG.md; exit 1; }

# Re-run should not duplicate
./scripts/append-changelog.sh "$TAG" body.md || true
COUNT=$(grep -c "^## \[$TAG\]" CHANGELOG.md || true)
if [[ "$COUNT" -ne 1 ]]; then
  echo "FAIL: Tag section duplicated ($COUNT occurrences)" >&2; exit 1
fi

echo "[smoke] PASS: missing changelog scenario handled correctly"