from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from .models import Task


class TaskAPITests(APITestCase):
    def test_list_tasks(self):
        Task.objects.create(title="Write tests")
        Task.objects.create(title="Ship feature")

        response = self.client.get(reverse("task-list"))

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["results"]), 2)

    def test_create_task(self):
        response = self.client.post(
            reverse("task-list"), {"title": "New task"}, format="json"
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Task.objects.count(), 1)
        task = Task.objects.get()
        self.assertEqual(task.title, "New task")
        self.assertFalse(task.done)

    def test_create_task_ignores_client_supplied_read_only_fields(self):
        response = self.client.post(
            reverse("task-list"),
            {"title": "New task", "id": 999, "created_at": "2020-01-01T00:00:00Z"},
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        task = Task.objects.get()
        self.assertNotEqual(task.id, 999)

    def test_create_task_requires_title(self):
        response = self.client.post(reverse("task-list"), {}, format="json")

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(Task.objects.count(), 0)

    def test_retrieve_task(self):
        task = Task.objects.create(title="Read me")

        response = self.client.get(reverse("task-detail", args=[task.id]))

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["title"], "Read me")

    def test_retrieve_missing_task_returns_404(self):
        response = self.client.get(reverse("task-detail", args=[999]))

        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_partial_update_toggles_done(self):
        task = Task.objects.create(title="Toggle me", done=False)

        response = self.client.patch(
            reverse("task-detail", args=[task.id]), {"done": True}, format="json"
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        task.refresh_from_db()
        self.assertTrue(task.done)
        self.assertEqual(task.title, "Toggle me")

    def test_delete_task(self):
        task = Task.objects.create(title="Delete me")

        response = self.client.delete(reverse("task-detail", args=[task.id]))

        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertEqual(Task.objects.count(), 0)


class TaskModelTests(APITestCase):
    def test_string_representation_is_title(self):
        task = Task.objects.create(title="A task")

        self.assertEqual(str(task), "A task")

    def test_default_ordering_is_newest_first(self):
        older = Task.objects.create(title="Older")
        newer = Task.objects.create(title="Newer")

        self.assertEqual(list(Task.objects.all()), [newer, older])
