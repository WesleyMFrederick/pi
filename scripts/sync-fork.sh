#!/bin/bash
# sync-fork.sh — fork sync + rebuild: upstream → origin/main → local main → feature branch → build.
#
# Model: `main` mirrors the canonical (upstream) repo everywhere (origin + local).
# Your customizations live on a feature branch (default: explore). This script pulls
# canon into main, merges main into your feature branch, then reinstalls deps and rebuilds
# so the installed `pi` binary runs the freshly merged source (dist/cli.js, not stale code).
#
# Enforcement contract: step 2 uses `git merge --ff-only`. If local `main` ever carries a
# stray commit (i.e. diverged from origin/main), the fast-forward fails LOUDLY and the sync
# aborts — surfacing the violation instead of silently merging fork work into main.
#
# Flags:
#   --no-build   skip the install + build step (git sync only)
#
# Usage: scripts/sync-fork.sh [feature-branch] [--no-build]
#        (feature-branch defaults to the previously checked-out branch)
set -euo pipefail

UPSTREAM_REPO="earendil-works/pi"
FORK_REPO="WesleyMFrederick/pi"

BUILD=1
FEATURE_BRANCH="@{-1}"
for arg in "$@"; do
  case "$arg" in
    --no-build) BUILD=0 ;;
    *) FEATURE_BRANCH="$arg" ;;
  esac
done

# 1. upstream → origin/main on GitHub
gh repo sync "$FORK_REPO" --source "$UPSTREAM_REPO" --branch main

# 2. origin/main → local main (FF-ONLY — fails loudly if main diverged)
git fetch origin
git checkout main
git merge --ff-only origin/main

# 3. main → active feature branch
git checkout "$FEATURE_BRANCH"
git merge main

# 4. reinstall deps + rebuild so the installed `pi` runs the merged source
if [ "$BUILD" -eq 1 ]; then
  npm install
  npm run build
  echo "✅ sync + rebuild complete — \`pi\` now runs the merged source."
else
  echo "✅ sync complete (build skipped — run \`npm install && npm run build\` to refresh the \`pi\` binary)."
fi
