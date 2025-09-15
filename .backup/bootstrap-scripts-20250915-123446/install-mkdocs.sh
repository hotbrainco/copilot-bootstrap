#!/usr/bin/env bash
set -Eeuo pipefail

# Install MkDocs Material in a local virtual environment.
# Strategy:
# 1. Create .venv in current directory
# 2. Install MkDocs Material + essential plugins
# 3. Create requirements.txt for reproducibility
# 4. Provide activation commands

need() { command -v "$1" >/dev/null 2>&1; }
warn() { echo "WARN: $*" >&2; }
die() { echo "ERROR: $*" >&2; exit 1; }

VENV_DIR=".venv"
REQUIREMENTS_FILE="requirements.txt"

# Essential MkDocs packages (keeping it minimal to avoid pipx issues)
PKGS=(
  "mkdocs-material>=9.0.0"
  "mkdocs-awesome-pages-plugin"
  "mkdocs-include-markdown-plugin"
)

print_os_hints() {
  echo ""
  echo "-- Python install hints --"
  case "${OSTYPE:-}" in
    darwin*)
      echo "macOS: brew install python"
      ;;
    linux*)
      echo "Linux (Debian/Ubuntu): sudo apt-get install python3 python3-venv python3-pip"
      echo "Linux (Fedora): sudo dnf install python3 python3-pip"
      ;;
    msys*|cygwin*|win32*)
      echo "Windows: winget install --id Python.Python.3"
      ;;
    *)
      echo "See https://www.python.org/downloads/ for platform-specific installers."
      ;;
  esac
}

create_requirements() {
  cat > "$REQUIREMENTS_FILE" <<EOF
# MkDocs Material and essential plugins
# Install with: pip install -r requirements.txt
mkdocs-material>=9.0.0
mkdocs-awesome-pages-plugin
mkdocs-include-markdown-plugin

# Optional plugins (uncomment as needed):
# mkdocs-monorepo-plugin
# mkdocs-jupyter
# mkdocs-mermaid2-plugin
EOF
  echo "📝 Created $REQUIREMENTS_FILE"
}

main() {
  if ! need python3; then
    echo "❌ Python 3 not found. Install Python first."
    print_os_hints
    exit 1
  fi

  echo "🐍 Setting up MkDocs in local virtual environment..."
  
  # Create virtual environment
  if [[ ! -d "$VENV_DIR" ]]; then
    python3 -m venv "$VENV_DIR" || die "Failed to create virtual environment"
    echo "✅ Created virtual environment: $VENV_DIR"
  else
    echo "📁 Using existing virtual environment: $VENV_DIR"
  fi

  # Activate and install packages
  source "$VENV_DIR/bin/activate" || die "Failed to activate virtual environment"
  
  echo "📦 Installing MkDocs Material..."
  pip install --upgrade pip
  pip install "${PKGS[@]}" || die "Failed to install MkDocs packages"
  
  # Create requirements.txt
  create_requirements
  
  echo ""
  echo "✅ MkDocs installation complete!"
  echo ""
  echo "📋 Next steps:"
  echo "  # Activate the environment:"
  echo "  source $VENV_DIR/bin/activate"
  echo ""
  echo "  # Start the dev server:"
  echo "  mkdocs serve"
  echo ""
  echo "  # Build the site:"
  echo "  mkdocs build"
  echo ""
  echo "  # Deactivate when done:"
  echo "  deactivate"
  echo ""
  echo "💡 Tip: Add '$VENV_DIR/' to your .gitignore"
  
  # Check if .gitignore exists and add venv if needed
  if [[ -f .gitignore ]]; then
    if ! grep -q "^\.venv/$" .gitignore 2>/dev/null; then
      echo ".venv/" >> .gitignore
      echo "📝 Added .venv/ to .gitignore"
    fi
  else
    echo ".venv/" > .gitignore
    echo "📝 Created .gitignore with .venv/"
  fi
}

main "$@"
