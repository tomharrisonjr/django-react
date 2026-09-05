#!/usr/bin/env bash
# Runs backend lint/tests and frontend lint/build; reports pass/fail for each step.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKEND_DIR="$REPO_ROOT/backend"
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

backend_lint() {
  ( cd "$BACKEND_DIR" && source venv/bin/activate && ruff check . )
}

backend_test() {
  ( cd "$BACKEND_DIR" && source venv/bin/activate && python manage.py test )
}

frontend_lint() {
  ( cd "$FRONTEND_DIR" && npm run lint )
}

frontend_build() {
  ( cd "$FRONTEND_DIR" && npm run build )
}

if [[ ! -f "$BACKEND_DIR/venv/bin/activate" ]]; then
  echo "error: backend/venv not found — run 'python -m venv venv && pip install -r requirements-dev.txt' in backend/ first" >&2
  exit 1
fi

run_step "backend lint (ruff check)" backend_lint
run_step "backend tests (manage.py test)" backend_test
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
