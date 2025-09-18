#!/usr/bin/env bash
# Changelog automation feature module
# ID: changelog
# Enables toggling the auto-changelog GitHub workflow + Copilot release notes after initial install.

feature_id="changelog"

feature_detect() {
  has_changelog_wf=false
  has_release_wf=false
  has_append_script=false
  has_generator_script=false
  
  [[ -f .github/workflows/update-changelog.yml ]] && has_changelog_wf=true
  [[ -f .github/workflows/auto-release.yml ]] && has_release_wf=true
  [[ -f scripts/append-changelog.sh || -f bootstrap/scripts/append-changelog.sh ]] && has_append_script=true
  [[ -f scripts/generate-release-notes.sh || -f bootstrap/scripts/generate-release-notes.sh ]] && has_generator_script=true
  
  if $has_changelog_wf && $has_release_wf && $has_append_script && $has_generator_script; then
    echo "present"; return 0
  fi
  echo "absent"
}

feature_enable() {
  feature_msg "Enabling changelog automation + Copilot release notes"
  local root changelog_wf_src release_wf_src append_src generator_src
  root="$(pwd)"
  
  # Locate source files (prefer from original packaging)
  [[ -f "$root/.github/workflows/update-changelog.yml" ]] && changelog_wf_src="$root/.github/workflows/update-changelog.yml"
  [[ -f "$root/.github/workflows/auto-release.yml" ]] && release_wf_src="$root/.github/workflows/auto-release.yml"
  
  if [[ -f "$root/scripts/append-changelog.sh" ]]; then
    append_src="$root/scripts/append-changelog.sh"
  elif [[ -f bootstrap/scripts/append-changelog.sh ]]; then
    append_src="bootstrap/scripts/append-changelog.sh"
  fi
  
  if [[ -f "$root/scripts/generate-release-notes.sh" ]]; then
    generator_src="$root/scripts/generate-release-notes.sh"
  elif [[ -f bootstrap/scripts/generate-release-notes.sh ]]; then
    generator_src="bootstrap/scripts/generate-release-notes.sh"
  fi
  
  mkdir -p .github/workflows scripts bootstrap/scripts
  
  # Copy workflow files
  if [[ -n "${changelog_wf_src:-}" ]]; then
    cp "$changelog_wf_src" .github/workflows/update-changelog.yml 2>/dev/null || true
  else
    feature_msg "WARN: update-changelog.yml template not found"
  fi
  
  if [[ -n "${release_wf_src:-}" ]]; then
    cp "$release_wf_src" .github/workflows/auto-release.yml 2>/dev/null || true
  else
    feature_msg "WARN: auto-release.yml template not found"
  fi
  
  # Copy script files
  if [[ -n "${append_src:-}" ]]; then
    cp "$append_src" scripts/append-changelog.sh
    cp "$append_src" bootstrap/scripts/append-changelog.sh 2>/dev/null || true
    chmod +x scripts/append-changelog.sh bootstrap/scripts/append-changelog.sh 2>/dev/null || true
  else
    feature_msg "WARN: append-changelog.sh source not found"
  fi
  
  if [[ -n "${generator_src:-}" ]]; then
    cp "$generator_src" scripts/generate-release-notes.sh
    cp "$generator_src" bootstrap/scripts/generate-release-notes.sh 2>/dev/null || true
    chmod +x scripts/generate-release-notes.sh bootstrap/scripts/generate-release-notes.sh 2>/dev/null || true
  else
    feature_msg "WARN: generate-release-notes.sh source not found"
  fi
  
  feature_msg "Changelog automation + Copilot release notes enabled."
  feature_msg "Flow: Push tag → Draft release with context → Copilot authors notes → Publish → Changelog updated"
}

feature_disable() {
  feature_msg "Disabling changelog automation"
  [[ -f .github/workflows/update-changelog.yml ]] && rm -f .github/workflows/update-changelog.yml
  [[ -f .github/workflows/auto-release.yml ]] && rm -f .github/workflows/auto-release.yml
  feature_msg "Removed workflow files."
}
feature_id="changelog"
