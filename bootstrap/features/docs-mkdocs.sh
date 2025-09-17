feature_id="docs:mkdocs"

feature_detect() {
  [[ -f mkdocs.yml ]] && echo present || echo absent
}

feature_enable() {
  if [[ -f mkdocs.yml ]]; then
    feature_msg "mkdocs.yml already present"
  else
    cat > mkdocs.yml <<'EOF'
site_name: My Project Docs
nav:
  - Home: index.md
  - Guide: guide.md
theme:
  name: material
plugins:
  - search
EOF
    mkdir -p docs
    [[ -f docs/index.md ]] || echo -e "# Welcome\n\nInitial MkDocs site." > docs/index.md
    [[ -f docs/guide.md ]] || echo -e "# Guide\n\nAdd usage guidance here." > docs/guide.md
    feature_msg "Created mkdocs.yml and docs/ skeleton"
  fi
  feature_msg "Run: bash bootstrap/scripts/install-mkdocs.sh (optional virtualenv)"
}

feature_disable() {
  feature_msg "Non-destructive disable; leaving files. (Use manual removal if desired.)"
}
