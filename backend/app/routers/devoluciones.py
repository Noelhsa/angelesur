import json
from datetime import date
from decimal import Decimal
from typing import Literal

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field

from app.database import call_procedure, fetch_all, fetch_one

router = APIRouter(prefix="/devoluciones", tags=["devoluciones"])

MotivoDevolucionCliente = Literal[
    "PRODUCTO_EQUIVOCADO",
    "PRODUCTO_DANADO",
    "CADUCADO",
    "ERROR_VENTA",
    "CLIENTE_SE_ARREPINTIO",
    "OTRO",
]
MetodoDevolucionCliente = Literal[
    "EFECTIVO",
    "ELECTRONICO",
    "CAMBIO_PRODUCTO",
    "SIN_DEVOLUCION_DINERO",
]
MotivoDevolucionProveedor = Literal[
    "PRODUCTO_DANADO",
    "CADUCADO",
    "ERROR_COMPRA",
    "EXCEDENTE",
    "CAMBIO_PRECIO",
    "OTRO",
]
TipoCompensacionProveedor = Literal[
    "EFECTIVO",
    "ELECTRONICO",
    "NOTA_CREDITO",
    "REPOSICION_PRODUCTO",
    "SIN_COMPENSACION",
]
EstatusDevolucion = Literal["REGISTRADA", "CANCELADA"]


class DevolucionClienteDetalleRequest(BaseModel):
    idVentaDetalle: int
    cantidad: int = Field(gt=0)
    regresaAInventario: bool = True
    motivoDetalle: str | None = Field(default=None, max_length=120)
    observaciones: str | None = Field(default=None, max_length=255)


class RegistrarDevolucionClienteRequest(BaseModel):
    idUsuario: int
    idVenta: int
    metodoDevolucion: MetodoDevolucionCliente = "EFECTIVO"
    motivo: MotivoDevolucionCliente = "OTRO"
    observaciones: str | None = Field(default=None, max_length=255)
    detalles: list[DevolucionClienteDetalleRequest] = Field(min_length=1)


class DevolucionProveedorDetalleRequest(BaseModel):
    idCompraDetalle: int | None = None
    idInventario: int
    cantidad: int = Field(gt=0)
    motivoDetalle: str | None = Field(default=None, max_length=120)
    observaciones: str | None = Field(default=None, max_length=255)


class ReposicionProveedorDetalleRequest(BaseModel):
    idProducto: int
    cantidad: int = Field(gt=0)
    costoUnitario: Decimal = Field(ge=0)
    precioVenta: Decimal = Field(ge=0)
    codigoLote: str | None = Field(default="REPOSICION", max_length=80)
    fechaCaducidad: str | None = None


class RegistrarDevolucionProveedorRequest(BaseModel):
    idUsuario: int
    idCompra: int | None = None
    idProveedor: int | None = None
    tipoCompensacion: TipoCompensacionProveedor = "SIN_COMPENSACION"
    motivo: MotivoDevolucionProveedor = "OTRO"
    observaciones: str | None = Field(default=None, max_length=255)
    detalles: list[DevolucionProveedorDetalleRequest] = Field(min_length=1)
    reposicionDetalles: list[ReposicionProveedorDetalleRequest] | None = None


class CancelarDevolucionRequest(BaseModel):
    idUsuario: int
    observaciones: str | None = Field(default=None, max_length=255)


@router.get("/clientes")
def listar_devoluciones_cliente(
    estatus: EstatusDevolucion | None = None,
    id_venta: int | None = Query(default=None, alias="idVenta"),
    id_corte: int | None = Query(default=None, alias="idCorte"),
    limite: int = Query(default=100, ge=1, le=500),
):
    sql = _select_devoluciones_cliente_sql()
    filtros: list[str] = []
    params: list[object] = []

    if estatus:
        filtros.append("d.estatus = %s")
        params.append(estatus)

    if id_venta is not None:
        filtros.append("d.idVenta = %s")
        params.append(id_venta)

    if id_corte is not None:
        filtros.append("d.idCorte = %s")
        params.append(id_corte)

    if filtros:
        sql += " WHERE " + " AND ".join(filtros)

    sql += " ORDER BY d.fecha DESC, d.idDevolucionCliente DESC LIMIT %s"
    params.append(limite)
    return fetch_all(sql, params)


@router.get("/clientes/{id_devolucion_cliente}")
def obtener_devolucion_cliente(id_devolucion_cliente: int):
    devolucion = _obtener_devolucion_cliente(id_devolucion_cliente)

    if not devolucion:
        raise HTTPException(status_code=404, detail="Devolucion de cliente no encontrada")

    devolucion["detalles"] = fetch_all(
        """
        SELECT
            d.idDevolucionClienteDetalle,
            d.idDevolucionCliente,
            d.idVentaDetalle,
            d.idInventario,
            p.nombre AS producto,
            i.codigoLote,
            d.cantidad,
            d.precioUnitarioDevuelto,
            d.subtotalDevuelto,
            d.regresaAInventario,
            d.motivoDetalle,
            d.observaciones
        FROM devolucion_cliente_detalle d
        INNER JOIN inventario_producto i ON i.idInventario = d.idInventario
        INNER JOIN producto p ON p.idProducto = i.idProducto
        WHERE d.idDevolucionCliente = %s
        ORDER BY d.idDevolucionClienteDetalle
        """,
        [id_devolucion_cliente],
    )
    return devolucion


@router.post("/clientes", status_code=201)
def registrar_devolucion_cliente(request: RegistrarDevolucionClienteRequest):
    detalles_json = json.dumps(
        [
            {
                "idVentaDetalle": detalle.idVentaDetalle,
                "cantidad": detalle.cantidad,
                "regresaAInventario": 1 if detalle.regresaAInventario else 0,
                "motivoDetalle": detalle.motivoDetalle,
                "observaciones": detalle.observaciones,
            }
            for detalle in request.detalles
        ]
    )

    result = call_procedure(
        "sp_registrar_devolucion_cliente",
        [
            request.idUsuario,
            request.idVenta,
            request.metodoDevolucion,
            request.motivo,
            request.observaciones,
            detalles_json,
        ],
        out_count=2,
    )
    return obtener_devolucion_cliente(result.get("out_0"))


@router.post("/clientes/{id_devolucion_cliente}/cancelar")
def cancelar_devolucion_cliente(
    id_devolucion_cliente: int,
    request: CancelarDevolucionRequest,
):
    if not _obtener_devolucion_cliente(id_devolucion_cliente):
        raise HTTPException(status_code=404, detail="Devolucion de cliente no encontrada")

    call_procedure(
        "sp_cancelar_devolucion_cliente",
        [
            request.idUsuario,
            id_devolucion_cliente,
            request.observaciones,
        ],
    )
    return obtener_devolucion_cliente(id_devolucion_cliente)


@router.get("/proveedores")
def listar_devoluciones_proveedor(
    estatus: EstatusDevolucion | None = None,
    id_compra: int | None = Query(default=None, alias="idCompra"),
    id_proveedor: int | None = Query(default=None, alias="idProveedor"),
    id_corte: int | None = Query(default=None, alias="idCorte"),
    limite: int = Query(default=100, ge=1, le=500),
):
    sql = _select_devoluciones_proveedor_sql()
    filtros: list[str] = []
    params: list[object] = []

    if estatus:
        filtros.append("d.estatus = %s")
        params.append(estatus)

    if id_compra is not None:
        filtros.append("d.idCompra = %s")
        params.append(id_compra)

    if id_proveedor is not None:
        filtros.append("d.idProveedor = %s")
        params.append(id_proveedor)

    if id_corte is not None:
        filtros.append("d.idCorte = %s")
        params.append(id_corte)

    if filtros:
        sql += " WHERE " + " AND ".join(filtros)

    sql += " ORDER BY d.fecha DESC, d.idDevolucionProveedor DESC LIMIT %s"
    params.append(limite)
    return fetch_all(sql, params)


@router.get("/proveedores/{id_devolucion_proveedor}")
def obtener_devolucion_proveedor(id_devolucion_proveedor: int):
    devolucion = _obtener_devolucion_proveedor(id_devolucion_proveedor)

    if not devolucion:
        raise HTTPException(status_code=404, detail="Devolucion a proveedor no encontrada")

    devolucion["detalles"] = fetch_all(
        """
        SELECT
            d.idDevolucionProveedorDetalle,
            d.idDevolucionProveedor,
            d.idCompraDetalle,
            d.idInventario,
            p.nombre AS producto,
            i.codigoLote,
            d.cantidad,
            d.costoUnitario,
            d.subtotal,
            d.motivoDetalle,
            d.observaciones
        FROM devolucion_proveedor_detalle d
        INNER JOIN inventario_producto i ON i.idInventario = d.idInventario
        INNER JOIN producto p ON p.idProducto = i.idProducto
        WHERE d.idDevolucionProveedor = %s
        ORDER BY d.idDevolucionProveedorDetalle
        """,
        [id_devolucion_proveedor],
    )
    return devolucion


@router.post("/proveedores", status_code=201)
def registrar_devolucion_proveedor(request: RegistrarDevolucionProveedorRequest):
    if request.tipoCompensacion == "REPOSICION_PRODUCTO" and not request.reposicionDetalles:
        raise HTTPException(
            status_code=422,
            detail="La reposicion de producto debe incluir los datos del inventario repuesto.",
        )
    if request.tipoCompensacion == "REPOSICION_PRODUCTO":
        _validar_reposicion_proveedor(request.reposicionDetalles or [])

    detalles_json = json.dumps(
        [
            {
                "idCompraDetalle": detalle.idCompraDetalle,
                "idInventario": detalle.idInventario,
                "cantidad": detalle.cantidad,
                "motivoDetalle": detalle.motivoDetalle,
                "observaciones": detalle.observaciones,
            }
            for detalle in request.detalles
        ]
    )

    result = call_procedure(
        "sp_registrar_devolucion_proveedor",
        [
            request.idUsuario,
            request.idCompra,
            request.idProveedor,
            request.tipoCompensacion,
            request.motivo,
            request.observaciones,
            detalles_json,
        ],
        out_count=2,
    )
    id_devolucion = result.get("out_0")
    folio_devolucion = result.get("out_1")

    if request.tipoCompensacion == "REPOSICION_PRODUCTO":
        reposicion_json = json.dumps(
            [
                {
                    "idProducto": detalle.idProducto,
                    "cantidad": detalle.cantidad,
                    "costoUnitario": str(detalle.costoUnitario),
                    "precioVenta": str(detalle.precioVenta),
                    "codigoLote": detalle.codigoLote or "REPOSICION",
                    "fechaCaducidad": detalle.fechaCaducidad,
                }
                for detalle in request.reposicionDetalles or []
            ]
        )

        call_procedure(
            "sp_registrar_compra",
            [
                request.idUsuario,
                request.idProveedor,
                f"REPOSICION-{folio_devolucion}",
                Decimal("0.00"),
                f"Reposicion por devolucion a proveedor {folio_devolucion}",
                reposicion_json,
                None,
                Decimal("0.00"),
            ],
            out_count=1,
        )

    return obtener_devolucion_proveedor(id_devolucion)


def _validar_reposicion_proveedor(detalles: list[ReposicionProveedorDetalleRequest]):
    today = date.today()

    for detalle in detalles:
        producto = fetch_one(
            """
            SELECT idProducto, nombre, manejaCaducidad, activo
            FROM producto
            WHERE idProducto = %s
            """,
            [detalle.idProducto],
        )

        if not producto:
            raise HTTPException(
                status_code=422,
                detail=f"El producto repuesto {detalle.idProducto} no existe.",
            )

        if not producto["activo"]:
            raise HTTPException(
                status_code=422,
                detail=f"El producto repuesto {producto['nombre']} esta inactivo.",
            )

        if producto["manejaCaducidad"] and not detalle.fechaCaducidad:
            raise HTTPException(
                status_code=422,
                detail=f"El producto repuesto {producto['nombre']} requiere fecha de caducidad.",
            )

        if detalle.fechaCaducidad:
            try:
                fecha_caducidad = date.fromisoformat(detalle.fechaCaducidad)
            except ValueError as exc:
                raise HTTPException(
                    status_code=422,
                    detail="La fecha de caducidad debe usar el formato YYYY-MM-DD.",
                ) from exc

            if fecha_caducidad < today:
                raise HTTPException(
                    status_code=422,
                    detail=f"La caducidad de {producto['nombre']} no puede estar vencida.",
                )


@router.post("/proveedores/{id_devolucion_proveedor}/cancelar")
def cancelar_devolucion_proveedor(
    id_devolucion_proveedor: int,
    request: CancelarDevolucionRequest,
):
    if not _obtener_devolucion_proveedor(id_devolucion_proveedor):
        raise HTTPException(status_code=404, detail="Devolucion a proveedor no encontrada")

    call_procedure(
        "sp_cancelar_devolucion_proveedor",
        [
            request.idUsuario,
            id_devolucion_proveedor,
            request.observaciones,
        ],
    )
    return obtener_devolucion_proveedor(id_devolucion_proveedor)


def _obtener_devolucion_cliente(id_devolucion_cliente: int):
    return fetch_one(
        _select_devoluciones_cliente_sql() + " WHERE d.idDevolucionCliente = %s",
        [id_devolucion_cliente],
    )


def _obtener_devolucion_proveedor(id_devolucion_proveedor: int):
    return fetch_one(
        _select_devoluciones_proveedor_sql() + " WHERE d.idDevolucionProveedor = %s",
        [id_devolucion_proveedor],
    )


def _select_devoluciones_cliente_sql() -> str:
    return """
        SELECT
            d.idDevolucionCliente,
            d.folio,
            d.idVenta,
            v.folio AS folioVenta,
            d.idCorte,
            d.idUsuario,
            u.nombre AS usuario,
            d.fecha,
            d.motivo,
            d.totalDevuelto,
            d.metodoDevolucion,
            d.estatus,
            d.observaciones,
            d.created_at
        FROM devolucion_cliente d
        INNER JOIN venta v ON v.idVenta = d.idVenta
        INNER JOIN usuario u ON u.idUsuario = d.idUsuario
    """


def _select_devoluciones_proveedor_sql() -> str:
    return """
        SELECT
            d.idDevolucionProveedor,
            d.folio,
            d.idCompra,
            d.idProveedor,
            p.nombre AS proveedor,
            d.idCorte,
            d.idUsuario,
            u.nombre AS usuario,
            d.fecha,
            d.motivo,
            d.totalDevolucion,
            d.tipoCompensacion,
            d.estatus,
            d.observaciones,
            d.created_at
        FROM devolucion_proveedor d
        LEFT JOIN proveedor p ON p.idProveedor = d.idProveedor
        INNER JOIN usuario u ON u.idUsuario = d.idUsuario
    """
