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
- [ ] Harden iteration loop and automation
  - Why: Ensure the default "iterate" path is reliable, reducing manual intervention and enabling autonomous runs.
  - Acceptance:
    - [ ] Docs step runs without syntax errors and soft-skips when no docs are present
    - [ ] VS Code exposes an "iterate:doctor" task
    - [ ] A no-git iteration runs green locally
  - Tech notes: Edit `scripts/iterate.sh` (`step_docs`), update `.vscode/tasks.json`. Consider adding CI smoke in a follow-up.

## Next
- [ ] Example: Improve error handling in engine-runner
  - Acceptance:
    - [ ] Return structured error codes
    - [ ] Add integration test covering parity:local failure path

## Later
- [ ] Example: Migrate docs to Docusaurus v3

## Done
- [ ] (autofilled by humans/Copilot when items complete; include PR URL)
