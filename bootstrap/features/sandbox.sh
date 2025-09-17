feature_id="sandbox"

feature_detect() { [[ -f bootstrap/scripts/sandbox.sh ]] && echo present || echo absent; }
feature_enable() { feature_msg "Sandbox already distributed with bootstrap; nothing to do."; }
feature_disable() { feature_msg "Not disabling core script; treat as always available."; }
