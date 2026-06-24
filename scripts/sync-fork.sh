#!/bin/bash
# sync-fork.sh — reliable 3-step fork sync: upstream → origin/main → local main → feature branch.
#
# Model: `main` mirrors the canonical (upstream) repo everywhere (origin + local).
# Your customizations live on a feature branch (default: explore). This script pulls
# canon into main, then merges main into your feature branch.
#
# Enforcement contract: step 2 uses `git merge --ff-only`. If local `main` ever carries a
# stray commit (i.e. diverged from origin/main), the fast-forward fails LOUDLY and the sync
# aborts — surfacing the violation instead of silently merging fork work into main.
#
# Usage: scripts/sync-fork.sh [feature-branch]   (defaults to the previously checked-out branch)
set -euo pipefail

UPSTREAM_REPO="earendil-works/pi"
FORK_REPO="WesleyMFrederick/pi"
FEATURE_BRANCH="${1:-@{-1}}"

# 1. upstream → origin/main on GitHub
gh repo sync "$FORK_REPO" --source "$UPSTREAM_REPO" --branch main

# 2. origin/main → local main (FF-ONLY — fails loudly if main diverged)
git fetch origin
git checkout main
git merge --ff-only origin/main

# 3. main → active feature branch
git checkout "$FEATURE_BRANCH"
git merge main
