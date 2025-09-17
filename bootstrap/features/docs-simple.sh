feature_id="docs:simple"

feature_detect() {
  [[ -d docs && -f docs/index.md && ! -f mkdocs.yml ]] && echo present || echo absent
}

feature_enable() {
  if [[ -d docs && -f docs/index.md ]]; then
    feature_msg "docs/ already exists; assuming simple docs present"
  else
    mkdir -p docs
    cat > docs/index.md <<'EOF'
# Simple Docs

Welcome. Add more markdown files here.
EOF
    feature_msg "Created docs/index.md"
  fi
}

feature_disable() { feature_msg "Leaving docs/ intact."; }
