#!/usr/bin/env bash
# One-shot local dev setup: checks dependencies, creates the backend venv and
# installs its requirements, installs frontend deps, migrates the sqlite db,
# and points you at the direnv files that still need to be allowed.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKEND_DIR="$REPO_ROOT/backend"
FRONTEND_DIR="$REPO_ROOT/frontend"

require_cmd() {
  local cmd="$1" hint="$2"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "error: '$cmd' not found — $hint" >&2
    exit 1
  fi
}

echo "==> Checking dependencies"
require_cmd python3 "install Python 3: https://www.python.org/downloads/"
require_cmd npm "install Node.js/npm: https://nodejs.org/"
require_cmd direnv "install direnv: brew install direnv (then hook it into your shell — see https://direnv.net/docs/hook.html)"
echo "python3: $(python3 --version)"
echo "npm: $(npm --version)"
echo "direnv: $(direnv version)"
echo

echo "==> Backend: virtualenv + dependencies"
if [[ ! -f "$BACKEND_DIR/venv/bin/activate" ]]; then
  ( cd "$BACKEND_DIR" && python3 -m venv venv )
  echo "Created $BACKEND_DIR/venv"
else
  echo "backend/venv already exists, skipping creation"
fi
( cd "$BACKEND_DIR" && source venv/bin/activate && pip install -r requirements-dev.txt )
echo

echo "==> Frontend: dependencies (npm install)"
( cd "$FRONTEND_DIR" && npm install )
echo

echo "==> Backend: migrating the database"
( cd "$BACKEND_DIR" && source venv/bin/activate && python manage.py migrate )
echo

echo "==================== Next step ===================="
echo "direnv is installed, but each .envrc still needs to be allowed once per"
echo "directory before it will auto-activate. Run:"
echo
echo "  cd $REPO_ROOT && direnv allow"
echo "  cd $BACKEND_DIR && direnv allow"
echo "  cd $FRONTEND_DIR && direnv allow"
echo "====================================================="
