feature_id="docs:docusaurus"

feature_detect() {
  [[ -d docs && -f docs/docusaurus.config.* ]] && echo present || echo absent
}

feature_enable() {
  feature_msg "Use: bash bootstrap/scripts/setup-docs.sh docusaurus (interactive)"
}

feature_disable() { feature_msg "Leaving any generated docs/ alone."; }
