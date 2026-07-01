from decimal import Decimal
from typing import Literal

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field

from app.database import call_procedure, fetch_all, fetch_one

router = APIRouter(prefix="/caja", tags=["caja"])

MedioDinero = Literal["EFECTIVO", "ELECTRONICO"]
TipoMovimientoDinero = Literal["ENTRADA", "SALIDA"]
ConceptoMovimientoDinero = Literal[
    "VENTA_PRODUCTO",
    "SERVICIO_YASTAS",
    "COMPRA_MERCANCIA",
    "DEPOSITO_YASTAS",
    "RETIRO_CAJA",
    "AJUSTE",
    "CANCELACION",
    "APERTURA",
    "DEVOLUCION_CLIENTE",
    "DEVOLUCION_PROVEEDOR",
    "OTRO",
]


class RegistrarMovimientoCajaRequest(BaseModel):
    idUsuario: int
    medio: MedioDinero
    tipo: TipoMovimientoDinero
    concepto: ConceptoMovimientoDinero
    monto: Decimal = Field(gt=0)
    idCompra: int | None = None
    observaciones: str | None = Field(default=None, max_length=255)


@router.get("/movimientos")
def listar_movimientos_caja(
    id_corte: int | None = Query(default=None, alias="idCorte"),
    medio: MedioDinero | None = None,
    tipo: TipoMovimientoDinero | None = None,
    concepto: ConceptoMovimientoDinero | None = None,
    limite: int = Query(default=200, ge=1, le=1000),
):
    sql = _select_movimientos_sql()
    filtros: list[str] = []
    params: list[object] = []

    if id_corte is not None:
        filtros.append("m.idCorte = %s")
        params.append(id_corte)

    if medio:
        filtros.append("m.medio = %s")
        params.append(medio)

    if tipo:
        filtros.append("m.tipo = %s")
        params.append(tipo)

    if concepto:
        filtros.append("m.concepto = %s")
        params.append(concepto)

    if filtros:
        sql += " WHERE " + " AND ".join(filtros)

    sql += " ORDER BY m.fecha DESC, m.idMovDin DESC LIMIT %s"
    params.append(limite)
    return fetch_all(sql, params)


@router.get("/movimientos/{id_movimiento}")
def obtener_movimiento_caja(id_movimiento: int):
    movimiento = _obtener_movimiento_caja(id_movimiento)

    if not movimiento:
        raise HTTPException(status_code=404, detail="Movimiento de caja no encontrado")

    return movimiento


@router.post("/movimiento", status_code=201)
def registrar_movimiento_caja(request: RegistrarMovimientoCajaRequest):
    result = call_procedure(
        "sp_registrar_movimiento_caja",
        [
            request.idUsuario,
            request.medio,
            request.tipo,
            request.concepto,
            request.monto,
            request.idCompra,
            request.observaciones,
        ],
        out_count=1,
    )
    id_movimiento = result.get("out_0")
    return obtener_movimiento_caja(id_movimiento)


@router.get("/saldo/actual")
def obtener_saldo_corte_actual():
    corte = fetch_one("SELECT * FROM vw_corte_resumen WHERE estado = 'ABIERTO' LIMIT 1")

    if not corte:
        raise HTTPException(status_code=404, detail="No hay corte abierto")

    return corte


def _obtener_movimiento_caja(id_movimiento: int):
    return fetch_one(
        _select_movimientos_sql() + " WHERE m.idMovDin = %s",
        [id_movimiento],
    )


def _select_movimientos_sql() -> str:
    return """
        SELECT
            m.idMovDin,
            m.idCorte,
            m.idUsuario,
            u.nombre AS usuario,
            m.medio,
            m.tipo,
            m.concepto,
            m.monto,
            m.fecha,
            m.idVenta,
            m.idPagoVenta,
            m.idServicioOperacion,
            m.idCompra,
            m.idDevolucionCliente,
            m.idDevolucionProveedor,
            m.observaciones
        FROM movimiento_dinero m
        INNER JOIN usuario u ON u.idUsuario = m.idUsuario
    """
