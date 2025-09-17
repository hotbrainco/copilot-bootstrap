# Common helpers for feature modules
have_cmd() { command -v "$1" >/dev/null 2>&1; }
json_get_feature_state() {
  local name="$1"
  [[ -f .iterate.json ]] || { echo "unknown"; return; }
  if have_cmd jq; then
    jq -r --arg f "$name" '.features[$f] // "unset"' .iterate.json 2>/dev/null || echo "unset"
  else
    echo "(jq missing)"
  fi
}
# Update .iterate.json in-place (requires jq); safe no-op if jq missing
json_set_feature_state() {
  local name="$1" state="$2" tmp
  have_cmd jq || { echo "WARN: jq not installed; cannot persist feature state" >&2; return 0; }
  tmp=".iterate.json.tmp"
  jq --arg f "$name" --arg v "$state" '(.features //= {}) | .features[$f]=$v' .iterate.json > "$tmp" && mv "$tmp" .iterate.json
}
feature_msg() { echo "[feature] $*"; }
