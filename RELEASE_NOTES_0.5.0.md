# v0.4.1 Release Notes

## Summary
Centralizes installer defaults in a configurable file. Users can now prepare a `.copilot-bootstrap.conf` in the target repository to control all prompt defaults when running the one-liner installer.

## Highlights
- Sourcing order: env vars > `.copilot-bootstrap.conf` > packaged `installer-defaults.conf` > hard fallbacks.
- Removes scattered inline `DEFAULT_*` assignments from the script body, reducing drift.
- README updated with usage examples.

## Migration
No action required for existing users. To customize future installs, drop a `.copilot-bootstrap.conf` in a new repo before running the installer.

Example:
```bash
BOOTSTRAP_DEFAULT_PROCEED_INSTALL=Y
BOOTSTRAP_DEFAULT_INIT_GIT=Y
BOOTSTRAP_DEFAULT_CONNECT_GITHUB=Y
BOOTSTRAP_DEFAULT_SETUP_DOCS=Y
BOOTSTRAP_DEFAULT_DOCS_CHOICE=1
BOOTSTRAP_DEFAULT_INSTALL_MKDOCS=Y
BOOTSTRAP_DEFAULT_COMMIT_DOCS=Y
```

## Compare
https://github.com/hotbrainco/copilot-bootstrap/compare/v0.4.0...v0.4.1
