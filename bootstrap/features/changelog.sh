#!/usr/bin/env bash
# Changelog automation feature module
# ID: changelog
# Enables toggling the auto-changelog GitHub workflow after initial install.

feature_id="changelog"

feature_detect() {
  if [[ -f .github/workflows/update-changelog.yml ]]; then
    if [[ -f scripts/append-changelog.sh || -f bootstrap/scripts/append-changelog.sh ]]; then
      echo "present"; return 0
    fi
  fi
  echo "absent"
}

feature_enable() {
  feature_msg "Enabling changelog automation"
  local root script_src wf_src
  root="$(pwd)"
  # Prefer sources from original packaging (when run inside original repo)
  if [[ -f "$root/.github/workflows/update-changelog.yml" ]]; then
    wf_src="$root/.github/workflows/update-changelog.yml"
  fi
  if [[ -f "$root/scripts/append-changelog.sh" ]]; then
    script_src="$root/scripts/append-changelog.sh"
  elif [[ -f bootstrap/scripts/append-changelog.sh ]]; then
    script_src="bootstrap/scripts/append-changelog.sh"
  fi
  mkdir -p .github/workflows scripts bootstrap/scripts
  if [[ -n "${wf_src:-}" ]]; then
    cp "$wf_src" .github/workflows/update-changelog.yml 2>/dev/null || true
  else
    feature_msg "WARN: workflow template not found (update-changelog.yml)"
  fi
  if [[ -n "${script_src:-}" ]]; then
    cp "$script_src" scripts/append-changelog.sh
    cp "$script_src" bootstrap/scripts/append-changelog.sh 2>/dev/null || true
    chmod +x scripts/append-changelog.sh bootstrap/scripts/append-changelog.sh 2>/dev/null || true
  else
    feature_msg "WARN: append-changelog.sh source not found"
  fi
  feature_msg "Changelog automation enabled."
}

feature_disable() {
  feature_msg "Disabling changelog automation"
  if [[ -f .github/workflows/update-changelog.yml ]]; then
    rm -f .github/workflows/update-changelog.yml
    feature_msg "Removed workflow file."
  fi
}
feature_id="changelog"
