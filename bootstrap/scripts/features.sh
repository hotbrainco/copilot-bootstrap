#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FEATURE_DIR="${SCRIPT_DIR%/scripts}/features"
source "${FEATURE_DIR}/_lib.sh"

need() { command -v "$1" >/dev/null 2>&1; }
usage() {
  cat <<EOF
Feature Toggle Manager
Usage:
  features.sh list
  features.sh status <feature-id>
  features.sh enable <feature-id>
  features.sh disable <feature-id>

Examples:
  bash bootstrap/scripts/features.sh list
  bash bootstrap/scripts/features.sh enable docs:mkdocs

Notes:
  - States persisted in .iterate.json (.features map) when jq is installed.
  - Env overrides (ITERATE_SKIP_DOCS, ITERATE_SKIP_PR) still take precedence at runtime.
EOF
}

load_modules() {
  for f in "${FEATURE_DIR}"/*.sh; do
    [[ "$f" == *"_lib.sh" ]] && continue
    # shellcheck source=/dev/null
    source "$f"
    echo "$feature_id"  # print id to collect
  done
}


# Build an in-memory registry: feature_id -> module (sourced already)
ALL_FEATURE_IDS=()
while read -r fid; do
  ALL_FEATURE_IDS+=("$fid")
done < <(load_modules)

find_feature() {
  local id="$1" found="false"
  for f in "${FEATURE_DIR}"/*.sh; do
    [[ "$f" == *"_lib.sh" ]] && continue
    unset feature_id
    # shellcheck source=/dev/null
    source "$f"
    if [[ "$feature_id" == "$id" ]]; then
      # re-source to expose functions
      source "$f"
      found="true";
      break
    fi
  done
  [[ "$found" == "true" ]]
}

pretty_state() {
  local id="$1" config_state real_state symbol
  config_state="$(json_get_feature_state "$id")"
  if find_feature "$id"; then
    if declare -f feature_detect >/dev/null 2>&1; then
      real_state="$(feature_detect)"
    else
      real_state="unknown"
    fi
  else
    real_state="missing"
  fi
  symbol="✖"
  [[ "$config_state" == "enabled" ]] && symbol="✔"
  printf "%s %-16s (config=%s, detect=%s)\n" "$symbol" "$id" "$config_state" "$real_state"
}

cmd="${1:-list}"; shift || true
case "$cmd" in
  list)
    for id in "${ALL_FEATURE_IDS[@]}"; do
      pretty_state "$id"
    done
    ;;
  status)
    [[ $# -ge 1 ]] || { echo "Need feature id" >&2; exit 1; }
    pretty_state "$1"
    ;;
  enable|disable)
    [[ $# -ge 1 ]] || { echo "Need feature id" >&2; exit 1; }
    fid="$1"; shift || true
    if ! find_feature "$fid"; then
      echo "Unknown feature: $fid" >&2; exit 1
    fi
    if [[ "$cmd" == "enable" ]]; then
      if declare -f feature_enable >/dev/null 2>&1; then feature_enable; fi
      json_set_feature_state "$fid" "enabled"
    else
      if declare -f feature_disable >/dev/null 2>&1; then feature_disable; fi
      json_set_feature_state "$fid" "disabled"
    fi
    pretty_state "$fid"
    ;;
  *)
    usage; exit 1;
    ;;
esac
