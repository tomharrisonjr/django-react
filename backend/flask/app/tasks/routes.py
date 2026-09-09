from __future__ import annotations

from flask import Blueprint, Response, jsonify, request, url_for

from ..models import Task, db
from ..schemas import serialize_task

tasks_bp: Blueprint = Blueprint("tasks", __name__)

PAGE_SIZE: int = 20


@tasks_bp.route("/tasks/", methods=["GET"])
def list_tasks() -> Response:
    page = request.args.get("page", default=1, type=int)
    pagination = Task.query.order_by(Task.created_at.desc()).paginate(
        page=page, per_page=PAGE_SIZE, error_out=False
    )

    def page_url(page_number: int | None) -> str | None:
        if page_number is None:
            return None
        return url_for("tasks.list_tasks", page=page_number, _external=True)

    return jsonify(
        {
            "count": pagination.total,
            "next": page_url(pagination.next_num if pagination.has_next else None),
            "previous": page_url(
                pagination.prev_num if pagination.has_prev else None
            ),
            "results": [serialize_task(task) for task in pagination.items],
        }
    )


@tasks_bp.route("/tasks/", methods=["POST"])
def create_task() -> tuple[Response, int]:
    data = request.get_json(silent=True) or {}
    title = data.get("title")
    if not title:
        return jsonify({"title": ["This field is required."]}), 400

    task = Task(title=title, done=bool(data.get("done", False)))
    db.session.add(task)
    db.session.commit()
    return jsonify(serialize_task(task)), 201


@tasks_bp.route("/tasks/<int:task_id>/", methods=["GET"])
def retrieve_task(task_id: int) -> tuple[Response, int] | Response:
    task = db.session.get(Task, task_id)
    if task is None:
        return jsonify({"detail": "Not found."}), 404
    return jsonify(serialize_task(task))


@tasks_bp.route("/tasks/<int:task_id>/", methods=["PATCH"])
def update_task(task_id: int) -> tuple[Response, int] | Response:
    task = db.session.get(Task, task_id)
    if task is None:
        return jsonify({"detail": "Not found."}), 404

    data = request.get_json(silent=True) or {}
    if "title" in data:
        task.title = data["title"]
    if "done" in data:
        task.done = bool(data["done"])
    db.session.commit()
    return jsonify(serialize_task(task))


@tasks_bp.route("/tasks/<int:task_id>/", methods=["DELETE"])
def delete_task(task_id: int) -> tuple[str, int] | tuple[Response, int]:
    task = db.session.get(Task, task_id)
    if task is None:
        return jsonify({"detail": "Not found."}), 404

    db.session.delete(task)
    db.session.commit()
    return "", 204
