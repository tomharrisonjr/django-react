# Scaffold for Django/DRF API with React

Django REST Framework backend + React (Vite/TS) frontend, run locally side by side. SQLite database, no Docker required for local dev.

## Backend (Django + DRF)

```
cd backend
source venv/bin/activate   # venv already created; recreate with: python3 -m venv venv
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver 8000
```

API: http://127.0.0.1:8000/api/tasks/
Admin: http://127.0.0.1:8000/admin/ (create a superuser with `python manage.py createsuperuser`)

## Frontend (React + Vite + TypeScript)

```
cd frontend
npm install
npm run dev
```

App: http://localhost:5173/ — talks to the API at `http://127.0.0.1:8000/api` (see `src/api.ts`).

## What's here

A minimal Task CRUD slice (`tasks` app / DRF `ModelViewSet` + router on the backend, a single `App.tsx` list/add/toggle/delete on the frontend) as a starting point to extend once the real test requirements are known.

## Notes / next steps

- CORS is restricted to `localhost:5173` / `127.0.0.1:5173` via `django-cors-headers` — update `CORS_ALLOWED_ORIGINS` in `backend/config/settings.py` if the frontend port changes.
- No auth wired up yet — add DRF token/session auth if the test requires it.
- Docker/docker-compose intentionally not added yet; add a `Dockerfile` per app + `docker-compose.yml` if the test calls for container parity.
