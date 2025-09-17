feature_id="docs:vitepress"

feature_detect() {
  [[ -d docs/.vitepress ]] && echo present || echo absent
}

feature_enable() {
  if [[ -d docs/.vitepress ]]; then
    feature_msg "VitePress already scaffolded"
  else
    mkdir -p docs/.vitepress
    cat > docs/.vitepress/config.js <<'EOF'
export default { title: 'My Project', description: 'Docs' };
EOF
    [[ -f docs/index.md ]] || echo '# Welcome (VitePress)' > docs/index.md
    feature_msg "Scaffolded VitePress config"
  fi
  feature_msg "Add dependency: npm add -D vitepress"
}

feature_disable() { feature_msg "Leaving VitePress files; remove manually if desired."; }
