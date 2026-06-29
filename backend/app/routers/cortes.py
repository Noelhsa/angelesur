from decimal import Decimal

from fastapi import APIRouter
from pydantic import BaseModel, Field

from app.database import call_procedure, fetch_all, fetch_one

router = APIRouter(prefix="/cortes", tags=["cortes"])


class AbrirCorteRequest(BaseModel):
    id_usuario: int = Field(alias="idUsuario")
    efectivo_inicial: Decimal = Field(default=Decimal("0.00"), alias="efectivoInicial")
    electronico_inicial: Decimal = Field(default=Decimal("0.00"), alias="electronicoInicial")
    observaciones: str | None = None


class CerrarCorteRequest(BaseModel):
    id_usuario: int = Field(alias="idUsuario")
    efectivo_contado: Decimal = Field(alias="efectivoContado")
    electronico_contado: Decimal = Field(alias="electronicoContado")
    observaciones: str | None = None


@router.get("/resumen")
def listar_cortes():
    return fetch_all("SELECT * FROM vw_corte_resumen ORDER BY fechaApertura DESC LIMIT 100")


@router.get("/actual")
def obtener_corte_actual():
    return fetch_one("SELECT * FROM vw_corte_resumen WHERE estado = 'ABIERTO' LIMIT 1")


@router.post("/abrir")
def abrir_corte(request: AbrirCorteRequest):
    result = call_procedure(
        "sp_abrir_corte",
        [
            request.id_usuario,
            request.efectivo_inicial,
            request.electronico_inicial,
            request.observaciones,
        ],
        out_count=1,
    )
    return {"idCorte": result.get("out_0")}


@router.post("/cerrar")
def cerrar_corte(request: CerrarCorteRequest):
    call_procedure(
        "sp_cerrar_corte",
        [
            request.id_usuario,
            request.efectivo_contado,
            request.electronico_contado,
            request.observaciones,
        ],
    )
    return {"status": "cerrado"}
