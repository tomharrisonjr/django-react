#!/usr/bin/env bash
# Stops the dev servers started by bounce.sh: frontend (Vite, :5173), Django
# (:8000), and Flask (:8001). Run from anywhere; pass --force to SIGKILL
# instead of SIGTERM for anything still up after the grace period.
set -uo pipefail

FORCE=false
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=true ;;
    *)
      echo "usage: $(basename "$0") [--force]" >&2
      exit 1
      ;;
  esac
done

declare -A PORTS=(
  [frontend]=5173
  [django]=8000
  [flask]=8001
)

stop_port() {
  local name="$1" port="$2"
  local pids
  pids="$(lsof -ti:"$port" -sTCP:LISTEN 2>/dev/null || true)"

  if [[ -z "$pids" ]]; then
    echo "$name (:$port) — not running"
    return
  fi

  echo "$name (:$port) — stopping pid(s) $pids"
  kill $pids 2>/dev/null || true

  for _ in $(seq 1 10); do
    pids="$(lsof -ti:"$port" -sTCP:LISTEN 2>/dev/null || true)"
    [[ -z "$pids" ]] && break
    sleep 0.5
  done

  pids="$(lsof -ti:"$port" -sTCP:LISTEN 2>/dev/null || true)"
  if [[ -n "$pids" ]]; then
    if [[ "$FORCE" == true ]]; then
      echo "$name (:$port) — still up, sending SIGKILL to pid(s) $pids"
      kill -9 $pids 2>/dev/null || true
    else
      echo "$name (:$port) — still up after SIGTERM (pid(s) $pids); rerun with --force to SIGKILL"
    fi
  else
    echo "$name (:$port) — stopped"
  fi
}

for name in "${!PORTS[@]}"; do
  stop_port "$name" "${PORTS[$name]}"
done
