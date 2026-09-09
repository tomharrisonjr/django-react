# CLAUDE.md

Guidance for Claude Code working in this repository.

## Repo layout

Two peer backends — Django REST Framework and Flask — implementing the same `Task` CRUD API, plus a React (Vite/TS) frontend that can point at either. Both backends share one SQLite file (`backend/django/db.sqlite3`), each owning its own table (`tasks_task` for Django, `flask_task` for Flask) and its own migration history, so they never collide. The Flask backend exists for learning/comparison, not to replace Django — see `docs/plans/gh-21-flask-version.md`. No Docker.

```
backend/
  django/           Django project
    config/         settings, urls, asgi/wsgi
    tasks/          the one app so far — models, serializers, views, urls, tests.py
    venv/           local virtualenv — never read, grep, or edit inside here
    db.sqlite3      gitignored, local only — shared with backend/flask
  flask/            Flask project (mirrors the Django API, no admin UI)
    app/            create_app() factory, config, SQLAlchemy models, schemas
    app/tasks/      Blueprint with the /api/tasks/ routes
    migrations/     Flask-Migrate/Alembic migrations — env.py filters autogenerate
                     to the flask_task table only, so it never touches Django's tables
    tests.py        unittest-based API tests, mirrors backend/django/tasks/tests.py
    venv/           local virtualenv — never read, grep, or edit inside here
frontend/           Vite + React 19 + TypeScript, styled with Tailwind CSS + shadcn/ui
  src/App.tsx       main list/add/toggle/delete UI
  src/api.ts        API client — base URL from VITE_API_BASE, defaults to Django's :8000
  src/components/ui/  shadcn/ui components (generated — see Conventions)
  src/lib/          utils.ts (shadcn's cn helper re-export), version.ts (reads package.json)
  components.json   shadcn/ui CLI config
  .env.example      documents VITE_API_BASE for both backends; copy to .env to switch
  node_modules/     never read, grep, or edit inside here
```

When searching the repo, exclude `backend/django/venv`, `backend/flask/venv`, and `frontend/node_modules` — they're large, gitignored, and never relevant to a change here.

## Commands

Django backend (from `backend/django/`, with `venv` activated):
```
source venv/bin/activate
pip install -r requirements-dev.txt   # adds ruff on top of requirements.txt
python manage.py migrate
python manage.py runserver 8000
python manage.py test              # tests
ruff check .                       # lint
ruff check --fix .                 # lint, autofixing what's safe to fix
```
Ruff is configured in `backend/django/pyproject.toml` (pycodestyle, pyflakes, isort, pyupgrade, bugbear, and Django-aware `DJ` rules; migrations excluded).

Flask backend (from `backend/flask/`, with `venv` activated):
```
source venv/bin/activate
pip install -r requirements-dev.txt   # adds ruff on top of requirements.txt
export FLASK_APP=wsgi.py              # .envrc sets this automatically under direnv
flask db upgrade                      # apply migrations
flask db migrate -m "..."             # generate a new migration after model changes
flask run --port 8001
python -m unittest tests.py           # tests
ruff check .                          # lint
ruff check --fix .                    # lint, autofixing what's safe to fix
```
Ruff is configured in `backend/flask/pyproject.toml` (same ruleset as Django's minus `DJ`; migrations excluded). Runs on port 8001 so both backends can be up at once.

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
- **Before a PR merges**, all of the following must pass (or run `scripts/test-lint-build.sh` / `test-lint-build` to do 1–6 in one shot):
  1. Django lint: `ruff check .` (from `backend/django/`, venv active)
  2. Django tests: `python manage.py test` (from `backend/django/`, venv active)
  3. Flask lint: `ruff check .` (from `backend/flask/`, venv active)
  4. Flask tests: `python -m unittest tests.py` (from `backend/flask/`, venv active)
  5. Frontend lint: `npm run lint` (from `frontend/`)
  6. Frontend TS build: `npm run build` (from `frontend/`)
  7. Any documentation affected by the change — README.md, frontend/README.md, or the feature's plan doc — is updated to reflect what shipped, and the plan doc's `Status` is set to `Complete`.

  Don't propose a PR as ready until you've actually run 1–6 yourself and confirmed they pass.

## Conventions

- Keep the plan doc and the PR description in sync — the plan is the source of truth for *why*, the PR diff for *what*.
- Match existing style: DRF `ModelViewSet` + router for Django endpoints (see `backend/django/tasks/views.py` + `tasks/urls.py`); a Flask Blueprint for Flask endpoints (see `backend/flask/app/tasks/routes.py`); functional React components with hooks on the frontend.
- CORS is restricted to `localhost:5173` / `127.0.0.1:5173` on both backends — Django via `CORS_ALLOWED_ORIGINS` in `backend/django/config/settings.py`, Flask via `CORS_ORIGINS` in `backend/flask/app/config.py`. Update both if the frontend port ever changes, and call it out in the PR if you do.
- **Django: annotate class attributes.** New and touched classes should carry PEP 526 variable annotations on their class-level attributes — model fields (`title: models.CharField[str] = models.CharField(...)`), `Meta`/config attributes (`name: str = "tasks"`), and viewset/serializer attributes (`queryset: QuerySet[Task] = ...`, `serializer_class: type[TaskSerializer] = ...`). Add `from __future__ import annotations` to any file that subscripts a Django field or model type this way, since Django's field classes aren't runtime-subscriptable. No mypy/django-stubs is configured, so this is for readability, not enforced — but keep it consistent with `tasks/models.py`, `tasks/serializers.py`, `tasks/views.py`, and `tasks/apps.py`.
- **Flask: same annotation convention.** Use SQLAlchemy 2.0-style typed `Mapped[...]` columns on models (`backend/flask/app/models.py`) and annotate module-level config/blueprint attributes the same way (`backend/flask/app/config.py`, `app/tasks/routes.py`) — keeps the two backends readable side by side.
- **Flask migrations are scoped to `flask_task` only.** `backend/flask/migrations/env.py` defines `include_object` to filter out every table Flask's SQLAlchemy metadata doesn't declare — without it, `flask db migrate` autogenerates against the *whole* shared SQLite file and proposes dropping all of Django's tables. Never remove that filter, and if you add new Flask models, no change to `include_object` is needed — it already whitelists anything in `target_db.metadata.tables`.
- **Frontend styling: Tailwind CSS + shadcn/ui.** Utility classes via Tailwind v4 (wired through `@tailwindcss/vite` in `vite.config.ts`); components come from shadcn/ui's CLI (`npx shadcn@latest add <component>`), which drops generated files into `src/components/ui/` — treat those as vendored (don't hand-edit their structure) so future `shadcn add` updates stay clean. The `@/*` import alias points at `src/` (configured in `tsconfig.json`/`tsconfig.app.json` and `vite.config.ts`). `react/only-export-components` is disabled for `src/components/ui/**` in `.oxlintrc.json` since shadcn's generated files intentionally export a `cva` variants function alongside the component.
