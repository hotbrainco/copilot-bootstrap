#!/usr/bin/env bash
set -euo pipefail
# Simple smoke test: install latest release into a temp dir non-interactively and assert key invariants.
# Intended to run in CI and locally. Requires: curl, tar, awk, git.

REPO_SLUG="hotbrainco/copilot-bootstrap"
WORKDIR=$(mktemp -d 2>/dev/null || mktemp -d -t cbsmoke)
cleanup() { rm -rf "$WORKDIR" || true; }
trap cleanup EXIT INT TERM

echo "==> Using temp dir: $WORKDIR"
cd "$WORKDIR"

latest_tag=$(curl -fsSL "https://api.github.com/repos/${REPO_SLUG}/releases/latest" | awk -F '"' '/tag_name/ {print $4; exit}')
if [[ -z "${latest_tag:-}" ]]; then
  echo "Failed to determine latest tag" >&2
  exit 1
fi

echo "==> Latest tag: $latest_tag"
# Fetch & extract
curl -fsSL "https://github.com/${REPO_SLUG}/archive/refs/tags/${latest_tag}.tar.gz" | tar xz
src_dir="copilot-bootstrap-${latest_tag#v}"
[[ -d "$src_dir" ]] || { echo "Extracted directory missing" >&2; exit 1; }

mv "$src_dir" copilot-bootstrap
cd copilot-bootstrap

# Run installer script (self-bootstrap). For smoke we simulate running the script itself.
# Ensure non-interactive.
BOOTSTRAP_INTERACTIVE=false ./copilot-bootstrap.sh > install.log 2>&1 || {
  echo "Installer failed" >&2
  sed -n '1,200p' install.log >&2
  exit 1
}

# Assertions
failures=0
assert_file() { [[ -f "$1" ]] || { echo "Missing file: $1" >&2; failures=$((failures+1)); }; }
assert_dir() { [[ -d "$1" ]] || { echo "Missing directory: $1" >&2; failures=$((failures+1)); }; }

assert_file copilot-bootstrap.sh
assert_dir bootstrap/scripts
assert_file bootstrap/scripts/iterate.sh
assert_file README.md
assert_file docs/index.md || true  # docs may be minimal

# No legacy prompt text
if grep -q "Run doctor and build docs now" install.log; then
  echo "Found legacy prompt in output" >&2; failures=$((failures+1));
fi
if grep -q "\[y/N\]" install.log; then
  echo "Found interactive y/N prompt in output" >&2; failures=$((failures+1));
fi

# Git repo initialized
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Installer did not initialize git repo" >&2; failures=$((failures+1));
fi

# First commit message sanity
if ! git log --oneline -n1 | grep -qi 'bootstrap' ; then
  echo "Unexpected initial commit message" >&2; failures=$((failures+1));
fi

# Summarize
if [[ $failures -gt 0 ]]; then
  echo "❌ Smoke test failed with $failures issue(s)." >&2
  sed -n '1,120p' install.log >&2 || true
  exit 1
fi

echo "✅ Smoke test passed for ${latest_tag}."
