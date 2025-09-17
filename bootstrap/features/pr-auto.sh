feature_id="pr:auto"

feature_detect() {
  # Always intangible; status derived from config state
  echo virtual
}

feature_enable() { feature_msg "PR auto-step will run when iterate executes."; }
feature_disable() { feature_msg "PR auto-step will be skipped unless explicitly invoked."; }
