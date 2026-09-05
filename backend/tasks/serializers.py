from rest_framework import serializers

from .models import Task


class TaskSerializer(serializers.ModelSerializer):
    class Meta:
        model: type[Task] = Task
        fields: list[str] = ["id", "title", "done", "created_at"]
        read_only_fields: list[str] = ["id", "created_at"]
