from __future__ import annotations

import unittest

from app import create_app
from app.config import Config
from app.models import Task, db


class TestConfig(Config):
    SQLALCHEMY_DATABASE_URI: str = "sqlite:///:memory:"
    TESTING: bool = True


class TaskAPITests(unittest.TestCase):
    def setUp(self) -> None:
        self.app = create_app(TestConfig)
        self.client = self.app.test_client()
        self.ctx = self.app.app_context()
        self.ctx.push()
        db.create_all()

    def tearDown(self) -> None:
        db.session.remove()
        db.drop_all()
        self.ctx.pop()

    def test_list_tasks(self) -> None:
        db.session.add_all(
            [Task(title="Write tests"), Task(title="Ship feature")]
        )
        db.session.commit()

        response = self.client.get("/api/tasks/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.get_json()["results"]), 2)

    def test_create_task(self) -> None:
        response = self.client.post("/api/tasks/", json={"title": "New task"})

        self.assertEqual(response.status_code, 201)
        self.assertEqual(Task.query.count(), 1)
        task = Task.query.one()
        self.assertEqual(task.title, "New task")
        self.assertFalse(task.done)

    def test_create_task_ignores_client_supplied_read_only_fields(self) -> None:
        response = self.client.post(
            "/api/tasks/",
            json={"title": "New task", "id": 999, "created_at": "2020-01-01T00:00:00Z"},
        )

        self.assertEqual(response.status_code, 201)
        task = Task.query.one()
        self.assertNotEqual(task.id, 999)

    def test_create_task_requires_title(self) -> None:
        response = self.client.post("/api/tasks/", json={})

        self.assertEqual(response.status_code, 400)
        self.assertEqual(Task.query.count(), 0)

    def test_retrieve_task(self) -> None:
        task = Task(title="Read me")
        db.session.add(task)
        db.session.commit()

        response = self.client.get(f"/api/tasks/{task.id}/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json()["title"], "Read me")

    def test_retrieve_missing_task_returns_404(self) -> None:
        response = self.client.get("/api/tasks/999/")

        self.assertEqual(response.status_code, 404)

    def test_partial_update_toggles_done(self) -> None:
        task = Task(title="Toggle me", done=False)
        db.session.add(task)
        db.session.commit()

        response = self.client.patch(f"/api/tasks/{task.id}/", json={"done": True})

        self.assertEqual(response.status_code, 200)
        db.session.refresh(task)
        self.assertTrue(task.done)
        self.assertEqual(task.title, "Toggle me")

    def test_partial_update_rejects_blank_title(self) -> None:
        task = Task(title="Keep me", done=False)
        db.session.add(task)
        db.session.commit()

        response = self.client.patch(f"/api/tasks/{task.id}/", json={"title": ""})

        self.assertEqual(response.status_code, 400)
        db.session.refresh(task)
        self.assertEqual(task.title, "Keep me")

    def test_create_task_parses_string_done_value(self) -> None:
        response = self.client.post(
            "/api/tasks/", json={"title": "New task", "done": "false"}
        )

        self.assertEqual(response.status_code, 201)
        task = Task.query.one()
        self.assertFalse(task.done)

    def test_partial_update_parses_string_done_value(self) -> None:
        task = Task(title="Toggle me", done=True)
        db.session.add(task)
        db.session.commit()

        response = self.client.patch(
            f"/api/tasks/{task.id}/", json={"done": "false"}
        )

        self.assertEqual(response.status_code, 200)
        db.session.refresh(task)
        self.assertFalse(task.done)

    def test_list_tasks_out_of_range_page_returns_404(self) -> None:
        db.session.add(Task(title="Only task"))
        db.session.commit()

        response = self.client.get("/api/tasks/?page=2")

        self.assertEqual(response.status_code, 404)

    def test_list_tasks_invalid_page_returns_404(self) -> None:
        response = self.client.get("/api/tasks/?page=0")

        self.assertEqual(response.status_code, 404)

    def test_list_tasks_empty_first_page_returns_200(self) -> None:
        response = self.client.get("/api/tasks/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json()["results"], [])

    def test_delete_task(self) -> None:
        task = Task(title="Delete me")
        db.session.add(task)
        db.session.commit()

        response = self.client.delete(f"/api/tasks/{task.id}/")

        self.assertEqual(response.status_code, 204)
        self.assertEqual(Task.query.count(), 0)


class TaskModelTests(unittest.TestCase):
    def setUp(self) -> None:
        self.app = create_app(TestConfig)
        self.ctx = self.app.app_context()
        self.ctx.push()
        db.create_all()

    def tearDown(self) -> None:
        db.session.remove()
        db.drop_all()
        self.ctx.pop()

    def test_string_representation_is_title(self) -> None:
        task = Task(title="A task")

        self.assertEqual(str(task), "A task")

    def test_default_ordering_is_newest_first(self) -> None:
        older = Task(title="Older")
        db.session.add(older)
        db.session.commit()
        newer = Task(title="Newer")
        db.session.add(newer)
        db.session.commit()

        self.assertEqual(
            Task.query.order_by(Task.created_at.desc()).all(), [newer, older]
        )


if __name__ == "__main__":
    unittest.main()
