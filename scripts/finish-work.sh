#!/usr/bin/env bash
# Runs test-lint-build, commits current work with an editable message, and opens a PR
# for the issue linked in the current branch name.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ ! "$BRANCH" =~ ^(feature|bug|chore)/gh-([0-9]+)-.+ ]]; then
  echo "error: branch '$BRANCH' doesn't match '<feature|bug|chore>/gh-<issue>-<slug>' — can't identify issue" >&2
  exit 1
fi
TYPE="${BASH_REMATCH[1]}"
ISSUE_NUM="${BASH_REMATCH[2]}"

echo "==> Issue #$ISSUE_NUM ($TYPE) on branch $BRANCH"

echo "==> Running test-lint-build.sh"
if ! "$SCRIPT_DIR/test-lint-build.sh"; then
  echo "error: test-lint-build.sh failed — fix the reported issues before finishing" >&2
  exit 1
fi

git add -A

if [[ -z "$(git diff --cached)" ]] && [[ -z "$(git log origin/main..HEAD 2>/dev/null || true)" ]]; then
  echo "error: no changes to commit and no commits ahead of main" >&2
  exit 1
fi

case "$TYPE" in
  feature) PREFIX="feat" ;;
  bug) PREFIX="fix" ;;
  chore) PREFIX="chore" ;;
esac

ISSUE_TITLE="$(gh issue view "$ISSUE_NUM" --json title -q .title 2>/dev/null || true)"
DEFAULT_TITLE="${PREFIX}: ${ISSUE_TITLE:-gh-$ISSUE_NUM}"
CHANGED_FILES="$(git diff --cached --stat | sed '$d' || true)"

MSG_FILE="$(mktemp)"
PR_BODY_FILE="$(mktemp)"
trap 'rm -f "$MSG_FILE" "$PR_BODY_FILE"' EXIT

if [[ -n "$(git diff --cached)" ]]; then
  cat > "$MSG_FILE" <<EOF
$DEFAULT_TITLE

Closes #$ISSUE_NUM

# Edit the commit message above. Lines starting with '#' are ignored.
#
# Files changed:
$(echo "$CHANGED_FILES" | sed 's/^/# /')
EOF
  "${EDITOR:-vim}" "$MSG_FILE"

  FINAL_MSG="$(grep -v '^#' "$MSG_FILE" || true)"
  if [[ -z "$(echo "$FINAL_MSG" | tr -d '[:space:]')" ]]; then
    echo "error: commit message is empty — aborting" >&2
    exit 1
  fi

  git commit -F <(echo "$FINAL_MSG")
else
  echo "==> Nothing staged — skipping commit, using existing commits"
  FINAL_MSG="$DEFAULT_TITLE"
fi

git push -u origin "$BRANCH"

PR_TITLE_DEFAULT="$(echo "$FINAL_MSG" | head -n1)"
read -r -p "PR title [$PR_TITLE_DEFAULT]: " PR_TITLE_INPUT
PR_TITLE="${PR_TITLE_INPUT:-$PR_TITLE_DEFAULT}"

cat > "$PR_BODY_FILE" <<EOF
## Summary
$(echo "$FINAL_MSG" | tail -n +2)

Closes #$ISSUE_NUM

# Edit the PR description above. Lines starting with '#' are ignored.
EOF
"${EDITOR:-vim}" "$PR_BODY_FILE"
PR_BODY="$(grep -v '^#' "$PR_BODY_FILE" || true)"

gh pr create --base main --head "$BRANCH" --title "$PR_TITLE" --body "$PR_BODY" --assignee "@me"
