# v0.4.0 Release Notes

## Summary
Improves first-run experience by prompting (default Yes) to add the `cb` dispatcher (bootstrap command wrapper) to the user's PATH, making commands like `cb iterate` immediately available without manual profile edits.

## Highlights
- New installer prompt auto-detects shell profile (`~/.zshrc`, `~/.bashrc` / `~/.bash_profile`, `~/.profile`, or fish config) and appends an export line if accepted.
- Skips if `cb` already resolves to this repo's `bootstrap/scripts/cb` to avoid duplicates.
- Works only in interactive mode; non-interactive runs can still manually append the export line later.
- README updated to describe behavior.

## Added
- PATH integration prompt (`add_cb_to_path_prompt`) in `copilot-bootstrap.sh`.

## Changed
- Documentation: QoL wrapper section now clarifies automatic prompt (v0.4.0+).

## Upgrade Notes
Existing installations can manually add to PATH if desired:
```bash
echo 'export PATH="$(pwd)/bootstrap/scripts:$PATH"' >> ~/.zshrc
source ~/.zshrc
```
(Adjust profile file for your shell.)

## Compare
https://github.com/hotbrainco/copilot-bootstrap/compare/v0.3.0...v0.4.0
