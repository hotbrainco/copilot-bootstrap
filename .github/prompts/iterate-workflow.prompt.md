Title: Iterative build-test-docs-PR loop

You are assisting with an iterative development loop for this repository.

Guidelines:
- Keep code changes minimal and well-explained.
- Always keep documentation in sync with behavior changes.
- Prefer conventional commit styles: feat/fix/chore/docs/test/refactor.

Process:
1) Propose and apply the smallest viable code change(s).
2) Run the VS Code task "iterate".
	- This triggers build, test, docs, commit, push, and PR steps via scripts/iterate.sh.
3) If a step fails:
	- Paste the relevant errors.
	- Propose the smallest targeted fix and apply it.
	- Re-run the "iterate" task.
4) When the iteration is green:
	- Summarize what changed (files, tests, docs).
	- Link to the PR.
	- Ask if we should continue to iterate.

Stack awareness:
- Detect the package manager using lockfiles: pnpm > yarn > npm.
- Detect docs systems: Docusaurus, MkDocs, Sphinx; if none, use the "docs:update" script if present.
- Respect env toggles (e.g., ITERATE_PR_DRAFT, ITERATE_SKIP_DOCS).
