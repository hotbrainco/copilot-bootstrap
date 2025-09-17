feature_id="update:script"

feature_detect() { [[ -f bootstrap/scripts/update.sh ]] && echo present || echo absent; }
feature_enable() { feature_msg "Update script already present; run: bash bootstrap/scripts/update.sh"; }
feature_disable() { feature_msg "Leaving update.sh; logical disable only."; }
