import json
from decimal import Decimal
from typing import Literal

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field

from app.database import call_procedure, fetch_all, fetch_one

router = APIRouter(prefix="/compras", tags=["compras"])

MedioPagoCompra = Literal["EFECTIVO", "ELECTRONICO"]


class CompraDetalleRequest(BaseModel):
    idProducto: int
    cantidad: int = Field(gt=0)
    costoUnitario: Decimal = Field(ge=0)
    precioVenta: Decimal = Field(ge=0)
    codigoLote: str | None = Field(default="SIN_LOTE", max_length=80)
    fechaCaducidad: str | None = None


class RegistrarCompraRequest(BaseModel):
    idUsuario: int
    idProveedor: int | None = None
    folioProveedor: str | None = Field(default=None, max_length=80)
    descuento: Decimal = Field(default=Decimal("0.00"), ge=0)
    observaciones: str | None = Field(default=None, max_length=255)
    detalles: list[CompraDetalleRequest] = Field(min_length=1)
    medioPago: MedioPagoCompra | None = None
    montoPagado: Decimal = Field(default=Decimal("0.00"), ge=0)


class CancelarCompraRequest(BaseModel):
    idUsuario: int
    observaciones: str | None = Field(default=None, max_length=255)


@router.get("")
def listar_compras(
    estatus: Literal["REGISTRADA", "CANCELADA"] | None = None,
    id_proveedor: int | None = Query(default=None, alias="idProveedor"),
    limite: int = Query(default=100, ge=1, le=500),
):
    sql = """
        SELECT
            c.idCompra,
            c.folioProveedor,
            c.idProveedor,
            p.nombre AS proveedor,
            c.idUsuario,
            u.nombre AS usuario,
            c.fecha,
            c.subtotal,
            c.descuento,
            c.total,
            c.estatus,
            c.observaciones
        FROM compra c
        LEFT JOIN proveedor p ON p.idProveedor = c.idProveedor
        INNER JOIN usuario u ON u.idUsuario = c.idUsuario
    """
    filtros: list[str] = []
    params: list[object] = []

    if estatus:
        filtros.append("c.estatus = %s")
        params.append(estatus)

    if id_proveedor is not None:
        filtros.append("c.idProveedor = %s")
        params.append(id_proveedor)

    if filtros:
        sql += " WHERE " + " AND ".join(filtros)

    sql += " ORDER BY c.fecha DESC, c.idCompra DESC LIMIT %s"
    params.append(limite)
    return fetch_all(sql, params)


@router.get("/{id_compra}")
def obtener_compra(id_compra: int):
    compra = _obtener_compra(id_compra)

    if not compra:
        raise HTTPException(status_code=404, detail="Compra no encontrada")

    compra["detalles"] = fetch_all(
        """
        SELECT
            d.idCompraDetalle,
            d.idCompra,
            d.idProducto,
            p.nombre AS producto,
            d.idInventario,
            i.codigoLote,
            d.cantidad,
            d.costoUnitario,
            d.precioVentaSugerido,
            d.fechaCaducidad,
            d.subtotal
        FROM compra_detalle d
        INNER JOIN producto p ON p.idProducto = d.idProducto
        LEFT JOIN inventario_producto i ON i.idInventario = d.idInventario
        WHERE d.idCompra = %s
        ORDER BY d.idCompraDetalle
        """,
        [id_compra],
    )
    return compra


@router.post("", status_code=201)
def registrar_compra(request: RegistrarCompraRequest):
    detalles_json = json.dumps(
        [
            {
                "idProducto": detalle.idProducto,
                "cantidad": detalle.cantidad,
                "costoUnitario": str(detalle.costoUnitario),
                "precioVenta": str(detalle.precioVenta),
                "codigoLote": detalle.codigoLote or "SIN_LOTE",
                "fechaCaducidad": detalle.fechaCaducidad,
            }
            for detalle in request.detalles
        ]
    )

    result = call_procedure(
        "sp_registrar_compra",
        [
            request.idUsuario,
            request.idProveedor,
            request.folioProveedor,
            request.descuento,
            request.observaciones,
            detalles_json,
            request.medioPago,
            request.montoPagado,
        ],
        out_count=1,
    )
    id_compra = result.get("out_0")
    return obtener_compra(id_compra)


@router.post("/{id_compra}/cancelar")
def cancelar_compra(id_compra: int, request: CancelarCompraRequest):
    if not _obtener_compra(id_compra):
        raise HTTPException(status_code=404, detail="Compra no encontrada")

    call_procedure(
        "sp_cancelar_compra",
        [
            request.idUsuario,
            id_compra,
            request.observaciones,
        ],
    )
    return obtener_compra(id_compra)


def _obtener_compra(id_compra: int):
    return fetch_one(
        """
        SELECT
            c.idCompra,
            c.folioProveedor,
            c.idProveedor,
            p.nombre AS proveedor,
            c.idUsuario,
            u.nombre AS usuario,
            c.fecha,
            c.subtotal,
            c.descuento,
            c.total,
            c.estatus,
            c.observaciones
        FROM compra c
        LEFT JOIN proveedor p ON p.idProveedor = c.idProveedor
        INNER JOIN usuario u ON u.idUsuario = c.idUsuario
        WHERE c.idCompra = %s
        """,
        [id_compra],
    )
