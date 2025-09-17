# Roadmap

Source of truth for what to build next. Keep items small with concrete acceptance criteria.

How to use
- Humans: Edit items below; keep acceptance criteria concise and testable.
- Copilot: Always pick the first item under “Now”, complete it end‑to‑end, then update status/links.

Status buckets
- Now: Highest priority. One small slice at a time.
- Next: Upcoming work, not yet started.
- Later: Nice-to-have or blocked items.
- Done: Completed items with links to PRs.

## Now
- [ ] Add changelog compare links automation
  - Acceptance:
    - [ ] Each new inserted version section includes a GitHub compare link
    - [ ] Script/workflow handles first-release edge case without link
- [ ] Minimal test harness for installer script
  - Acceptance:
    - [ ] CI job runs installer in a temp directory
    - [ ] Verifies non-interactive mode produces expected files & git init
    - [ ] Fails if legacy prompt text reappears

## Next
- [ ] Add a `.code-workspace` file that includes both roots
  - Acceptance:
    - [ ] Workspace lists `copilot-bootstrap/` and `bootstrap-this/` as folders
    - [ ] Default build task runs iteration doctor in each repo
- [ ] CI docs build path (optional mkdocs install) smoke
  - Acceptance:
    - [ ] Job installs mkdocs via provided script
    - [ ] `iterate.sh docs` exits 0
- [ ] Spinner / timeout heuristics revisit
  - Acceptance:
    - [ ] Document recommended env overrides for slow orgs
    - [ ] Add adaptive backoff if Pages API returns 202 repeatedly

## Later
- [ ] Optional: Release notes templating (markdown section ordering)
  - Acceptance:
    - [ ] Script can reorder sections (Added, Fixed, Changed) if present
- [ ] Optional: Detect and warn on missing `GITHUB_TOKEN` before Pages enable attempt
  - Acceptance:
    - [ ] Clear pre-flight message instead of silent skip

## Done
- [x] Choose docs approach (mkdocs optional, simple markdown baseline) — Completed
  - Acceptance:
    - [x] `bootstrap/scripts/iterate.sh docs` soft-skips cleanly without mkdocs
    - [x] Baseline `docs/index.md` present after install
  - Notes: Selected "simple" markdown default; mkdocs path documented via install script.
- [x] Bootstrap sibling repo: `../bootstrap-this/` — Completed
  - Acceptance:
    - [x] Folder `../bootstrap-this/` exists alongside `copilot-bootstrap/` in the parent.
    - [x] Installer run via curl copies workflow files into `../bootstrap-this/`:
      - [x] `bootstrap/scripts/iterate.sh` present and executable
      - [x] `.vscode/` and `.github/` copied to repo root
      - [x] `.iterate.json` and `ROADMAP.md` present
    - [x] `bash bootstrap/scripts/iterate.sh doctor` runs and reports the environment (soft‑skips missing tools).
    - [x] `bash bootstrap/scripts/iterate.sh iterate` completes locally (OK to skip git/PR if not configured).
    - [x] Optional: repo initialized with git and first commit created; remote configured later or via `gh`.
    - [x] Optional: open as a multi‑root workspace including both `copilot-bootstrap/` and `bootstrap-this/`.
  - Notes: Fixed installer bug where literal "leave blank" was set as origin remote instead of validating URL format.
- [x] Harden iteration loop and automation — PR: https://github.com/hotbrainco/copilot-bootstrap/pull/6
  - Acceptance:
    - Docs step soft-skips when MkDocs isn’t installed
    - VS Code exposes an `iterate:doctor` task
    - No-git iteration runs green locally
  - Notes: Fixed merge markers in `bootstrap/scripts/iterate.sh`, added helpers, improved docs flow, and bumped installer default tag to `v0.1.5`.
