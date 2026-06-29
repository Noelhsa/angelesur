from decimal import Decimal

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field

from app.database import call_procedure, fetch_all, fetch_one

router = APIRouter(prefix="/inventario", tags=["inventario"])


class AjustarInventarioRequest(BaseModel):
    idUsuario: int
    idInventario: int
    nuevoStock: int = Field(ge=0)
    motivo: str = Field(min_length=1, max_length=20)
    observaciones: str | None = Field(default=None, max_length=255)


class CambiarPrecioInventarioRequest(BaseModel):
    idUsuario: int
    idInventario: int
    precioNuevo: Decimal = Field(ge=0)
    motivo: str | None = Field(default=None, max_length=255)


@router.get("/disponible")
def listar_inventario_disponible(
    busqueda: str | None = Query(default=None, min_length=1),
    id_producto: int | None = Query(default=None, alias="idProducto"),
    limite: int = Query(default=100, ge=1, le=500),
):
    sql = "SELECT * FROM vw_inventario_disponible_para_venta"
    filtros: list[str] = []
    params: list[object] = []

    if busqueda:
        filtros.append("(nombre LIKE %s OR codigoBarras LIKE %s OR categoria LIKE %s)")
        like = f"%{busqueda}%"
        params.extend([like, like, like])

    if id_producto is not None:
        filtros.append("idProducto = %s")
        params.append(id_producto)

    if filtros:
        sql += " WHERE " + " AND ".join(filtros)

    sql += " LIMIT %s"
    params.append(limite)
    return fetch_all(sql, params)


@router.get("/actual")
def listar_inventario_actual(
    busqueda: str | None = Query(default=None, min_length=1),
    id_producto: int | None = Query(default=None, alias="idProducto"),
    solo_activos: bool = Query(default=True, alias="soloActivos"),
    limite: int = Query(default=200, ge=1, le=1000),
):
    sql = "SELECT * FROM vw_inventario_actual"
    filtros: list[str] = []
    params: list[object] = []

    if solo_activos:
        filtros.append("inventarioActivo = %s AND productoActivo = %s")
        params.extend([1, 1])

    if id_producto is not None:
        filtros.append("idProducto = %s")
        params.append(id_producto)

    if busqueda:
        filtros.append("(nombre LIKE %s OR codigoBarras LIKE %s OR codigoLote LIKE %s)")
        like = f"%{busqueda}%"
        params.extend([like, like, like])

    if filtros:
        sql += " WHERE " + " AND ".join(filtros)

    sql += " ORDER BY nombre, fechaCaducidad, idInventario LIMIT %s"
    params.append(limite)
    return fetch_all(sql, params)


@router.get("/caducidad")
def listar_productos_por_caducar(
    limite: int = Query(default=100, ge=1, le=500),
):
    return fetch_all(
        "SELECT * FROM vw_productos_por_caducar LIMIT %s",
        [limite],
    )


@router.get("/movimientos")
def listar_movimientos_inventario(
    id_inventario: int | None = Query(default=None, alias="idInventario"),
    id_producto: int | None = Query(default=None, alias="idProducto"),
    limite: int = Query(default=200, ge=1, le=1000),
):
    sql = """
        SELECT
            m.idMovInv,
            m.idUsuario,
            u.nombre AS usuario,
            m.idInventario,
            i.idProducto,
            p.nombre AS producto,
            i.codigoLote,
            m.tipo,
            m.motivo,
            m.cantidad,
            m.stockAntes,
            m.stockDespues,
            m.fecha,
            m.idVentaDetalle,
            m.idCompraDetalle,
            m.idDevolucionClienteDetalle,
            m.idDevolucionProveedorDetalle,
            m.observaciones
        FROM movimiento_inventario m
        INNER JOIN inventario_producto i ON i.idInventario = m.idInventario
        INNER JOIN producto p ON p.idProducto = i.idProducto
        INNER JOIN usuario u ON u.idUsuario = m.idUsuario
    """
    filtros: list[str] = []
    params: list[object] = []

    if id_inventario is not None:
        filtros.append("m.idInventario = %s")
        params.append(id_inventario)

    if id_producto is not None:
        filtros.append("i.idProducto = %s")
        params.append(id_producto)

    if filtros:
        sql += " WHERE " + " AND ".join(filtros)

    sql += " ORDER BY m.fecha DESC, m.idMovInv DESC LIMIT %s"
    params.append(limite)
    return fetch_all(sql, params)


@router.get("/historial-precios")
def listar_historial_precios(
    id_inventario: int | None = Query(default=None, alias="idInventario"),
    id_producto: int | None = Query(default=None, alias="idProducto"),
    limite: int = Query(default=200, ge=1, le=1000),
):
    sql = """
        SELECT
            h.idHistorialPrecio,
            h.idProducto,
            p.nombre AS producto,
            h.idInventario,
            i.codigoLote,
            h.precioAnterior,
            h.precioNuevo,
            h.motivo,
            h.idUsuario,
            u.nombre AS usuario,
            h.fecha
        FROM historial_precio_producto h
        INNER JOIN producto p ON p.idProducto = h.idProducto
        LEFT JOIN inventario_producto i ON i.idInventario = h.idInventario
        INNER JOIN usuario u ON u.idUsuario = h.idUsuario
    """
    filtros: list[str] = []
    params: list[object] = []

    if id_inventario is not None:
        filtros.append("h.idInventario = %s")
        params.append(id_inventario)

    if id_producto is not None:
        filtros.append("h.idProducto = %s")
        params.append(id_producto)

    if filtros:
        sql += " WHERE " + " AND ".join(filtros)

    sql += " ORDER BY h.fecha DESC, h.idHistorialPrecio DESC LIMIT %s"
    params.append(limite)
    return fetch_all(sql, params)


@router.get("/{id_inventario}")
def obtener_inventario(id_inventario: int):
    inventario = _obtener_inventario_actual(id_inventario)

    if not inventario:
        raise HTTPException(status_code=404, detail="Inventario no encontrado")

    return inventario


@router.post("/ajuste")
def ajustar_inventario(request: AjustarInventarioRequest):
    if not _obtener_inventario_actual(request.idInventario):
        raise HTTPException(status_code=404, detail="Inventario no encontrado")

    call_procedure(
        "sp_ajustar_inventario",
        [
            request.idUsuario,
            request.idInventario,
            request.nuevoStock,
            request.motivo,
            request.observaciones,
        ],
    )

    return _obtener_inventario_actual(request.idInventario)


@router.post("/precio")
def cambiar_precio_inventario(request: CambiarPrecioInventarioRequest):
    if not _obtener_inventario_actual(request.idInventario):
        raise HTTPException(status_code=404, detail="Inventario no encontrado")

    call_procedure(
        "sp_cambiar_precio_inventario",
        [
            request.idUsuario,
            request.idInventario,
            request.precioNuevo,
            request.motivo,
        ],
    )

    return _obtener_inventario_actual(request.idInventario)


def _obtener_inventario_actual(id_inventario: int):
    return fetch_one(
        "SELECT * FROM vw_inventario_actual WHERE idInventario = %s",
        [id_inventario],
    )
