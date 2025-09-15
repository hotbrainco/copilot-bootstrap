#!/usr/bin/env bash
set -Eeuo pipefail

# Cross-platform guidance + best-effort install for MkDocs Material and common plugins.
# Strategy:
# - Prefer pipx for user-scoped, isolated CLI installs.
# - Fall back to pip --user if pipx unavailable.
# - Print clear next-step commands for macOS, Linux (apt/dnf), and Windows (winget/choco) without assuming root.

need() { command -v "$1" >/dev/null 2>&1; }
warn() { echo "WARN: $*" >&2; }
die() { echo "ERROR: $*" >&2; exit 1; }

PKGS=(
  mkdocs-material
  mkdocs-monorepo-plugin
  mkdocs-awesome-pages-plugin
  mkdocs-include-markdown-plugin
  mkdocs-jupyter
  mkdocs-mermaid2
)

print_os_hints() {
  echo ""
  echo "-- OS install hints --"
  case "${OSTYPE:-}" in
    darwin*)
      echo "macOS:"
      echo "  brew install pipx || brew install python"
      echo "  pipx ensurepath"
      ;;
    linux*)
      echo "Linux (Debian/Ubuntu):"
      echo "  sudo apt-get update && sudo apt-get install -y python3-pip pipx || sudo apt-get install -y python3-pip"
      echo "Linux (Fedora):"
      echo "  sudo dnf install -y python3-pip pipx || sudo dnf install -y python3-pip"
      ;;
    msys*|cygwin*|win32*)
      echo "Windows (PowerShell):"
      echo "  winget install --id Python.Python.3  || choco install python"
      echo "  pipx ensurepath (if pipx installed)"
      ;;
    *)
      echo "See https://www.mkdocs.org/user-guide/installation/ for platform specifics."
      ;;
  esac
}

install_with_pipx() {
  if ! need pipx; then
    warn "pipx not found; attempting to install via pip --user."
    return 1
  fi
  pipx ensurepath || true
  # Ensure base material package first, then inject plugins into that venv
  pipx install mkdocs-material || true
  for p in "${PKGS[@]}"; do
    pipx inject mkdocs-material "$p" || true
  done
}

install_with_pip_user() {
  local pip="python3 -m pip"
  if ! need python3; then
    warn "python3 not found. Install Python first."; print_os_hints; return 1
  fi
  $pip install --user --upgrade pip || true
  $pip install --user mkdocs-material || return 1
  $pip install --user "${PKGS[@]}" || true
}

main() {
  echo "Installing MkDocs Material and common plugins..."
  if install_with_pipx; then
    echo "Done via pipx. Restart your shell if commands aren't found."
    exit 0
  fi
  if install_with_pip_user; then
    echo "Done via pip --user. Ensure ~/.local/bin is on PATH."
    exit 0
  fi
  echo "Could not complete installation automatically." >&2
  print_os_hints
  exit 1
}

main "$@"
