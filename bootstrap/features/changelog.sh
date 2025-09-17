feature_id="changelog"

feature_detect() { [[ -f scripts/append-changelog.sh ]] && echo present || echo absent; }
feature_enable() { feature_msg "Changelog helper present; usage: scripts/append-changelog.sh <tag> <file|- >"; }
feature_disable() { feature_msg "Leaving helper script; disable is logical only."; }
