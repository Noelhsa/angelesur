from decimal import Decimal
from typing import Literal

from fastapi import APIRouter, HTTPException, Query
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
def listar_cortes(
    busqueda: str | None = Query(default=None, min_length=1),
    estado: Literal["ABIERTO", "CERRADO"] | None = None,
    fecha_apertura_desde: str | None = Query(default=None, alias="fechaAperturaDesde"),
    fecha_apertura_hasta: str | None = Query(default=None, alias="fechaAperturaHasta"),
    fecha_cierre_desde: str | None = Query(default=None, alias="fechaCierreDesde"),
    fecha_cierre_hasta: str | None = Query(default=None, alias="fechaCierreHasta"),
    limite: int = Query(default=100, ge=1, le=500),
):
    sql = _select_cortes_resumen_sql()
    filtros: list[str] = []
    params: list[object] = []

    if busqueda:
        filtros.append(
            """
            (
                CAST(r.idCorte AS CHAR) LIKE %s
                OR ua.nombre LIKE %s
                OR uc.nombre LIKE %s
                OR c.observaciones LIKE %s
                OR CAST(r.efectivoInicial AS CHAR) LIKE %s
                OR CAST(r.electronicoInicial AS CHAR) LIKE %s
                OR CAST(r.efectivoContado AS CHAR) LIKE %s
                OR CAST(r.electronicoContado AS CHAR) LIKE %s
                OR CAST(r.efectivoSistema AS CHAR) LIKE %s
                OR CAST(r.electronicoSistema AS CHAR) LIKE %s
                OR CAST(r.efectivoSistema + r.electronicoSistema AS CHAR) LIKE %s
            )
            """
        )
        like = f"%{busqueda.strip()}%"
        params.extend([like] * 11)

    if estado:
        filtros.append("r.estado = %s")
        params.append(estado)

    if fecha_apertura_desde:
        filtros.append("DATE(r.fechaApertura) >= %s")
        params.append(fecha_apertura_desde)

    if fecha_apertura_hasta:
        filtros.append("DATE(r.fechaApertura) <= %s")
        params.append(fecha_apertura_hasta)

    if fecha_cierre_desde:
        filtros.append("DATE(r.fechaCierre) >= %s")
        params.append(fecha_cierre_desde)

    if fecha_cierre_hasta:
        filtros.append("DATE(r.fechaCierre) <= %s")
        params.append(fecha_cierre_hasta)

    if filtros:
        sql += " WHERE " + " AND ".join(filtros)

    sql += " ORDER BY r.fechaApertura DESC LIMIT %s"
    params.append(limite)
    return fetch_all(sql, params)


@router.get("/actual")
def obtener_corte_actual():
    return fetch_one(
        _select_cortes_resumen_sql()
        + " WHERE r.estado = 'ABIERTO' LIMIT 1"
    )


@router.get("/{id_corte}/movimientos")
def listar_movimientos_corte(
    id_corte: int,
    limite: int = Query(default=1000, ge=1, le=2000),
):
    if not _obtener_corte_resumen(id_corte):
        raise HTTPException(status_code=404, detail="Corte no encontrado")

    return fetch_all(
        _select_movimientos_corte_sql()
        + " WHERE m.idCorte = %s"
        + " ORDER BY m.fecha DESC, m.idMovDin DESC LIMIT %s",
        [id_corte, limite],
    )


@router.get("/{id_corte}")
def obtener_detalle_corte(
    id_corte: int,
    limite_movimientos: int = Query(default=1000, ge=1, le=2000, alias="limiteMovimientos"),
):
    corte = _obtener_corte_resumen(id_corte)

    if not corte:
        raise HTTPException(status_code=404, detail="Corte no encontrado")

    corte["totalesMovimientos"] = fetch_one(
        _select_totales_movimientos_corte_sql(),
        [id_corte],
    )
    corte["movimientos"] = fetch_all(
        _select_movimientos_corte_sql()
        + " WHERE m.idCorte = %s"
        + " ORDER BY m.fecha DESC, m.idMovDin DESC LIMIT %s",
        [id_corte, limite_movimientos],
    )
    return corte


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


def _obtener_corte_resumen(id_corte: int):
    return fetch_one(
        _select_cortes_resumen_sql() + " WHERE r.idCorte = %s",
        [id_corte],
    )


def _select_cortes_resumen_sql() -> str:
    return """
        SELECT
            r.*,
            c.observaciones AS observacionesCorte,
            ua.nombre AS usuarioAbreNombre,
            uc.nombre AS usuarioCierraNombre,
            COALESCE(m.ventasEfectivo, 0) AS ventasEfectivo,
            COALESCE(m.ventasElectronico, 0) AS ventasElectronico,
            COALESCE(m.entradasEfectivo, 0) AS entradasEfectivo,
            COALESCE(m.entradasElectronico, 0) AS entradasElectronico,
            COALESCE(m.otrosIngresos, 0) AS otrosIngresos,
            COALESCE(m.salidasEfectivo, 0) AS salidasEfectivo,
            COALESCE(m.salidasElectronico, 0) AS salidasElectronico,
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
                        WHEN medio = 'EFECTIVO'
                            AND tipo = 'ENTRADA'
                        THEN monto
                        ELSE 0
                    END
                ) AS entradasEfectivo,
                SUM(
                    CASE
                        WHEN medio = 'ELECTRONICO'
                            AND tipo = 'ENTRADA'
                        THEN monto
                        ELSE 0
                    END
                ) AS entradasElectronico,
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
                        WHEN medio = 'EFECTIVO'
                            AND tipo = 'SALIDA'
                        THEN monto
                        ELSE 0
                    END
                ) AS salidasEfectivo,
                SUM(
                    CASE
                        WHEN medio = 'ELECTRONICO'
                            AND tipo = 'SALIDA'
                        THEN monto
                        ELSE 0
                    END
                ) AS salidasElectronico,
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
        LEFT JOIN corte_caja c ON c.idCorte = r.idCorte
        INNER JOIN usuario ua ON ua.idUsuario = r.usuarioAbre
        LEFT JOIN usuario uc ON uc.idUsuario = r.usuarioCierra
    """


def _select_movimientos_corte_sql() -> str:
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
            NULLIF(
                TRIM(
                    CONCAT_WS(
                        ' | ',
                        NULLIF(m.observaciones, ''),
                        NULLIF(v.observaciones, '')
                    )
                ),
                ''
            ) AS observaciones
        FROM movimiento_dinero m
        INNER JOIN usuario u ON u.idUsuario = m.idUsuario
        LEFT JOIN venta v ON v.idVenta = m.idVenta
    """


def _select_totales_movimientos_corte_sql() -> str:
    return """
        SELECT
            COALESCE(SUM(CASE WHEN medio = 'EFECTIVO' AND tipo = 'ENTRADA' THEN monto ELSE 0 END), 0) AS entradasEfectivo,
            COALESCE(SUM(CASE WHEN medio = 'EFECTIVO' AND tipo = 'SALIDA' THEN monto ELSE 0 END), 0) AS salidasEfectivo,
            COALESCE(SUM(CASE WHEN medio = 'ELECTRONICO' AND tipo = 'ENTRADA' THEN monto ELSE 0 END), 0) AS entradasElectronico,
            COALESCE(SUM(CASE WHEN medio = 'ELECTRONICO' AND tipo = 'SALIDA' THEN monto ELSE 0 END), 0) AS salidasElectronico,
            COALESCE(SUM(CASE WHEN tipo = 'ENTRADA' THEN monto ELSE 0 END), 0) AS entradas,
            COALESCE(SUM(CASE WHEN tipo = 'SALIDA' THEN monto ELSE 0 END), 0) AS salidas,
            COUNT(*) AS totalMovimientos
        FROM movimiento_dinero
        WHERE idCorte = %s
    """
