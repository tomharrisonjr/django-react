#!/usr/bin/env bash
# Starts this app's dev server if it isn't already running, then tails its
# log so you can watch it (pass --no-log to skip that and just exit). Run
# from inside frontend/ to start the Vite dev server, backend/django/ to
# start Django's, or backend/flask/ to start Flask's.
set -euo pipefail

NO_LOG=false
for arg in "$@"; do
  case "$arg" in
    --no-log) NO_LOG=true ;;
    *)
      echo "usage: $(basename "$0") [--no-log]" >&2
      exit 1
      ;;
  esac
done

FRONTEND_PORT=5173
DJANGO_PORT=8000
FLASK_PORT=8001

REPO_ROOT="$(git rev-parse --show-toplevel)"
CWD="$(pwd -P)"

is_listening() {
  lsof -ti:"$1" -sTCP:LISTEN >/dev/null 2>&1
}

tail_log() {
  local log_file="$1"
  if [[ "$NO_LOG" == true ]]; then
    return
  fi
  echo "==> Tailing $log_file (Ctrl-C to stop watching; the server keeps running)"
  tail -f "$log_file"
}

case "$CWD" in
  "$REPO_ROOT/frontend")
    LOG_FILE=/tmp/frontend-dev.log
    if is_listening "$FRONTEND_PORT"; then
      echo "frontend dev server already running on port $FRONTEND_PORT"
    else
      echo "==> Starting frontend dev server (npm run dev) on port $FRONTEND_PORT"
      nohup npm run dev > "$LOG_FILE" 2>&1 &
      echo "Started (pid $!). Logs: $LOG_FILE"
    fi
    tail_log "$LOG_FILE"
    ;;
  "$REPO_ROOT/backend/django")
    LOG_FILE=/tmp/backend-django-dev.log
    if is_listening "$DJANGO_PORT"; then
      echo "django dev server already running on port $DJANGO_PORT"
    else
      if [[ ! -f venv/bin/activate ]]; then
        echo "error: backend/django/venv not found — run 'python -m venv venv && pip install -r requirements-dev.txt' first" >&2
        exit 1
      fi
      echo "==> Starting django dev server (manage.py runserver) on port $DJANGO_PORT"
      source venv/bin/activate
      nohup python manage.py runserver "$DJANGO_PORT" > "$LOG_FILE" 2>&1 &
      echo "Started (pid $!). Logs: $LOG_FILE"
    fi
    tail_log "$LOG_FILE"
    ;;
  "$REPO_ROOT/backend/flask")
    LOG_FILE=/tmp/backend-flask-dev.log
    if is_listening "$FLASK_PORT"; then
      echo "flask dev server already running on port $FLASK_PORT"
    else
      if [[ ! -f venv/bin/activate ]]; then
        echo "error: backend/flask/venv not found — run 'python -m venv venv && pip install -r requirements-dev.txt' first" >&2
        exit 1
      fi
      echo "==> Starting flask dev server (flask run) on port $FLASK_PORT"
      source venv/bin/activate
      FLASK_APP=wsgi.py nohup flask run --port "$FLASK_PORT" > "$LOG_FILE" 2>&1 &
      echo "Started (pid $!). Logs: $LOG_FILE"
    fi
    tail_log "$LOG_FILE"
    ;;
  *)
    echo "error: run this from inside frontend/, backend/django/, or backend/flask/ (currently in $CWD)" >&2
    exit 1
    ;;
esac
