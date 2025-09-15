# Roadmap

This file is the source of truth for what to build next. Copilot and humans should both use it.

How to use
- Humans: Edit items below. Keep acceptance criteria concise and concrete.
- Copilot: Pick the top item under “Now” (or the first in “Next” if “Now” is empty). Work in small, end-to-end increments and update this file with status and PR links.

Status buckets
- Now: Highest priority. Take one small slice at a time.
- Next: Upcoming work, not yet started.
- Later: Nice-to-have or blocked items.
- Done: Completed items with links to PRs.

## Now
// (empty — pick from Next)

## Next
- [ ] Example: Improve error handling in engine-runner
  - Acceptance:
    - [ ] Return structured error codes
    - [ ] Add integration test covering parity:local failure path

## Later
- [ ] Example: Migrate docs to Docusaurus v3

## Done
- [x] Harden iteration loop and automation — PR: https://github.com/hotbrainco/copilot-bootstrap/pull/6
  - Acceptance:
    - Docs step soft-skips when MkDocs isn’t installed
    - VS Code exposes an `iterate:doctor` task
    - No-git iteration runs green locally
  - Notes: Fixed merge markers in `bootstrap/scripts/iterate.sh`, added helpers, improved docs flow, and bumped installer default tag to `v0.1.5`.
