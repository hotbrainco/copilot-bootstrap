#!/usr/bin/env bash
# Copilot Bootstrap Teardown Feature
# Safely tear down the current repository (local directory removal) and optionally
# delete the GitHub remote. Includes multiple safeguards to avoid accidental
# destruction and refuses to act inside the copilot-bootstrap repo itself.
#
# Usage:
#   cb teardown                # interactive local teardown (asks first)
#   cb teardown --yes          # skip first confirmation (still interactive for remote)
#   cb teardown --delete-remote  # offer remote deletion prompt
#   cb teardown --delete-remote --yes
#   cb teardown --dry-run
#
# Flags:
#   --yes / --force       Skip initial local confirmation
#   --delete-remote       Offer remote deletion (requires typing repo name)
#   --dry-run             Show planned actions only
#   --archive             Create a compressed tar archive of repo before removal
#   --keep-dir            Do not delete the directory; only archive (implies no local delete)
#   --help                Show help for this feature
#
# Environment:
#   CB_TEARDOWN_AUTO_REMOTE=1   Implies --delete-remote
#
# Exit codes:
#   0 success / user abort
#   1 misuse or not a repo
#   2 unknown flag
#
set -euo pipefail

cb::teardown::usage() {
  sed -n '1,120p' "$0" | grep -E '^# ' | sed 's/^# //'
}

cb::teardown::main() {
  local YES=false DO_REMOTE=false DRY_RUN=false ARCHIVE=false KEEP_DIR=false
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --yes|--force) YES=true ;;
      --delete-remote) DO_REMOTE=true ;;
      --dry-run) DRY_RUN=true ;;
      --archive) ARCHIVE=true ;;
      --keep-dir) KEEP_DIR=true ;;
      --help|-h) cb::teardown::usage; return 0 ;;
      *) echo "Unknown flag: $1" >&2; return 2 ;;
    esac
    shift || true
  done
  [[ "${CB_TEARDOWN_AUTO_REMOTE:-}" == "1" ]] && DO_REMOTE=true

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Not inside a git repository." >&2
    return 1
  fi

  local REPO_ROOT REPO_NAME OWNER REMOTE_REPO REMOTE_URL
  REPO_ROOT="$(git rev-parse --show-toplevel)"
  REPO_NAME="$(basename "$REPO_ROOT")"

  # Safeguard: never allow teardown of the copilot-bootstrap repo itself.
  if [[ "$REPO_NAME" == "copilot-bootstrap" ]]; then
    echo "Refusing teardown: repository is 'copilot-bootstrap' (protected)." >&2
    return 1
  fi

  if git remote get-url origin >/dev/null 2>&1; then
    REMOTE_URL="$(git remote get-url origin 2>/dev/null || true)"
    if [[ "$REMOTE_URL" =~ github.com[/:]([^/]+)/([^/\.]+)(\.git)?$ ]]; then
      OWNER="${BASH_REMATCH[1]}"; REMOTE_REPO="${BASH_REMATCH[2]}"
    fi
  fi

  echo "=== Teardown: $REPO_NAME ==="
  echo "Repo root: $REPO_ROOT"
  if [[ -n "${OWNER:-}" ]]; then
    echo "Remote:    $OWNER/$REMOTE_REPO"
  else
    echo "Remote:    (none or unsupported host)"
  fi

  if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Warning: Uncommitted changes detected." >&2
  fi

  if ! $YES; then
    read -r -p "Are you sure you want to teardown this repo (local delete)? [y/N]: " ans || true
    [[ "$ans" =~ ^[Yy]$ ]] || { echo "Aborted."; return 0; }
  fi

  local DELETE_REMOTE=false
  if $DO_REMOTE && [[ -n "${OWNER:-}" ]]; then
    echo "Remote deletion is IRREVERSIBLE."
    read -r -p "Also teardown remote? Type '$REPO_NAME' to confirm (or press Enter to skip): " confirm_remote || true
    if [[ "$confirm_remote" == "$REPO_NAME" ]]; then
      DELETE_REMOTE=true
    else
      echo "Skipping remote deletion.";
    fi
  fi

  if $DELETE_REMOTE && ! command -v gh >/dev/null 2>&1; then
    echo "gh CLI not found; cannot delete remote automatically." >&2
    DELETE_REMOTE=false
  fi

  echo
  echo "Plan:"; echo "  Remove local directory: $REPO_ROOT"; echo "  Delete remote: $($DELETE_REMOTE && echo yes || echo no)"; echo "  Archive before delete: $($ARCHIVE && echo yes || echo no)"; echo "  Keep directory: $($KEEP_DIR && echo yes || echo no)"; $DRY_RUN && echo "(dry-run)"
  if $DELETE_REMOTE; then
    echo "Remote delete command: gh repo delete $OWNER/$REMOTE_REPO --yes"
  fi

  $DRY_RUN && { echo "Dry-run complete."; return 0; }

  if $DELETE_REMOTE; then
    if gh repo view "$OWNER/$REMOTE_REPO" >/dev/null 2>&1; then
      echo "Deleting remote $OWNER/$REMOTE_REPO ..."
      gh repo delete "$OWNER/$REMOTE_REPO" --yes || echo "Remote deletion failed (continuing)."
    else
      echo "Remote $OWNER/$REMOTE_REPO not found (skipping)."
    fi
  fi

  local ARCHIVE_PATH="" PARENT TEMP_SCRIPT
  if $ARCHIVE; then
    local ts
    ts="$(date +%Y%m%d-%H%M%S)"
    ARCHIVE_PATH="${REPO_ROOT%/}-archive-${ts}.tar.gz"
    echo "Creating archive $ARCHIVE_PATH ..."
    (cd "$(dirname "$REPO_ROOT")" && tar -czf "$ARCHIVE_PATH" "$(basename "$REPO_ROOT")")
    echo "Archive size: $(du -h "$(dirname "$REPO_ROOT")/$ARCHIVE_PATH" | awk '{print $1}')"
  fi

  $KEEP_DIR && { echo "Keeping directory (no local removal)."; echo "Teardown (partial) finished."; return 0; }

  local PARENT TEMP_SCRIPT
  PARENT="$(dirname "$REPO_ROOT")"
  TEMP_SCRIPT="$(mktemp "${TMPDIR:-/tmp}/cb-teardown-XXXX.sh")"
  cat >"$TEMP_SCRIPT" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
TARGET_DIR="$1"
echo "Removing local directory: $TARGET_DIR"
rm -rf "$TARGET_DIR"
echo "Local teardown complete."
EOS
  chmod +x "$TEMP_SCRIPT"

  echo "Switching to parent and removing..."
  cd "$PARENT"
  "$TEMP_SCRIPT" "$REPO_ROOT"
  rm -f "$TEMP_SCRIPT"

  echo "Teardown finished."
  echo "Recreate fresh repo with:"; echo "  mkdir -p \"$REPO_ROOT\" && cd \"$REPO_ROOT\" && bash -c \"$(curl -fsSL https://raw.githubusercontent.com/hotbrainco/copilot-bootstrap/main/copilot-bootstrap.sh)\""
}

cb::cmd::teardown() { cb::teardown::main "$@"; }
