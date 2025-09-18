Repository custom instructions for GitHub Copilot

Core workflow
- After applying code edits, run the VS Code task "iterate". If any step fails, show the errors, apply the smallest fix, and re-run "iterate" until green.

Roadmap-driven work
- Treat #file:ROADMAP.md as the source of truth for priorities and acceptance criteria.
- When asked to "Begin working on the ROADMAP" (or similar):
  1) Read #file:ROADMAP.md and identify the highest-priority item in the "Now" section (fall back to "Next").
  2) Propose a short plan for the first small, end-to-end change (1–2 sentences). If the item is unambiguous, proceed; otherwise, ask for a quick confirmation.
  3) Create or use a branch named roadmap/<short-slug>.
  4) Make minimal, well-scoped changes; keep tests and docs in sync.
  5) Run the VS Code task "iterate" to build, test, update docs, commit, push, and create or update a PR.
  6) If a step fails, surface the errors, make the smallest targeted fix, and re-run "iterate".
  7) Update #file:ROADMAP.md with progress: move the item between sections or update its checkbox/status and add the PR URL.
  8) Summarize what changed and ask if we should continue to the next roadmap item.

Conventions
- Keep diffs small and focused. Prefer conventional commits (feat/fix/chore/docs/test/refactor).
- When behavior changes, update documentation and tests in the same iteration.
- Prefer using GitHub CLI (gh) for PR actions. If gh is not installed, explain how to install it (https://cli.github.com/) or use the IDE’s PR flow.
- Respect repository conventions in #file:CONTRIBUTING.md, #file:README.md, and any files in .github/ when present.

Release Workflow
- To create a release, first write release notes in `.github/RELEASE_NOTES.md` (this file is git-ignored and temporary).
- Include comprehensive release notes with sections like "New Features", "Bug Fixes", "Breaking Changes", etc.
- Push a semantic version tag (e.g., `git tag v0.6.3 && git push origin v0.6.3`).
- The pre-push hook validates that the release notes file exists and has content before allowing the push.
- The automated workflow publishes the release using the notes and automatically updates `CHANGELOG.md`.
- The release notes file is automatically deleted after successful release to prevent stale content.
- Never edit `CHANGELOG.md` directly - it is managed by automation.

Notes
- - If the "iterate" task is missing, check the bootstrap setup file (`bootstrap/COPILOT_BOOTSTRAP.md`) and offer to (re)create .vscode/tasks.json and bootstrap/scripts/iterate.sh.
- If #file:ROADMAP.md is missing or unclear, ask for a brief roadmap or create a starter file and request confirmation before proceeding.

Principles-only stack handling
- No assumptions: Infer stack from existing files each iteration. If ambiguous, ask once, then proceed. Do not persist a stack choice in the repo unless explicitly requested.
- Ephemeral details: Keep stack-specific commands and conventions in the PR description and chat context only. Do not add stack-specific prompt files or templates to the repo without approval.
- Late binding + safety: Prefer generic commands. Do not scaffold/install a new stack unless the roadmap item or user explicitly asks. Never mix package managers or toolchains.
- Detection discipline: If multiple conflicting signals are found (e.g., both pnpm and yarn lockfiles), stop and ask which to use. Default to soft-skip over guessing installs.
- Drift control: Record current working assumptions in the PR body. If they change, update the PR. Do not create or modify stack-specific config files unless directed.