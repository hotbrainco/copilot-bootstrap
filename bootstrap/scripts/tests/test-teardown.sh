#!/usr/bin/env bash
# Basic test stub for cb teardown command (dry-run only to avoid destructive actions)
# Run manually or wire into iterate workflow later.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CB="${SCRIPT_DIR}/../cb"

fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "PASS: $*"; }

# 1. Ensure cb exists
[[ -x "$CB" ]] || fail "cb script not executable"

# 2. Run help to ensure teardown listed
HELP_OUT="$($CB help || true)"
 echo "$HELP_OUT" | grep -q "teardown" || fail "teardown not in help"
pass "help shows teardown"

# 3. Create temporary git repo to simulate environment
TMP_REPO="$(mktemp -d)"
( cd "$TMP_REPO"; git init -q; echo test > file.txt; git add file.txt; git commit -q -m init )

# 4. Run dry-run teardown inside temp repo (skip confirmation)
( cd "$TMP_REPO"; "$CB" teardown --dry-run --yes | grep -q "Dry-run complete." ) || fail "dry-run plan missing"
pass "dry-run executes in temp repo"

# 5. Ensure safeguard triggers in copilot-bootstrap repo
( cd "$SCRIPT_DIR/../.."; "$CB" teardown --dry-run 2>&1 || true ) | grep -qi "Refusing teardown" || fail "safeguard did not trigger for protected repo"
pass "safeguard blocks in copilot-bootstrap repo"

# 6. Cleanup temp
rm -rf "$TMP_REPO"
pass "cleanup complete"

echo "All teardown tests passed."