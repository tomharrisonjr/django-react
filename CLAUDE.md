# CLAUDE.md

Guidance for Claude Code working in this repository.

## Repo layout

Django REST Framework backend + React (Vite/TS) frontend, run side by side locally. SQLite, no Docker.

```
backend/            Django project
  config/           settings, urls, asgi/wsgi
  tasks/            the one app so far — models, serializers, views, urls, tests.py
  venv/             local virtualenv — never read, grep, or edit inside here
  db.sqlite3        gitignored, local only
frontend/           Vite + React 19 + TypeScript
  src/App.tsx       main list/add/toggle/delete UI
  src/api.ts        API client, points at http://127.0.0.1:8000/api
  node_modules/     never read, grep, or edit inside here
```

When searching the repo, exclude `backend/venv` and `frontend/node_modules` — they're large, gitignored, and never relevant to a change here.

## Commands

Backend (from `backend/`, with `venv` activated):
```
source venv/bin/activate
pip install -r requirements-dev.txt   # adds ruff on top of requirements.txt
python manage.py migrate
python manage.py runserver 8000
python manage.py test              # tests
ruff check .                       # lint
ruff check --fix .                 # lint, autofixing what's safe to fix
```
Ruff is configured in `backend/pyproject.toml` (pycodestyle, pyflakes, isort, pyupgrade, bugbear, and Django-aware `DJ` rules; migrations excluded).

Frontend (from `frontend/`):
```
npm run dev        # dev server, http://localhost:5173
npm run build       # tsc -b && vite build — this is "the ts build"
npm run lint        # oxlint
npm run preview
```

## Workflow

This repo tracks work as GitHub issues (`gh issue list` / `gh issue view <n>`).

- **Every change starts from a GitHub issue.** If one doesn't exist for the requested work, create it first (`gh issue create`) before branching.
- **Branch naming:** `<type>/gh-<issue>-<short-title>`, where `type` is `feature`, `bug`, or `chore`, `<issue>` is the GitHub issue number, and `<short-title>` is a few kebab-case words summarizing it. Examples: `feature/gh-12-task-priority`, `bug/gh-14-cors-error`, `chore/gh-16-upgrade-drf`.
- **Every new feature starts with a plan doc** before implementation: a markdown file (put it under `docs/plans/`, e.g. `docs/plans/gh-12-task-priority.md`) whose header is:
  ```markdown
  # <Title>

  - Date: YYYY-MM-DD
  - GitHub Issue: #<n>
  - Status: Draft | In Progress | Complete
  ```
  followed by the plan content. Use Claude Code's plan mode to draft this, get it approved, then write it to the file before starting implementation. Update `Status` as work progresses.
- **Before a PR merges**, all of the following must pass:
  1. Backend lint: `ruff check .` (from `backend/`, venv active)
  2. Backend tests: `python manage.py test` (from `backend/`, venv active)
  3. Frontend lint: `npm run lint` (from `frontend/`)
  4. Frontend TS build: `npm run build` (from `frontend/`)
  5. Any documentation affected by the change — README.md, frontend/README.md, or the feature's plan doc — is updated to reflect what shipped, and the plan doc's `Status` is set to `Complete`.

  Don't propose a PR as ready until you've actually run 1–4 yourself and confirmed they pass.

## Conventions

- Keep the plan doc and the PR description in sync — the plan is the source of truth for *why*, the PR diff for *what*.
- Match existing style: DRF `ModelViewSet` + router for backend endpoints (see `tasks/views.py` + `tasks/urls.py`); functional React components with hooks on the frontend.
- CORS is restricted to `localhost:5173` / `127.0.0.1:5173` in `backend/config/settings.py` — update `CORS_ALLOWED_ORIGINS` there if the frontend port ever changes, and call it out in the PR if you do.
