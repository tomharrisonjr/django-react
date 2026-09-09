# Scaffold for Django/DRF + Flask API with React

Two interchangeable backends — Django REST Framework and Flask — plus a React (Vite/TS) frontend, run locally side by side. Both backends share the same SQLite database file (in their own tables) so you can compare the two frameworks without duplicating data. No Docker required for local dev.

## Quick start

```
scripts/setup.sh   # or `setup`, once direnv has sourced .aliases
```

Checks for python3/npm/direnv, creates a venv for each backend (`backend/django/venv`,
`backend/flask/venv`) and installs its requirements, runs `npm install` in `frontend/`,
and migrates the sqlite db for each backend. Afterwards it prints the `direnv allow`
commands to run once per directory (root, `backend/django/`, `backend/flask/`,
`frontend/`) so each `.envrc` can auto-activate.

## Backend: Django + DRF

```
cd backend/django
source venv/bin/activate   # venv already created; recreate with: python3 -m venv venv
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver 8000
```

API: http://127.0.0.1:8000/api/tasks/
Admin: http://127.0.0.1:8000/admin/ (create a superuser with `python manage.py createsuperuser`)

## Backend: Flask

A second, independent implementation of the same `Task` CRUD API — no admin UI, but real migrations via Flask-Migrate (Alembic). It reads/writes the same `backend/django/db.sqlite3` file as the Django backend, in its own `flask_task` table, so the two never collide.

```
cd backend/flask
source venv/bin/activate   # venv already created; recreate with: python3 -m venv venv
pip install -r requirements.txt
flask db upgrade
flask run --port 8001
```

API: http://127.0.0.1:8001/api/tasks/

## Frontend (React + Vite + TypeScript)

```
cd frontend
npm install
npm run dev
```

App: http://localhost:5173/ — talks to the API at `VITE_API_BASE` (see `src/api.ts`), defaulting to Django at `http://127.0.0.1:8000/api`. Copy `.env.example` to `.env` and set `VITE_API_BASE=http://127.0.0.1:8001/api` to point it at Flask instead, then restart `npm run dev`.

## What's here

A minimal Task CRUD slice implemented twice — Django (`tasks` app / DRF `ModelViewSet` + router) and Flask (`app` package / Blueprint + Flask-SQLAlchemy) — with a single `App.tsx` list/add/toggle/delete frontend that can point at either. Started as a Django-only scaffold; the Flask backend was added for learning/comparison purposes (see `docs/plans/gh-21-flask-version.md`), not to replace Django.

## Notes / next steps

- CORS is restricted to `localhost:5173` / `127.0.0.1:5173` — Django via `django-cors-headers` (`backend/django/config/settings.py`), Flask via `Flask-Cors` (`backend/flask/app/config.py`). Update both if the frontend port changes.
- No auth wired up yet on either backend — add DRF token/session auth (Django) or Flask-Login/JWT (Flask) if the test requires it.
- Docker/docker-compose intentionally not added yet; add a `Dockerfile` per app + `docker-compose.yml` if the test calls for container parity.
