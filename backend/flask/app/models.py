from __future__ import annotations

import datetime

from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.orm import Mapped, mapped_column

db: SQLAlchemy = SQLAlchemy()


class Task(db.Model):
    # Own table, distinct from Django's `tasks_task`, so both backends can
    # share the same SQLite file without their migrations colliding.
    __tablename__ = "flask_task"

    id: Mapped[int] = mapped_column(primary_key=True)
    title: Mapped[str] = mapped_column(db.String(200))
    done: Mapped[bool] = mapped_column(default=False)
    created_at: Mapped[datetime.datetime] = mapped_column(
        default=lambda: datetime.datetime.now(datetime.UTC)
    )

    def __str__(self) -> str:
        return self.title
