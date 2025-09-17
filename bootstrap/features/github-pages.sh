feature_id="github:pages"

feature_detect() {
  # Detect presence of a pages deployment workflow
  if grep -R "deploy-pages@" -n .github/workflows >/dev/null 2>&1; then echo present; else echo absent; fi
}

feature_enable() {
  feature_msg "Pages enablement occurs automatically during docs step if ITERATE_PAGES_ENABLE=true or via API calls."
  feature_msg "To force immediate attempt: ITERATE_PAGES_ENABLE=true bash bootstrap/scripts/iterate.sh docs"
}

feature_disable() { feature_msg "No destructive action; you can remove workflows manually if undesired."; }
