#!/usr/bin/env bash
set -Eeuo pipefail

# A safe sandbox runner to test the iterate workflow without touching your repo.
# - Copies the current repo into a temp dir
# - Initializes a throwaway git repo
# - Runs iterate with git/PR disabled by default
# - Cleans up on exit unless --keep is passed

usage() {
  cat <<EOF
Usage: bootstrap/scripts/sandbox.sh [doctor|iterate] [--keep] [--enable-git]

Options:
  doctor         Run only the doctor step in the sandbox
  iterate        Run the full iterate loop in the sandbox (default)
  --keep         Keep the sandbox directory for inspection (prints path)
  --enable-git   Allow commit/push/PR inside the sandbox (still isolated)

By default, this runs docs/build/test only (no git/PR) in an isolated copy.
EOF
}

KEEP="false"
ENABLE_GIT="false"
CMD="iterate"

ARGS=("$@")
NEW_ARGS=()
for arg in "${ARGS[@]}"; do
  case "$arg" in
    doctor) CMD="doctor" ;;
    iterate) CMD="iterate" ;;
    --keep) KEEP="true" ;;
    --enable-git) ENABLE_GIT="true" ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $arg" >&2; usage; exit 2 ;;
  esac
  shift || true

done

ROOT_DIR="$(pwd)"
SANDBOX="$(mktemp -d)"
cleanup() {
  if [[ "$KEEP" != "true" ]]; then
    rm -rf "$SANDBOX" || true
  fi
}
trap cleanup EXIT

# Copy workspace into sandbox (excluding common junk)
rsync -a --exclude ".git" --exclude "node_modules" --exclude ".venv" --exclude "venv" \
  --exclude "site" --exclude "dist" --exclude "build" ./ "$SANDBOX/"

cd "$SANDBOX"

# Initialize an isolated git repo to allow script behavior that expects git
if command -v git >/dev/null 2>&1; then
  git init -q
  git config user.name sandbox
  git config user.email sandbox@example.com
  git add -A || true
  git commit -m "sandbox: initial" -q || true
fi

# Default: disable git/PR to avoid any network calls
if [[ "$ENABLE_GIT" != "true" ]]; then
  export ITERATE_SKIP_GIT="true"
  export ITERATE_SKIP_PR="true"
fi

# Always safe: never enable strict by default here
export ITERATE_STRICT=${ITERATE_STRICT:-false}
export ITERATE_STRICT_DOCS=${ITERATE_STRICT_DOCS:-false}

if [[ "$CMD" == "doctor" ]]; then
  bootstrap/scripts/iterate.sh doctor
else
  bootstrap/scripts/iterate.sh doctor || true
  bootstrap/scripts/iterate.sh iterate
fi

if [[ "$KEEP" == "true" ]]; then
  echo "Sandbox kept at: $SANDBOX"
else
  echo "Sandbox completed (temp cleaned)."
fi
