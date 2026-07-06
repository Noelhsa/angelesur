from decimal import Decimal
from typing import Literal

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field

from app.database import call_procedure, db_connection, fetch_all, fetch_one

router = APIRouter(prefix="/servicios-yastas", tags=["servicios-yastas"])

TipoServicioYastas = Literal[
    "RECARGA",
    "DEPOSITO",
    "RETIRO",
    "PAGO_SERVICIO",
    "CFE",
    "TELMEX",
    "IZZI",
    "INTERNET",
    "OTRO",
]
EstatusServicioYastas = Literal["REALIZADA", "CANCELADA", "FALLIDA"]


class TarifaServicioBase(BaseModel):
    tipoServicio: TipoServicioYastas
    nombreServicio: str = Field(min_length=1, max_length=120)
    montoBase: Decimal = Field(default=Decimal("0.00"), ge=0)
    comisionCliente: Decimal = Field(default=Decimal("0.00"), ge=0)
    comisionYastas: Decimal = Field(default=Decimal("0.00"), ge=0)
    regaliaYastas: Decimal = Field(default=Decimal("0.00"), ge=0)
    gananciaFarmacia: Decimal = Field(default=Decimal("0.00"), ge=0)


class CrearTarifaServicioRequest(TarifaServicioBase):
    pass


class ActualizarTarifaServicioRequest(BaseModel):
    tipoServicio: TipoServicioYastas | None = None
    nombreServicio: str | None = Field(default=None, min_length=1, max_length=120)
    montoBase: Decimal | None = Field(default=None, ge=0)
    comisionCliente: Decimal | None = Field(default=None, ge=0)
    comisionYastas: Decimal | None = Field(default=None, ge=0)
    regaliaYastas: Decimal | None = Field(default=None, ge=0)
    gananciaFarmacia: Decimal | None = Field(default=None, ge=0)


class CambiarEstadoTarifaRequest(BaseModel):
    activo: bool


class RegistrarServicioYastasRequest(BaseModel):
    idUsuario: int
    idTarifa: int
    montoServicio: Decimal = Field(ge=0)
    referenciaOperacion: str | None = Field(default=None, max_length=120)
    observaciones: str | None = Field(default=None, max_length=255)


class CancelarServicioYastasRequest(BaseModel):
    idUsuario: int
    observaciones: str | None = Field(default=None, max_length=255)


@router.get("/tarifas")
def listar_tarifas_servicio(
    tipo_servicio: TipoServicioYastas | None = Query(default=None, alias="tipoServicio"),
    incluir_inactivas: bool = Query(default=False, alias="incluirInactivas"),
    limite: int = Query(default=200, ge=1, le=1000),
):
    sql = """
        SELECT
            idTarifa,
            tipoServicio,
            nombreServicio,
            montoBase,
            comisionCliente,
            comisionYastas,
            regaliaYastas,
            gananciaFarmacia,
            activo,
            created_at,
            updated_at
        FROM tarifa_servicio
    """
    filtros: list[str] = []
    params: list[object] = []

    if not incluir_inactivas:
        filtros.append("activo = %s")
        params.append(1)

    if tipo_servicio:
        filtros.append("tipoServicio = %s")
        params.append(tipo_servicio)

    if filtros:
        sql += " WHERE " + " AND ".join(filtros)

    sql += " ORDER BY tipoServicio, nombreServicio, montoBase LIMIT %s"
    params.append(limite)
    return fetch_all(sql, params)


@router.get("/tarifas/{id_tarifa}")
def obtener_tarifa_servicio(id_tarifa: int):
    tarifa = _obtener_tarifa(id_tarifa)

    if not tarifa:
        raise HTTPException(status_code=404, detail="Tarifa de servicio no encontrada")

    return tarifa


@router.post("/tarifas", status_code=201)
def crear_tarifa_servicio(request: CrearTarifaServicioRequest):
    with db_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                INSERT INTO tarifa_servicio (
                    tipoServicio,
                    nombreServicio,
                    montoBase,
                    comisionCliente,
                    comisionYastas,
                    regaliaYastas,
                    gananciaFarmacia
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                """,
                [
                    request.tipoServicio,
                    request.nombreServicio.strip(),
                    request.montoBase,
                    request.comisionCliente,
                    request.comisionYastas,
                    request.regaliaYastas,
                    request.gananciaFarmacia,
                ],
            )
            id_tarifa = cursor.lastrowid

    return obtener_tarifa_servicio(id_tarifa)


@router.patch("/tarifas/{id_tarifa}")
def actualizar_tarifa_servicio(id_tarifa: int, request: ActualizarTarifaServicioRequest):
    obtener_tarifa_servicio(id_tarifa)

    campos = [
        "tipoServicio",
        "nombreServicio",
        "montoBase",
        "comisionCliente",
        "comisionYastas",
        "regaliaYastas",
        "gananciaFarmacia",
    ]
    updates: list[str] = []
    params: list[object] = []

    for campo in campos:
        if campo not in request.model_fields_set:
            continue

        value = getattr(request, campo)
        if isinstance(value, str):
            value = value.strip()
        updates.append(f"{campo} = %s")
        params.append(value)

    if updates:
        params.append(id_tarifa)
        with db_connection() as connection:
            with connection.cursor() as cursor:
                cursor.execute(
                    f"UPDATE tarifa_servicio SET {', '.join(updates)} WHERE idTarifa = %s",
                    params,
                )

    return obtener_tarifa_servicio(id_tarifa)


@router.patch("/tarifas/{id_tarifa}/estado")
def cambiar_estado_tarifa_servicio(id_tarifa: int, request: CambiarEstadoTarifaRequest):
    obtener_tarifa_servicio(id_tarifa)

    with db_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                "UPDATE tarifa_servicio SET activo = %s WHERE idTarifa = %s",
                [1 if request.activo else 0, id_tarifa],
            )

    return obtener_tarifa_servicio(id_tarifa)


@router.get("")
def listar_servicios_yastas(
    estatus: EstatusServicioYastas | None = None,
    tipo_servicio: TipoServicioYastas | None = Query(default=None, alias="tipoServicio"),
    id_corte: int | None = Query(default=None, alias="idCorte"),
    id_usuario: int | None = Query(default=None, alias="idUsuario"),
    limite: int = Query(default=100, ge=1, le=500),
):
    sql = _select_servicios_sql()
    filtros: list[str] = []
    params: list[object] = []

    if estatus:
        filtros.append("s.estatus = %s")
        params.append(estatus)

    if tipo_servicio:
        filtros.append("s.tipoServicio = %s")
        params.append(tipo_servicio)

    if id_corte is not None:
        filtros.append("s.idCorte = %s")
        params.append(id_corte)

    if id_usuario is not None:
        filtros.append("s.idUsuario = %s")
        params.append(id_usuario)

    if filtros:
        sql += " WHERE " + " AND ".join(filtros)

    sql += " ORDER BY s.fecha DESC, s.idServicioOperacion DESC LIMIT %s"
    params.append(limite)
    return fetch_all(sql, params)


@router.get("/{id_servicio_operacion}")
def obtener_servicio_yastas(id_servicio_operacion: int):
    servicio = _obtener_servicio(id_servicio_operacion)

    if not servicio:
        raise HTTPException(status_code=404, detail="Servicio Yastas no encontrado")

    return servicio


@router.post("", status_code=201)
def registrar_servicio_yastas(request: RegistrarServicioYastasRequest):
    if not _obtener_tarifa(request.idTarifa):
        raise HTTPException(status_code=404, detail="Tarifa de servicio no encontrada")

    result = call_procedure(
        "sp_registrar_servicio_yastas",
        [
            request.idUsuario,
            request.idTarifa,
            request.montoServicio,
            request.referenciaOperacion,
            request.observaciones,
        ],
        out_count=1,
    )
    return obtener_servicio_yastas(result.get("out_0"))


@router.post("/{id_servicio_operacion}/cancelar")
def cancelar_servicio_yastas(
    id_servicio_operacion: int,
    request: CancelarServicioYastasRequest,
):
    if not _obtener_servicio(id_servicio_operacion):
        raise HTTPException(status_code=404, detail="Servicio Yastas no encontrado")

    call_procedure(
        "sp_cancelar_servicio_yastas",
        [
            request.idUsuario,
            id_servicio_operacion,
            request.observaciones,
        ],
    )
    return obtener_servicio_yastas(id_servicio_operacion)


def _obtener_tarifa(id_tarifa: int):
    return fetch_one(
        """
        SELECT
            idTarifa,
            tipoServicio,
            nombreServicio,
            montoBase,
            comisionCliente,
            comisionYastas,
            regaliaYastas,
            gananciaFarmacia,
            activo,
            created_at,
            updated_at
        FROM tarifa_servicio
        WHERE idTarifa = %s
        """,
        [id_tarifa],
    )


def _obtener_servicio(id_servicio_operacion: int):
    return fetch_one(
        _select_servicios_sql() + " WHERE s.idServicioOperacion = %s",
        [id_servicio_operacion],
    )


def _select_servicios_sql() -> str:
    return """
        SELECT
            s.idServicioOperacion,
            s.idUsuario,
            u.nombre AS usuario,
            s.idCorte,
            s.idTarifa,
            s.tipoServicio,
            s.nombreServicio,
            s.referenciaOperacion,
            s.montoServicio,
            s.comisionCliente,
            s.comisionYastas,
            s.regaliaYastas,
            s.gananciaFarmacia,
            s.totalCobradoCliente,
            s.estatus,
            s.fecha,
            s.observaciones
        FROM servicio_operacion s
        INNER JOIN usuario u ON u.idUsuario = s.idUsuario
    """
