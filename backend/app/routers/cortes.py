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
    return fetch_all(
        _select_cortes_resumen_sql()
        + " ORDER BY r.fechaApertura DESC LIMIT 100"
    )


@router.get("/actual")
def obtener_corte_actual():
    return fetch_one(
        _select_cortes_resumen_sql()
        + " WHERE r.estado = 'ABIERTO' LIMIT 1"
    )


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


def _select_cortes_resumen_sql() -> str:
    return """
        SELECT
            r.*,
            COALESCE(m.ventasEfectivo, 0) AS ventasEfectivo,
            COALESCE(m.ventasElectronico, 0) AS ventasElectronico,
            COALESCE(m.otrosIngresos, 0) AS otrosIngresos,
            COALESCE(m.salidas, 0) AS salidas,
            r.efectivoSistema AS efectivoEsperado,
            r.electronicoSistema AS electronicoEsperado,
            r.efectivoSistema + r.electronicoSistema AS totalEsperado
        FROM vw_corte_resumen r
        LEFT JOIN (
            SELECT
                idCorte,
                SUM(
                    CASE
                        WHEN medio = 'EFECTIVO'
                            AND tipo = 'ENTRADA'
                            AND concepto = 'VENTA_PRODUCTO'
                        THEN monto
                        ELSE 0
                    END
                ) AS ventasEfectivo,
                SUM(
                    CASE
                        WHEN medio = 'ELECTRONICO'
                            AND tipo = 'ENTRADA'
                            AND concepto = 'VENTA_PRODUCTO'
                        THEN monto
                        ELSE 0
                    END
                ) AS ventasElectronico,
                SUM(
                    CASE
                        WHEN tipo = 'ENTRADA'
                            AND concepto <> 'VENTA_PRODUCTO'
                        THEN monto
                        ELSE 0
                    END
                ) AS otrosIngresos,
                SUM(
                    CASE
                        WHEN tipo = 'SALIDA'
                        THEN monto
                        ELSE 0
                    END
                ) AS salidas
            FROM movimiento_dinero
            GROUP BY idCorte
        ) m ON m.idCorte = r.idCorte
    """
