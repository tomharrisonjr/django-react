from __future__ import annotations

from flask import Flask
from flask_cors import CORS
from flask_migrate import Migrate

from .config import Config
from .models import db

migrate: Migrate = Migrate()


def create_app(config_class: type[Config] = Config) -> Flask:
    app = Flask(__name__)
    app.config.from_object(config_class)

    db.init_app(app)
    migrate.init_app(app, db)
    CORS(app, origins=app.config["CORS_ORIGINS"])

    from .tasks.routes import tasks_bp

    app.register_blueprint(tasks_bp, url_prefix="/api")

    return app
