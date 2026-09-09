from __future__ import annotations

from django.db.models import QuerySet
from rest_framework import viewsets

from .models import Task
from .serializers import TaskSerializer


class TaskViewSet(viewsets.ModelViewSet):
    queryset: QuerySet[Task] = Task.objects.all()
    serializer_class: type[TaskSerializer] = TaskSerializer
