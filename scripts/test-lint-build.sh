#!/usr/bin/env bash
# Runs both backends' lint/tests and frontend lint/build; reports pass/fail for each step.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DJANGO_DIR="$REPO_ROOT/backend/django"
FLASK_DIR="$REPO_ROOT/backend/flask"
FRONTEND_DIR="$REPO_ROOT/frontend"

STEP_NAMES=()
STEP_RESULTS=()

run_step() {
  local name="$1"
  shift
  echo "==> $name"
  if "$@"; then
    STEP_RESULTS+=("PASS")
  else
    STEP_RESULTS+=("FAIL")
  fi
  STEP_NAMES+=("$name")
  echo
}

django_lint() {
  ( cd "$DJANGO_DIR" && source venv/bin/activate && ruff check . )
}

django_test() {
  ( cd "$DJANGO_DIR" && source venv/bin/activate && python manage.py test )
}

flask_lint() {
  ( cd "$FLASK_DIR" && source venv/bin/activate && ruff check . )
}

flask_test() {
  ( cd "$FLASK_DIR" && source venv/bin/activate && python -m unittest tests.py )
}

frontend_lint() {
  ( cd "$FRONTEND_DIR" && npm run lint )
}

frontend_build() {
  ( cd "$FRONTEND_DIR" && npm run build )
}

if [[ ! -f "$DJANGO_DIR/venv/bin/activate" ]]; then
  echo "error: backend/django/venv not found — run 'python -m venv venv && pip install -r requirements-dev.txt' in backend/django/ first" >&2
  exit 1
fi
if [[ ! -f "$FLASK_DIR/venv/bin/activate" ]]; then
  echo "error: backend/flask/venv not found — run 'python -m venv venv && pip install -r requirements-dev.txt' in backend/flask/ first" >&2
  exit 1
fi

run_step "django lint (ruff check)" django_lint
run_step "django tests (manage.py test)" django_test
run_step "flask lint (ruff check)" flask_lint
run_step "flask tests (unittest)" flask_test
run_step "frontend lint (npm run lint)" frontend_lint
run_step "frontend build (npm run build)" frontend_build

echo "==================== Summary ===================="
overall=0
for i in "${!STEP_NAMES[@]}"; do
  printf '%-40s %s\n' "${STEP_NAMES[$i]}" "${STEP_RESULTS[$i]}"
  [[ "${STEP_RESULTS[$i]}" == "FAIL" ]] && overall=1
done
echo "==================================================="

exit $overall
