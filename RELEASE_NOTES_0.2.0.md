# v0.2.0 Release Notes

Date: 2025-09-17

## Overview
v0.2.0 elevates the bootstrap script from an early, mostly-interactive helper to an automation‑friendly, fast, and self‑verifying workflow installer. It focuses on frictionless non‑interactive installs, dependable GitHub Pages enablement & verification, and clearer progress feedback.

No breaking changes. Existing 0.1.x users can upgrade directly (either by re‑running the installer in a fresh repo or pulling in updated scripts via `bootstrap/scripts/update.sh`).

## Highlights
- Non-interactive mode (`BOOTSTRAP_INTERACTIVE=false`) for CI and scripted bootstrap (auto-accept defaults; skips prompts)
- Remote attachment without prompts via `BOOTSTRAP_REMOTE_URL`
- Automatic docs + doctor run & docs auto-commit (removed obsolete prompt)
- Two-phase GitHub Pages verification (build status + HTTP probe) with configurable timeouts
- Faster, configurable spinner with contextual labels and ETA hints
- Suppression of misleading timeout message when site is already live
- Configurable Pages polling & probe intervals/timeouts and spinner delay

## Detailed Changes
### Automation & Non-Interactive
- Added `BOOTSTRAP_INTERACTIVE=false` to disable all TTY prompts while still applying defaults
- Added `BOOTSTRAP_REMOTE_URL` for direct origin configuration (skips `gh repo create` flow)
- Ensured git init & origin setup still execute under non-interactive mode when defaults allow

### Documentation & Doctor Flow
- Removed lingering “Run doctor and build docs now?” prompt; doctor/docs run automatically when enabled by defaults
- Auto-commit newly generated docs when `BOOTSTRAP_DEFAULT_COMMIT_DOCS=Y`
- README clarified dynamic latest tag usage (no stale hard-coded versions)

### GitHub Pages & Verification
- Added dual-phase verification: poll Pages build API then probe the public URL
- Introduced environment knobs:
  - `BOOTSTRAP_PAGES_BUILD_TIMEOUT_SECONDS`
  - `BOOTSTRAP_PAGES_BUILD_INTERVAL_SECONDS`
  - `BOOTSTRAP_PAGES_PROBE_TIMEOUT_SECONDS`
  - `BOOTSTRAP_PAGES_PROBE_INTERVAL_SECONDS`
  - `BOOTSTRAP_SPINNER_DELAY_SECONDS`
- Only prints final timeout warning if both build polling and URL probe fail

### UX & Feedback
- Spinner speed increased (default frame delay 0.05s) and made configurable
- Progress labels now include expected duration hints (“(1–2 min)”, “(a few seconds)”) and clear phase descriptions
- Cleaner output ordering; reduced noise in success paths

### Reliability & Polish
- Graceful handling when `gh` is absent (skips Pages enablement & PR hints)
- Correct default behavior for git/origin setup in both interactive and non-interactive modes
- Consistent fallback when API calls fail (soft warnings, continue install)

## Environment Variable Additions (since early 0.1.x)
- `BOOTSTRAP_INTERACTIVE` (false disables prompts)
- `BOOTSTRAP_REMOTE_URL`
- Pages tuning & spinner: `BOOTSTRAP_PAGES_*`, `BOOTSTRAP_SPINNER_DELAY_SECONDS`

## Upgrade Guidance
Nothing special required:
1. For new repos: use the dynamic latest-tag quick start (no changes vs 0.1.x).
2. For existing repos: run `bash bootstrap/scripts/update.sh` (optionally with `BOOTSTRAP_TAG=v0.2.0`).

## Future Ideas (Post 0.2.0)
- Optional metrics summary (timings) for each phase
- Pluggable docs builder abstraction for custom generators
- Cached detection results to skip redundant preflight in very large repos

---
Thanks for trying Copilot Bootstrap. Feedback welcome via issues / PRs.
