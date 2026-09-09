from __future__ import annotations

from .models import Task


def serialize_task(task: Task) -> dict[str, object]:
    # SQLite has no timezone-aware storage, so SQLAlchemy always hands back a
    # naive datetime here — it's UTC (see Task.created_at's default), so
    # format it as such to match Django's ISO-8601-with-Z convention.
    created_at = task.created_at
    if created_at.tzinfo is not None:
        created_at = created_at.replace(tzinfo=None)
    return {
        "id": task.id,
        "title": task.title,
        "done": task.done,
        "created_at": created_at.isoformat() + "Z",
    }
