# Changelog
## [v0.3.0] - 2025-09-17
[Compare with v0.2.2](https://github.com/hotbrainco/copilot-bootstrap/compare/v0.2.2...v0.3.0)

### Added
- `cb teardown` command with safeguards (refuses on core repo) and options: `--delete-remote`, `--archive`, `--keep-dir`, `--dry-run`, `--yes`.
- `--archive` + `--keep-dir` options for safe snapshot before removal.
- Test runner: `cb tests` executing scripts in `bootstrap/scripts/tests/`.
- Teardown unit test stub (`test-teardown.sh`).

### Changed
- Dispatcher help now includes teardown/tests.

### Internal
- Documentation updated (README) with new commands.

### Notes
Prepares for broader feature test coverage in future minor versions.

## [v0.2.2] - 2025-09-17
[Compare with v0.2.1](https://github.com/hotbrainco/copilot-bootstrap/compare/v0.2.1...v0.2.2)

Demo body line

## [v0.2.1] - 2025-09-17
Manual dispatch retry body for v0.2.1


All notable changes to this project are documented here. This project follows a pragmatic pre-1.0 SemVer approach: minor version bumps (0.x) group meaningful UX / capability improvements; patch-level tags inside a minor cycle may roll into the next minor summary.

## [0.2.0] - 2025-09-17
### Added
- Non-interactive mode (`BOOTSTRAP_INTERACTIVE=false`) to suppress all prompts
- Remote origin auto-config (`BOOTSTRAP_REMOTE_URL`)
- Dual-phase GitHub Pages verification (build status + HTTP probe)
- Pages and spinner tuning env vars: `BOOTSTRAP_PAGES_*`, `BOOTSTRAP_SPINNER_DELAY_SECONDS`

### Changed
- Automatic doctor + docs build & auto-commit by defaults (removed obsolete prompt)
- Faster spinner with ETA/context labels
- Cleaner, less noisy output; only warn on Pages timeout if both polling & probe fail

### Fixed
- Git/origin setup now runs correctly in non-interactive mode
- Removed misleading Pages timeout when site already reachable

### Internal / Docs
- README: dynamic latest-tag instructions; env var documentation expanded
- Release notes consolidated into this changelog (replaces standalone release notes file)

(Contains rolled-up improvements from 0.1.17–0.1.22.)

## [0.1.22] - 2025-09-17
Fix: ensure git/origin setup logic executes under new non-interactive mode.

## [0.1.21] - 2025-09-17
Feat: introduce non-interactive mode + `BOOTSTRAP_REMOTE_URL` (initial implementation).

## [0.1.20] - 2025-09-17
UI: Faster spinner and ETA hint labels for Pages verification.

## [0.1.19] - 2025-09-17
Enhancement: Pages verification timeouts configurable; suppress misleading timeout message when probe succeeds.

## [0.1.18] - 2025-09-17
Removal: obsolete doctor/docs confirmation prompt; auto-run enabled.

## [0.1.17] - 2025-09-17
Release: baseline for upcoming UX changes (automation groundwork).

## [0.1.16] - 2025-09-17
Maintenance & minor fixes (see GitHub release for diff).

## [0.1.15] - 2025-09-17
Docs & updater improvements; added safety around update flow.

## [0.1.14] - 2025-09-16
Git URL validation; prompt consolidation; virtualenv doc improvements.

## [0.1.13] - 2025-09-16
Fix: commit docs before enabling Pages to avoid missing config in workflow.

## [0.1.12] - 2025-09-15
Refine Pages enable logic; remove redundant installer messages.

## [0.1.11] - 2025-09-15
Robust Pages enable sequence (PUT + POST + PUT) and docs hints.

## [0.1.10] - 2025-09-15
Updater hardening, dry-run mode, safer temp handling.

## [0.1.9] - 2025-09-15
Pages enable fallback improvements; updater reliability tweaks.

## [0.1.8] - 2025-09-15
Pages create (POST) + configure (PUT) sequence.

## [0.1.7] - 2025-09-15
Add updater script; README upgrade section.

## [0.1.6] - 2025-09-15
Guided git/GitHub setup; Pages gating; doctor improvements.

## [0.1.5] - 2025-09-15
Initial public workflow refinement & soft-skip docs behavior.

---
Compare all changes: https://github.com/hotbrainco/copilot-bootstrap/compare/v0.1.5...v0.2.0
