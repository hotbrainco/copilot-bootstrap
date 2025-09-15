# Contributing Guide

This repo prefers small, focused PRs with a squash-merge strategy. To avoid local conflicts after merging, use the workflow below.

## Recommended Git Workflow

- Always branch from a fresh `origin/main`:
  ```bash
  git switch main
  git pull --ff-only
  git switch -c iter/$(date +%Y%m%d-%H%M%S)
  ```

- After a squash-merge on GitHub, reset your local `main` to the remote instead of rebasing old commits:
  ```bash
  git switch main
  git fetch origin
  git reset --hard origin/main
  ```

- Rebase feature branches onto `origin/main` (not the other way around):
  ```bash
  git switch your-branch
  git fetch origin
  git rebase origin/main
  ```

- Prefer fast-forward pulls to avoid accidental merge commits:
  ```bash
  git config --global pull.ff only
  ```

- Clean up merged branches:
  ```bash
  git fetch -p
  git branch -d <merged-branch>
  ```

- Speed up repeated conflict resolutions (optional):
  ```bash
  git config --global rerere.enabled true
  ```

## Conflict Markers

CI will fail if conflict markers (<<<<<<<, =======, >>>>>>>) are present in the tree. Resolve conflicts locally before pushing.

## Iteration Tasks

See `README.md` for the iterate workflow and VS Code tasks to build, test, docs, commit, push, and PR.