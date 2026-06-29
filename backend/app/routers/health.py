from fastapi import APIRouter

from app.database import fetch_one

router = APIRouter(tags=["health"])


@router.get("/health")
def health_check():
    return {"status": "ok"}


@router.get("/health/db")
def database_health_check():
    row = fetch_one("SELECT 1 AS ok")
    return {"status": "ok", "database": row}
