#!/usr/bin/env bash
set -Eeuo pipefail

# Setup documentation alternatives that don't require Python.
# Options: VitePress (Node.js), Docusaurus (Node.js), or simple markdown with GitHub Pages.

need() { command -v "$1" >/dev/null 2>&1; }
warn() { echo "WARN: $*" >&2; }
die() { echo "ERROR: $*" >&2; exit 1; }

print_usage() {
  cat <<EOF
Usage: bootstrap/scripts/setup-docs.sh [vitepress|docusaurus|simple]

Options:
  vitepress   - Vue-based static site generator (requires Node.js)
  docusaurus  - React-based documentation platform (requires Node.js)
  simple      - Basic markdown with GitHub Pages (no dependencies)

Examples:
  bash bootstrap/scripts/setup-docs.sh vitepress
  bash bootstrap/scripts/setup-docs.sh simple
EOF
}

detect_package_manager() {
  if [[ -f pnpm-lock.yaml ]]; then echo "pnpm"; return; fi
  if [[ -f yarn.lock ]]; then echo "yarn"; return; fi
  echo "npm"
}

setup_vitepress() {
  if ! need node; then
    echo "❌ Node.js not found. Install Node.js first: https://nodejs.org/"
    exit 1
  fi

  local pm
  pm=$(detect_package_manager)
  
  echo "📚 Setting up VitePress documentation..."
  
  # Create docs directory and basic config
  mkdir -p docs
  
  # Create VitePress config
  cat > docs/.vitepress/config.js <<EOF
export default {
  title: 'My Project',
  description: 'Documentation for my project',
  themeConfig: {
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Guide', link: '/guide' }
    ],
    sidebar: [
      {
        text: 'Introduction',
        items: [
          { text: 'Getting Started', link: '/guide' }
        ]
      }
    ]
  }
}
EOF

  # Create index page
  cat > docs/index.md <<EOF
# Welcome

This is the documentation for my project.

## Quick Start

Get started with our [guide](./guide.md).
EOF

  # Create guide page
  cat > docs/guide.md <<EOF
# Getting Started

This guide will help you get started with the project.

## Installation

\`\`\`bash
# Install dependencies
npm install
\`\`\`

## Usage

Basic usage instructions go here.
EOF

  # Add package.json scripts if package.json exists
  if [[ -f package.json ]]; then
    echo "📦 Adding VitePress scripts to package.json..."
    # This would require jq for proper JSON manipulation
    echo "Add these scripts to your package.json:"
    echo '  "docs:dev": "vitepress dev docs",'
    echo '  "docs:build": "vitepress build docs",'
    echo '  "docs:preview": "vitepress preview docs"'
  fi

  echo "✅ VitePress setup complete!"
  echo ""
  echo "📋 Next steps:"
  echo "  # Install VitePress:"
  echo "  $pm add -D vitepress"
  echo ""
  echo "  # Start dev server:"
  echo "  npx vitepress dev docs"
}

setup_docusaurus() {
  if ! need node; then
    echo "❌ Node.js not found. Install Node.js first: https://nodejs.org/"
    exit 1
  fi

  local pm
  pm=$(detect_package_manager)
  
  echo "📚 Setting up Docusaurus documentation..."
  
  if need npx; then
    npx create-docusaurus@latest docs classic --typescript
    echo "✅ Docusaurus setup complete!"
    echo ""
    echo "📋 Next steps:"
    echo "  cd docs && $pm start"
  else
    echo "❌ npx not found. Please install Node.js with npm."
    exit 1
  fi
}

setup_simple() {
  echo "📚 Setting up simple markdown documentation..."
  
  # Create docs directory
  mkdir -p docs
  
  # Create index page
  cat > docs/index.md <<EOF
# My Project Documentation

Welcome to the documentation for my project.

## Table of Contents

- [Getting Started](getting-started.md)
- [API Reference](api.md)
- [Contributing](contributing.md)

## Quick Links

- [GitHub Repository](#)
- [Issues](#)
- [Releases](#)
EOF

  # Create getting started guide
  cat > docs/getting-started.md <<EOF
# Getting Started

This guide will help you get started with the project.

## Prerequisites

List any prerequisites here.

## Installation

\`\`\`bash
# Installation commands
git clone <repository-url>
cd <project-name>
\`\`\`

## Basic Usage

Basic usage instructions go here.

## Next Steps

- Check out the [API Reference](api.md)
- Learn about [Contributing](contributing.md)
EOF

  # Create API reference
  cat > docs/api.md <<EOF
# API Reference

Documentation for the project's API.

## Overview

Brief overview of the API.

## Endpoints

### Example Endpoint

\`\`\`
GET /api/example
\`\`\`

Description of the endpoint.
EOF

  # Create contributing guide
  cat > docs/contributing.md <<EOF
# Contributing

Thank you for your interest in contributing to this project!

## Development Setup

1. Fork the repository
2. Clone your fork
3. Create a feature branch
4. Make your changes
5. Submit a pull request

## Guidelines

- Follow existing code style
- Add tests for new features
- Update documentation as needed
EOF

  # Create GitHub Pages workflow
  mkdir -p .github/workflows
  cat > .github/workflows/docs.yml <<EOF
name: Deploy Documentation

on:
  push:
    branches: [ main ]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: true

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: \${{ steps.deployment.outputs.page_url }}
    steps:
      - uses: actions/checkout@v4
      - name: Setup Pages
        uses: actions/configure-pages@v4
      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: docs
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
EOF

  echo "✅ Simple markdown documentation setup complete!"
  echo ""
  echo "📋 Your documentation files:"
  echo "  docs/index.md"
  echo "  docs/getting-started.md" 
  echo "  docs/api.md"
  echo "  docs/contributing.md"
  echo ""
  echo "🚀 GitHub Pages workflow created at .github/workflows/docs.yml"
  echo ""
  echo "💡 Enable GitHub Pages in your repository settings:"
  echo "   Settings → Pages → Source: GitHub Actions"
}

main() {
  local option="${1:-}"
  
  case "$option" in
    vitepress)
      setup_vitepress
      ;;
    docusaurus)
      setup_docusaurus
      ;;
    simple)
      setup_simple
      ;;
    -h|--help|help)
      print_usage
      ;;
    "")
      echo "❌ Please specify a documentation option."
      echo ""
      print_usage
      exit 1
      ;;
    *)
      echo "❌ Unknown option: $option"
      echo ""
      print_usage
      exit 1
      ;;
  esac
}

main "$@"