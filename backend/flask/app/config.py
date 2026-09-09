from __future__ import annotations

from pathlib import Path

BASE_DIR: Path = Path(__file__).resolve().parent.parent
DB_PATH: Path = (BASE_DIR / ".." / "django" / "db.sqlite3").resolve()


class Config:
    SQLALCHEMY_DATABASE_URI: str = f"sqlite:///{DB_PATH}"
    SQLALCHEMY_TRACK_MODIFICATIONS: bool = False

    # CORS — allow the Vite dev server to call the API
    CORS_ORIGINS: list[str] = [
        "http://localhost:5173",
        "http://127.0.0.1:5173",
    ]
