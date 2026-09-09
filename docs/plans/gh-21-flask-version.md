# Flask Version (parallel to Django)

- Date: 2026-09-09
- GitHub Issue: #21
- Status: Complete

## Context

Issue #21 ("flask version") says the test will use Flask instead of Django. Rather than replacing the Django backend, the goal here is to add a second, independently-runnable Flask backend for learning/comparison purposes — same `Task` CRUD API, same SQLite database file, own migrations. Django keeps the admin UI and its own tables; Flask does not need an admin UI but does need real migrations (Alembic via Flask-Migrate) and to read/write the same physical `db.sqlite3` file (in its own tables, so the two migration histories never collide).

This plan also relocates the existing Django project from `backend/` to `backend/django/` so the two frameworks sit side by side under `backend/` as peers.

## Approach

### 1. Move Django: `backend/` → `backend/django/`

- `git mv` everything currently under `backend/` (except `venv/` and `db.sqlite3`, which are gitignored — see below) into `backend/django/`: `config/`, `tasks/`, `manage.py`, `pyproject.toml`, `requirements.txt`, `requirements-dev.txt`.
- Recreate `venv/` inside `backend/django/` (it's gitignored, not moved — just reinstalled: `python -m venv venv && pip install -r requirements-dev.txt`).
- Move `db.sqlite3` to `backend/django/db.sqlite3` manually (gitignored, not a `git mv`) — or just let it regenerate via `migrate`, since it's local dev data.
- No code changes needed inside the Django project itself — it has no hardcoded paths back to `backend/`.

### 2. New Flask project: `backend/flask/`

Structure, mirroring the Django project's shape as closely as sensibly possible:

```
backend/flask/
  app/
    __init__.py        # create_app() factory, extension init (db, migrate, cors)
    config.py           # Config class: SQLALCHEMY_DATABASE_URI, CORS origins
    models.py            # Task model (SQLAlchemy)
    schemas.py           # serialization to/from JSON (marshmallow, or manual to_dict)
    tasks/
      __init__.py
      routes.py          # Blueprint with the /api/tasks/ CRUD routes
  migrations/            # Flask-Migrate/Alembic migration scripts (generated)
  tests.py               # unittest-based API tests, mirroring tasks/tests.py's cases
  requirements.txt        # Flask, Flask-SQLAlchemy, Flask-Migrate, Flask-CORS
  requirements-dev.txt     # + ruff (reuse same lint tool/config as Django side)
  pyproject.toml           # ruff config (can extend/copy backend/django/pyproject.toml rules)
  wsgi.py                  # entrypoint: `flask --app wsgi run --port 8001`
```

Key libraries: **Flask**, **Flask-SQLAlchemy** (ORM), **Flask-Migrate** (wraps Alembic — gives real migration files comparable to Django's `migrate`), **Flask-CORS** (equivalent of `django-cors-headers`).

**Database sharing:** point `SQLALCHEMY_DATABASE_URI` at the *same* `backend/django/db.sqlite3` file (relative path reaches across from `backend/flask/`). To avoid the two migration histories fighting over one table, the Flask `Task` model uses a distinct table name (e.g. `__tablename__ = "flask_task"`), separate from Django's `tasks_task`. Both backends read/write the same SQLite file, each owns its own table and migration chain — satisfies "same DB" without schema collisions, and keeps each side's migration tooling independently exercisable for comparison.

**Task model** (mirrors `backend/django/tasks/models.py`):
```python
class Task(db.Model):
    id: Mapped[int] = mapped_column(primary_key=True)
    title: Mapped[str] = mapped_column(db.String(200))
    done: Mapped[bool] = mapped_column(default=False)
    created_at: Mapped[datetime] = mapped_column(default=datetime.utcnow)
```
Use SQLAlchemy 2.0-style typed `Mapped[...]` columns, matching this repo's convention of annotating class attributes (CLAUDE.md's Django rule extends naturally here).

**Routes** (Blueprint `tasks`, registered under `/api`), matching the existing REST surface exactly:
- `GET /api/tasks/` — paginated list, **same response shape as DRF**: `{count, next, previous, results}` (page size 20, `?page=` param), ordered by `-created_at`.
- `POST /api/tasks/` — create; `title` required (400 if missing), `done` defaults `False`, `id`/`created_at` ignored if sent.
- `GET /api/tasks/<id>/` — retrieve, 404 if missing.
- `PATCH /api/tasks/<id>/` — partial update.
- `DELETE /api/tasks/<id>/` — 204 on success.

No admin UI, no auth/sessions app — just the DB, migrations, and this one Blueprint.

### 3. Frontend: pick a backend via env var

- `frontend/src/api.ts`: change `const API_BASE = "http://127.0.0.1:8000/api"` to read from Vite env: `const API_BASE = import.meta.env.VITE_API_BASE ?? "http://127.0.0.1:8000/api"`.
- Add `frontend/.env` (or `.env.local`, gitignored) with `VITE_API_BASE=http://127.0.0.1:8000/api` (Django default) and document the Flask alternative (`http://127.0.0.1:8001/api`) in a comment or `.env.example`.
- Add `frontend/.env.example` (committed) showing both options, so switching backends is: edit `.env`, restart `npm run dev`.

### 4. CORS

- Django's `CORS_ALLOWED_ORIGINS` already only needs `localhost:5173`/`127.0.0.1:5173` — unaffected by the move.
- Flask-CORS config in `backend/flask/app/config.py` allows the same two origins.
- No change needed to CLAUDE.md's CORS note beyond mentioning the new Flask config lives in `backend/flask/app/config.py`.

### 5. Documentation updates

- `README.md`: update backend setup instructions to cover both `backend/django/` (existing steps, now under new path) and `backend/flask/` (new steps: venv, `pip install -r requirements-dev.txt`, `flask db upgrade`, `flask --app wsgi run --port 8001`). Explain the `VITE_API_BASE` switch.
- `CLAUDE.md`: update the repo layout section — `backend/django/` and `backend/flask/` as peers, note the shared SQLite file and separate tables, add Flask's commands (`flask db migrate`, `flask db upgrade`, `flask --app wsgi run --port 8001`, `ruff check .`) alongside the Django ones.
- This plan doc gets written to `docs/plans/gh-21-flask-version.md` (per repo convention) once approved, `Status: In Progress` → `Complete` as work lands.

## Files touched

- Moved: everything in `backend/` → `backend/django/` (git mv).
- New: `backend/flask/` (app package, migrations, tests, requirements, wsgi entrypoint).
- Modified: `frontend/src/api.ts` (env-based `API_BASE`), new `frontend/.env.example`.
- Modified: `README.md`, `CLAUDE.md`.

## Verification

1. Django side unaffected: `cd backend/django && source venv/bin/activate && python manage.py test && ruff check .` — still passes after the move.
2. Flask side: `cd backend/flask && source venv/bin/activate && flask db upgrade && python -m unittest tests.py && ruff check .`.
3. Run both backends simultaneously (`:8000` Django, `:8001` Flask); flip `VITE_API_BASE` in `frontend/.env` between the two, confirm the frontend's list/add/toggle/delete flows work identically against each.
4. Confirm both backends' tables coexist in the one `db.sqlite3` (`sqlite3 backend/django/db.sqlite3 .tables` shows both `tasks_task` and `flask_task`).
5. Frontend: `npm run lint && npm run build` still pass.
6. Update `docs/plans/gh-21-flask-version.md` Status to `Complete`, update README/CLAUDE.md as shipped.
