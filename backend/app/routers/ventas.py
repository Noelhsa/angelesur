import json
from decimal import Decimal
from typing import Literal

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field

from app.database import call_procedure, fetch_all, fetch_one

router = APIRouter(prefix="/ventas", tags=["ventas"])


class VentaDetalleRequest(BaseModel):
    id_inventario: int = Field(alias="idInventario")
    cantidad: int = Field(gt=0)
    descuento: Decimal = Decimal("0.00")


class VentaPagoRequest(BaseModel):
    medio: Literal["EFECTIVO", "ELECTRONICO", "TARJETA", "TRANSFERENCIA", "OTRO"]
    monto: Decimal = Field(gt=0)
    referencia: str | None = ""


class RegistrarVentaRequest(BaseModel):
    id_usuario: int = Field(alias="idUsuario")
    descuento_general: Decimal = Field(default=Decimal("0.00"), alias="descuentoGeneral")
    monto_recibido: Decimal | None = Field(default=None, alias="montoRecibido")
    observaciones: str | None = None
    detalles: list[VentaDetalleRequest]
    pagos: list[VentaPagoRequest]


class CancelarVentaRequest(BaseModel):
    idUsuario: int
    observaciones: str | None = Field(default=None, max_length=255)


@router.get("")
def listar_ventas(
    estatus: Literal["PAGADA", "CANCELADA"] | None = None,
    id_corte: int | None = Query(default=None, alias="idCorte"),
    id_usuario: int | None = Query(default=None, alias="idUsuario"),
    folio: str | None = Query(default=None, min_length=1),
    limite: int = Query(default=100, ge=1, le=500),
):
    sql = _select_ventas_sql()
    filtros: list[str] = []
    params: list[object] = []

    if estatus:
        filtros.append("v.estatus = %s")
        params.append(estatus)

    if id_corte is not None:
        filtros.append("v.idCorte = %s")
        params.append(id_corte)

    if id_usuario is not None:
        filtros.append("v.idUsuario = %s")
        params.append(id_usuario)

    if folio:
        filtros.append("v.folio LIKE %s")
        params.append(f"%{folio}%")

    if filtros:
        sql += " WHERE " + " AND ".join(filtros)

    sql += " ORDER BY v.fecha DESC, v.idVenta DESC LIMIT %s"
    params.append(limite)
    return fetch_all(sql, params)


@router.get("/{id_venta}")
def obtener_venta(id_venta: int):
    venta = _obtener_venta(id_venta)

    if not venta:
        raise HTTPException(status_code=404, detail="Venta no encontrada")

    venta["detalles"] = fetch_all(
        """
        SELECT
            d.idVentaDetalle,
            d.idVenta,
            d.idInventario,
            i.idProducto,
            p.nombre AS producto,
            i.codigoLote,
            i.fechaCaducidad,
            d.cantidad,
            d.precioUnitario,
            d.costoUnitario,
            d.descuento,
            d.subtotal
        FROM venta_detalle d
        INNER JOIN inventario_producto i ON i.idInventario = d.idInventario
        INNER JOIN producto p ON p.idProducto = i.idProducto
        WHERE d.idVenta = %s
        ORDER BY d.idVentaDetalle
        """,
        [id_venta],
    )
    venta["pagos"] = _listar_pagos_venta(id_venta)
    return venta


@router.get("/{id_venta}/pagos")
def listar_pagos_venta(id_venta: int):
    if not _obtener_venta(id_venta):
        raise HTTPException(status_code=404, detail="Venta no encontrada")

    return _listar_pagos_venta(id_venta)


@router.post("")
def registrar_venta(request: RegistrarVentaRequest):
    detalles_json = json.dumps(
        [
            {
                "idInventario": detalle.id_inventario,
                "cantidad": detalle.cantidad,
                "descuento": str(detalle.descuento),
            }
            for detalle in request.detalles
        ]
    )
    pagos_json = json.dumps(
        [
            {
                "medio": pago.medio,
                "monto": str(pago.monto),
                "referencia": pago.referencia or "",
            }
            for pago in request.pagos
        ]
    )

    result = call_procedure(
        "sp_registrar_venta",
        [
            request.id_usuario,
            request.descuento_general,
            request.monto_recibido,
            request.observaciones,
            detalles_json,
            pagos_json,
        ],
        out_count=2,
    )

    return obtener_venta(result.get("out_0"))


@router.post("/{id_venta}/cancelar")
def cancelar_venta(id_venta: int, request: CancelarVentaRequest):
    if not _obtener_venta(id_venta):
        raise HTTPException(status_code=404, detail="Venta no encontrada")

    call_procedure(
        "sp_cancelar_venta",
        [
            request.idUsuario,
            id_venta,
            request.observaciones,
        ],
    )
    return obtener_venta(id_venta)


def _obtener_venta(id_venta: int):
    return fetch_one(
        _select_ventas_sql() + " WHERE v.idVenta = %s",
        [id_venta],
    )


def _listar_pagos_venta(id_venta: int):
    return fetch_all(
        """
        SELECT
            idPagoVenta,
            idVenta,
            medio,
            monto,
            referencia,
            fecha
        FROM pago_venta
        WHERE idVenta = %s
        ORDER BY idPagoVenta
        """,
        [id_venta],
    )


def _select_ventas_sql() -> str:
    return """
        SELECT
            v.idVenta,
            v.folio,
            v.idUsuario,
            u.nombre AS usuario,
            v.idCorte,
            v.fecha,
            v.subtotal,
            v.descuento,
            v.total,
            v.montoRecibido,
            v.cambio,
            v.estatus,
            v.observaciones,
            v.created_at
        FROM venta v
        INNER JOIN usuario u ON u.idUsuario = v.idUsuario
    """
