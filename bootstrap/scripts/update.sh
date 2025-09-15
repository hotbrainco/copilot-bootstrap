#!/usr/bin/env bash
set -euo pipefail

REPO="${BOOTSTRAP_REPO:-hotbrainco/copilot-bootstrap}"

is_tty() { [[ "${BOOTSTRAP_INTERACTIVE:-}" == "true" ]] && return 0; [[ -t 1 || -t 0 ]] && return 0; [[ -r /dev/tty ]]; }
yesno() {
  local prompt="$1" default="${2:-Y}" ans
  local suffix=" [y/N]"
  [[ "$default" == "Y" || "$default" == "y" ]] && suffix=" [Y/n]"
  if [[ -r /dev/tty ]]; then
    read -r -p "$prompt$suffix " ans < /dev/tty || true
  elif [[ -t 0 || -t 1 ]]; then
    read -r -p "$prompt$suffix " ans || true
  else
    ans="$default"
  fi
  ans=${ans:-$default}
  [[ "$ans" == "y" || "$ans" == "Y" ]]
}

fetch_latest_tag() {
  local api="https://api.github.com/repos/${REPO}/releases/latest"
  local tag
  tag=$(curl -fsSL "$api" | awk -F '"' '/tag_name/ {print $4; exit}') || true
  [[ -n "$tag" ]] && echo "$tag" || return 1
}

main() {
  local TAG
  TAG="${BOOTSTRAP_TAG:-}"
  if [[ -z "$TAG" ]]; then
    if ! TAG=$(fetch_latest_tag); then
      echo "Could not determine latest release tag. Set BOOTSTRAP_TAG=vX.Y.Z and retry." >&2
      exit 1
    fi
  fi

  local ZIP_URL="https://github.com/${REPO}/archive/refs/tags/${TAG}.zip"

  echo "Copilot Bootstrap update"
  echo "  Repo: ${REPO}"
  echo "  Target tag: ${TAG}"
  echo "This will update:"
  echo "  - bootstrap/scripts/* (overwrite with backup)"
  echo "  - .github/ and .vscode/ (add missing files only)"
  echo "It will NOT modify: .iterate.json, ROADMAP.md, your app code."
  if is_tty; then
    if ! yesno "Proceed with update?" Y; then
      echo "Aborted. No changes made."
      exit 0
    fi
  fi

  local TMPDIR
  TMPDIR=$(mktemp -d)
  trap 'rm -rf "$TMPDIR"' EXIT

  echo "Downloading ${ZIP_URL}..."
  curl -fsSL "$ZIP_URL" -o "$TMPDIR/cb.zip"
  unzip -q "$TMPDIR/cb.zip" -d "$TMPDIR"
  local TAG_DIR="${TAG#v}"
  local SRC="$TMPDIR/copilot-bootstrap-$TAG_DIR"

  # Backup and update bootstrap/scripts
  if [[ -d ./bootstrap/scripts ]]; then
    local ts
    ts=$(date +%Y%m%d-%H%M%S)
    mkdir -p ./.backup
    cp -R ./bootstrap/scripts "./.backup/bootstrap-scripts-$ts" || true
    echo "Backed up ./bootstrap/scripts -> ./.backup/bootstrap-scripts-$ts"
  fi
  mkdir -p ./bootstrap
  if [[ -d "$SRC/bootstrap/scripts" ]]; then
    rm -rf ./bootstrap/scripts
    cp -R "$SRC/bootstrap/scripts" ./bootstrap/
  else
    rm -rf ./bootstrap/scripts
    cp -R "$SRC/scripts" ./bootstrap/
  fi
  chmod +x ./bootstrap/scripts/*.sh 2>/dev/null || true

  # Non-destructive sync of .github and .vscode (add missing files only)
  if command -v rsync >/dev/null 2>&1; then
    [[ -d "$SRC/.vscode" ]] && rsync -a --ignore-existing "$SRC/.vscode/" ./.vscode/
    [[ -d "$SRC/.github" ]] && rsync -a --ignore-existing "$SRC/.github/" ./.github/
  else
    [[ -d "$SRC/.vscode" ]] && mkdir -p ./.vscode && (cd "$SRC/.vscode" && find . -type f -print0 | xargs -0 -I{} sh -c 'dst="../../.vscode/{}"; [ -e "$dst" ] || (mkdir -p "$(dirname "$dst")" && cp "{}" "$dst")')
    [[ -d "$SRC/.github" ]] && mkdir -p ./.github && (cd "$SRC/.github" && find . -type f -print0 | xargs -0 -I{} sh -c 'dst="../../.github/{}"; [ -e "$dst" ] || (mkdir -p "$(dirname "$dst")" && cp "{}" "$dst")')
  fi

  echo "✅ Update complete. Next steps:"
  echo "  - Review backups under ./.backup/ if needed"
  echo "  - Run: bash bootstrap/scripts/iterate.sh doctor"
}

main "$@"
