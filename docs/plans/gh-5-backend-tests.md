# Backend API Unit Tests

- Date: 2026-09-05
- GitHub Issue: #5
- Status: Complete

## Context

Issue #5 asks for "any basic unit test" on the backend. The `tasks` app currently has no tests (`backend/tasks/tests.py` is just the scaffold comment), so the `Task` CRUD API (`GET/POST/PUT/PATCH/DELETE /api/tasks/`) has no automated coverage. This adds a test suite that exercises the API end-to-end through DRF's test client, plus a couple of model-level checks, so regressions in the viewset/serializer/model are caught by `python manage.py test`.

## Current API surface (for reference)

- `tasks/models.py`: `Task(title: CharField, done: BooleanField=False, created_at: auto_now_add)`, ordered by `-created_at`.
- `tasks/serializers.py`: `TaskSerializer` — fields `id, title, done, created_at`; `id`/`created_at` read-only.
- `tasks/views.py`: `TaskViewSet(viewsets.ModelViewSet)` — full CRUD, no custom permissions (defaults to DRF's `AllowAny`).
- `tasks/urls.py`: registered on a `DefaultRouter` at `tasks` → `/api/tasks/`.
- `REST_FRAMEWORK` settings use `PageNumberPagination` (`PAGE_SIZE=20`), so list responses are paginated (`count/next/previous/results`).

## Approach

Replace the contents of `backend/tasks/tests.py` with a `TaskAPITests(APITestCase)` class (from `rest_framework.test`), matching the existing repo convention of one `tests.py` per app. Cover:

1. **List** — `GET /api/tasks/` returns 200 and the paginated `results` list, reflecting created fixtures.
2. **Create** — `POST /api/tasks/` with `{"title": "..."}` returns 201, persists a row, defaults `done=False`, and ignores a client-supplied `id`/`created_at` (read-only).
3. **Create validation** — `POST /api/tasks/` with no `title` returns 400.
4. **Retrieve** — `GET /api/tasks/{id}/` returns the matching task.
5. **Retrieve missing** — `GET /api/tasks/{id}/` for a non-existent id returns 404.
6. **Partial update** — `PATCH /api/tasks/{id}/` with `{"done": true}` toggles the flag and leaves `title` unchanged.
7. **Delete** — `DELETE /api/tasks/{id}/` returns 204 and the row is gone from the DB.
8. **Model ordering** — creating tasks out of order returns them newest-first (`-created_at`), and `str(task)` returns the title.

Use `reverse("task-list")` / `reverse("task-detail", args=[pk])` (DRF router default basename `task`, derived from `Task.objects.all()`) rather than hardcoded URLs, so the test survives URL changes. Use `self.client.post(url, data, format="json")` per DRF's `APITestCase` conventions — no new dependencies needed (`djangorestframework` is already installed and includes `rest_framework.test`).

## Files touched

- `backend/tasks/tests.py` — full test suite (only file modified).

## Verification

1. `cd backend && source venv/bin/activate && python manage.py test` — all new tests pass.
2. `ruff check .` — lint clean.
3. Update this plan doc's `Status` to `Complete` once merged (per CLAUDE.md PR checklist); no README changes are needed since this doesn't change runtime behavior or commands.
