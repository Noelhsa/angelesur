import json
from decimal import Decimal
from typing import Literal

from fastapi import APIRouter
from pydantic import BaseModel, Field

from app.database import call_procedure

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

    return {
        "idVenta": result.get("out_0"),
        "folio": result.get("out_1"),
    }
