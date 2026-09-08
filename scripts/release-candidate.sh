#!/usr/bin/env bash
# Bumps semver, updates frontend/package.json to match, merges the current
# branch's PR, tags main, and publishes a GitHub release.
# Usage: release-candidate.sh [major|minor|patch]  (defaults to patch)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

BUMP="${1:-patch}"
if [[ "$BUMP" != "major" && "$BUMP" != "minor" && "$BUMP" != "patch" ]]; then
  echo "usage: $(basename "$0") [major|minor|patch]" >&2
  exit 1
fi

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$BRANCH" == "main" ]]; then
  echo "error: run this from the feature branch whose PR you want to release, not main" >&2
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "error: you have uncommitted changes — commit or stash them before releasing" >&2
  git status --short
  exit 1
fi

PR_NUMBER="$(gh pr view --json number -q .number 2>/dev/null || true)"
if [[ -z "$PR_NUMBER" ]]; then
  echo "error: no PR found for branch '$BRANCH' — open one with finish-work.sh first" >&2
  exit 1
fi
PR_TITLE="$(gh pr view --json title -q .title)"
PR_STATE="$(gh pr view --json state -q .state)"

if [[ "$PR_STATE" != "OPEN" ]]; then
  echo "error: PR #$PR_NUMBER is not open (state: $PR_STATE)" >&2
  exit 1
fi

git fetch --tags origin

LATEST_TAG="$(git tag --list 'v[0-9]*.[0-9]*.[0-9]*' --sort=-v:refname | head -n1)"

if [[ -z "$LATEST_TAG" ]]; then
  NEW_TAG="v0.1.0"
  echo "==> No prior tags found — starting at $NEW_TAG"
else
  VERSION="${LATEST_TAG#v}"
  IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"
  case "$BUMP" in
    major) NEW_TAG="v$((MAJOR + 1)).0.0" ;;
    minor) NEW_TAG="v${MAJOR}.$((MINOR + 1)).0" ;;
    patch) NEW_TAG="v${MAJOR}.${MINOR}.$((PATCH + 1))" ;;
  esac
  echo "==> Bumping $LATEST_TAG -> $NEW_TAG ($BUMP)"
fi

VERSION_NO_V="${NEW_TAG#v}"

read -r -p "Bump frontend to $VERSION_NO_V, merge PR #$PR_NUMBER \"$PR_TITLE\", and release as $NEW_TAG? [y/N] " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo "Aborted."
  exit 1
fi

echo "==> Bumping frontend/package.json to $VERSION_NO_V"
( cd "$REPO_ROOT/frontend" && npm version "$VERSION_NO_V" --no-git-tag-version --allow-same-version >/dev/null )
git add frontend/package.json frontend/package-lock.json
if git diff --cached --quiet; then
  echo "frontend/package.json already at $VERSION_NO_V — nothing to commit, skipping push"
else
  git commit -m "chore: bump frontend version to $VERSION_NO_V"
  git push origin "$BRANCH"
fi

gh pr merge "$PR_NUMBER" --squash --delete-branch

git checkout main
git pull origin main

git tag -a "$NEW_TAG" -m "$NEW_TAG"
git push origin "$NEW_TAG"

gh release create "$NEW_TAG" --title "$PR_TITLE" --generate-notes

echo "==> Released $NEW_TAG: $(gh release view "$NEW_TAG" --json url -q .url)"
