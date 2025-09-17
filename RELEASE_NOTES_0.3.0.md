# Release Notes v0.3.0

## Highlights
- New safety-focused `cb teardown` command for rapidly resetting test repositories without risking the core `copilot-bootstrap` repo.
- Optional archival flow (`--archive`, `--keep-dir`) to preserve state before destructive operations.
- Lightweight internal test runner `cb tests` plus first test stub.

## New Commands
| Command | Description |
|---------|-------------|
| `cb teardown` | Interactive teardown of current repo (with remote delete prompt) |
| `cb tests` | Runs shell test scripts in `bootstrap/scripts/tests/` |

### Teardown Options
- `--dry-run` – show plan only
- `--yes` / `--force` – skip initial confirmation
- `--delete-remote` – prompt to delete remote (requires typing repo name)
- `--archive` – create `repo-archive-<timestamp>.tar.gz` before removal
- `--keep-dir` – only archive; leave directory in place

## Safety
- Refuses to run in `copilot-bootstrap` repository (protection)
- Remote deletion requires exact repo name entry

## Documentation
- README updated with new usage examples.

## Internal
- Added `test-teardown.sh` as a pattern for future tests.

## Upgrade
Existing users can update via:
```bash
bash bootstrap/scripts/update.sh
```

Then add the new `cb` to PATH if not already done.

## Compare
Full diff: https://github.com/hotbrainco/copilot-bootstrap/compare/v0.2.2...v0.3.0
