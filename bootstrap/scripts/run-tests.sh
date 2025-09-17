#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="$SCRIPT_DIR/tests"

if [[ ! -d "$TEST_DIR" ]]; then
  echo "No tests directory at $TEST_DIR" >&2
  exit 1
fi

failures=0
for t in "$TEST_DIR"/test-*.sh; do
  [[ -f "$t" ]] || continue
  echo "=== RUN $(basename "$t") ==="
  if bash "$t"; then
    echo "--- PASS: $(basename "$t")"
  else
    echo "--- FAIL: $(basename "$t")" >&2
    failures=$((failures+1))
  fi
  echo
done

if [[ $failures -gt 0 ]]; then
  echo "$failures test(s) failed" >&2
  exit 1
fi

echo "All tests passed."