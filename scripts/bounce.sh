#!/usr/bin/env bash
# Starts this app's dev server if it isn't already running. Run from inside
# frontend/ to start the Vite dev server, or backend/ to start Django's.
set -euo pipefail

FRONTEND_PORT=5173
BACKEND_PORT=8000

REPO_ROOT="$(git rev-parse --show-toplevel)"
CWD="$(pwd -P)"

is_listening() {
  lsof -ti:"$1" -sTCP:LISTEN >/dev/null 2>&1
}

case "$CWD" in
  "$REPO_ROOT/frontend")
    if is_listening "$FRONTEND_PORT"; then
      echo "frontend dev server already running on port $FRONTEND_PORT"
      exit 0
    fi
    echo "==> Starting frontend dev server (npm run dev) on port $FRONTEND_PORT"
    nohup npm run dev > /tmp/frontend-dev.log 2>&1 &
    echo "Started (pid $!). Logs: /tmp/frontend-dev.log"
    ;;
  "$REPO_ROOT/backend")
    if is_listening "$BACKEND_PORT"; then
      echo "backend dev server already running on port $BACKEND_PORT"
      exit 0
    fi
    if [[ ! -f venv/bin/activate ]]; then
      echo "error: backend/venv not found — run 'python -m venv venv && pip install -r requirements-dev.txt' first" >&2
      exit 1
    fi
    echo "==> Starting backend dev server (manage.py runserver) on port $BACKEND_PORT"
    source venv/bin/activate
    nohup python manage.py runserver "$BACKEND_PORT" > /tmp/backend-dev.log 2>&1 &
    echo "Started (pid $!). Logs: /tmp/backend-dev.log"
    ;;
  *)
    echo "error: run this from inside frontend/ or backend/ (currently in $CWD)" >&2
    exit 1
    ;;
esac
