from collections.abc import Sequence
from contextlib import contextmanager
from typing import Any

import pymysql
from pymysql.cursors import DictCursor

from app.config import get_settings


@contextmanager
def db_connection():
    settings = get_settings()
    connection = pymysql.connect(
        host=settings.db_host,
        port=settings.db_port,
        user=settings.db_user,
        password=settings.db_password,
        database=settings.db_name,
        charset="utf8mb4",
        cursorclass=DictCursor,
        autocommit=False,
    )

    try:
        yield connection
        connection.commit()
    except Exception:
        connection.rollback()
        raise
    finally:
        connection.close()


def fetch_all(sql: str, params: Sequence[Any] | None = None) -> list[dict[str, Any]]:
    with db_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(sql, params or ())
            return list(cursor.fetchall())


def fetch_one(sql: str, params: Sequence[Any] | None = None) -> dict[str, Any] | None:
    rows = fetch_all(sql, params)
    return rows[0] if rows else None


def call_procedure(
    name: str,
    in_args: Sequence[Any] | None = None,
    out_count: int = 0,
) -> dict[str, Any]:
    in_args = list(in_args or [])
    out_vars = [f"@out_{index}" for index in range(out_count)]
    placeholders = ["%s" for _ in in_args] + out_vars
    sql = f"CALL `{name}`({', '.join(placeholders)})"

    with db_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(sql, in_args)

            while cursor.nextset():
                pass

            if not out_vars:
                return {}

            cursor.execute(
                "SELECT "
                + ", ".join(f"{out_var} AS out_{index}" for index, out_var in enumerate(out_vars))
            )
            return dict(cursor.fetchone() or {})
