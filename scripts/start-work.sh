#!/usr/bin/env bash
# Creates a GitHub issue (with $EDITOR for the body) and a linked branch to start new work.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "error: you have uncommitted changes — commit or stash them before starting new work" >&2
  git status --short
  exit 1
fi

read -r -p "Issue title: " TITLE
if [[ -z "$TITLE" ]]; then
  echo "error: title cannot be empty" >&2
  exit 1
fi

TYPE=""
while [[ "$TYPE" != "feature" && "$TYPE" != "bug" && "$TYPE" != "chore" ]]; do
  read -r -p "Type (feature/bug/chore): " TYPE
done

BODY_FILE="$(mktemp)"
trap 'rm -f "$BODY_FILE"' EXIT
cat > "$BODY_FILE" <<EOF
# Describe the issue below. Lines starting with '#' are ignored.
# Title: $TITLE
# Type: $TYPE
EOF
"${EDITOR:-vim}" "$BODY_FILE"

BODY="$(grep -v '^#' "$BODY_FILE" || true)"
if [[ -z "$(echo "$BODY" | tr -d '[:space:]')" ]]; then
  echo "error: issue body is empty — aborting" >&2
  exit 1
fi

DEFAULT_BRANCH="$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)"
git checkout "$DEFAULT_BRANCH"
git pull origin "$DEFAULT_BRANCH"

ISSUE_URL="$(gh issue create --title "$TITLE" --body "$BODY" --assignee "@me")"
ISSUE_NUM="$(basename "$ISSUE_URL")"
echo "Created issue #$ISSUE_NUM: $ISSUE_URL"

SLUG="$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g' | cut -c1-50 | sed -E 's/-+$//')"
BRANCH="${TYPE}/gh-${ISSUE_NUM}-${SLUG}"

gh issue develop "$ISSUE_NUM" --base "$DEFAULT_BRANCH" --name "$BRANCH" --checkout

echo "Checked out branch: $BRANCH (linked to issue #$ISSUE_NUM)"
