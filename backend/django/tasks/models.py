from __future__ import annotations

import datetime

from django.db import models


class Task(models.Model):
    title: models.CharField[str] = models.CharField(max_length=200)
    done: models.BooleanField[bool] = models.BooleanField(default=False)
    created_at: models.DateTimeField[datetime.datetime] = models.DateTimeField(
        auto_now_add=True
    )

    class Meta:
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return self.title
