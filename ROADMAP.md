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
- [ ] Choose docs approach for `bootstrap-this/` (simple | mkdocs | vitepress | docusaurus) and make `docs` step green
  - Acceptance:
    - [ ] `bootstrap/scripts/iterate.sh docs` succeeds locally
    - [ ] Minimal landing doc in `bootstrap-this/docs/`

## Next
- [ ] Add a `.code-workspace` file that includes both roots
  - Acceptance:
    - [ ] Workspace lists `copilot-bootstrap/` and `bootstrap-this/` as folders
    - [ ] Default build task runs `iterate` in each as appropriate
- [ ] Enable GitHub Pages for `bootstrap-this/` once remote exists
  - Acceptance:
    - [ ] Pages build type set to workflow (via `gh` or API)
    - [ ] Docs deploy from Actions on push to `main`

## Later
- [ ] Enable GitHub Pages for `bootstrap-this/` once remote exists
  - Acceptance:
    - [ ] Pages build type set to workflow (via `gh` or API)
    - [ ] Docs deploy from Actions on push to `main`

## Done
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
