from fastapi import APIRouter, Query

from app.database import fetch_all

router = APIRouter(prefix="/inventario", tags=["inventario"])


@router.get("/disponible")
def listar_inventario_disponible(
    busqueda: str | None = Query(default=None, min_length=1),
    limite: int = Query(default=100, ge=1, le=500),
):
    sql = "SELECT * FROM vw_inventario_disponible_para_venta"
    params: list[object] = []

    if busqueda:
        sql += " WHERE nombre LIKE %s OR codigoBarras LIKE %s OR categoria LIKE %s"
        like = f"%{busqueda}%"
        params.extend([like, like, like])

    sql += " LIMIT %s"
    params.append(limite)
    return fetch_all(sql, params)


@router.get("/actual")
def listar_inventario_actual(limite: int = Query(default=200, ge=1, le=1000)):
    return fetch_all("SELECT * FROM vw_inventario_actual LIMIT %s", [limite])


@router.get("/caducidad")
def listar_productos_por_caducar(limite: int = Query(default=100, ge=1, le=500)):
    return fetch_all("SELECT * FROM vw_productos_por_caducar LIMIT %s", [limite])
