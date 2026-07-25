from typing import Literal

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field

from app.database import db_connection, fetch_all, fetch_one

router = APIRouter(prefix="/productos", tags=["productos"])

TipoProducto = Literal["MEDICAMENTO", "PRODUCTO"]
ViaAdministracion = Literal[
    "CAPSULA",
    "TABLETA",
    "PASTILLA",
    "SUSPENSION",
    "GOTAS",
    "INYECCION",
    "JARABE",
    "CREMA",
    "POMADA",
    "AEROSOL",
    "SOLUCION",
    "OTRO",
]
EdadMedicamento = Literal["PEDIATRICO", "INFANTIL", "ADULTO", "GENERAL"]


class InfoMedicamentoRequest(BaseModel):
    presentacion: str | None = Field(default=None, max_length=80)
    viaAdministracion: ViaAdministracion | None = None
    edad: EdadMedicamento | None = "GENERAL"
    requiereReceta: bool = False
    sustanciaActiva: str | None = Field(default=None, max_length=150)
    dosis: str | None = Field(default=None, max_length=100)


class ProductoBase(BaseModel):
    codigoBarras: str | None = Field(default=None, max_length=64)
    nombre: str = Field(min_length=1, max_length=200)
    descripcion: str | None = Field(default=None, max_length=255)
    tipo: TipoProducto
    categoria: str | None = Field(default=None, max_length=80)
    manejaCaducidad: bool = False


class CrearProductoRequest(ProductoBase):
    infoMedicamento: InfoMedicamentoRequest | None = None


class ActualizarProductoRequest(BaseModel):
    codigoBarras: str | None = Field(default=None, max_length=64)
    nombre: str | None = Field(default=None, min_length=1, max_length=200)
    descripcion: str | None = Field(default=None, max_length=255)
    tipo: TipoProducto | None = None
    categoria: str | None = Field(default=None, max_length=80)
    manejaCaducidad: bool | None = None
    infoMedicamento: InfoMedicamentoRequest | None = None


class CambiarEstadoProductoRequest(BaseModel):
    activo: bool


class ProductoResponse(BaseModel):
    idProducto: int
    codigoBarras: str | None
    nombre: str
    descripcion: str | None
    tipo: TipoProducto
    categoria: str | None
    manejaCaducidad: bool
    activo: bool
    presentacion: str | None = None
    viaAdministracion: str | None = None
    edad: str | None = None
    requiereReceta: bool | None = None
    sustanciaActiva: str | None = None
    dosis: str | None = None


@router.get("")
def listar_productos(
    busqueda: str | None = Query(default=None, min_length=1),
    tipo: TipoProducto | None = None,
    categoria: str | None = Query(default=None, min_length=1),
    activo: bool | None = None,
    incluir_inactivos: bool = Query(default=False, alias="incluirInactivos"),
    pagina: int = Query(default=1, ge=1),
    limite: int = Query(default=25, ge=5, le=100),
):
    filtros: list[str] = []
    params: list[object] = []

    if not incluir_inactivos:
        filtros.append("p.activo = %s")
        params.append(1)

    if activo is not None:
        filtros.append("p.activo = %s")
        params.append(1 if activo else 0)

    if tipo:
        filtros.append("p.tipo = %s")
        params.append(tipo)

    if categoria:
        filtros.append("p.categoria = %s")
        params.append(categoria)

    if busqueda:
        filtros.append(
            "(p.nombre LIKE %s OR p.codigoBarras LIKE %s OR p.categoria LIKE %s)"
        )
        like = f"%{busqueda.strip()}%"
        params.extend([like, like, like])

    where_sql = f" WHERE {' AND '.join(filtros)}" if filtros else ""
    total_row = fetch_one(
        f"SELECT COUNT(*) AS total FROM ({_select_productos_sql()}{where_sql}) productos",
        params,
    )
    total = int(total_row["total"] if total_row else 0)
    total_paginas = max((total + limite - 1) // limite, 1)
    pagina_actual = min(pagina, total_paginas)
    offset = (pagina_actual - 1) * limite

    items = fetch_all(
        _select_productos_sql() + where_sql + " ORDER BY p.nombre LIMIT %s OFFSET %s",
        [*params, limite, offset],
    )
    return {
        "items": items,
        "pagina": pagina_actual,
        "limite": limite,
        "total": total,
        "totalPaginas": total_paginas,
        "hayAnterior": pagina_actual > 1,
        "haySiguiente": pagina_actual < total_paginas,
    }


@router.get("/{id_producto}", response_model=ProductoResponse)
def obtener_producto(id_producto: int):
    producto = fetch_one(
        _select_productos_sql() + " WHERE p.idProducto = %s",
        [id_producto],
    )

    if not producto:
        raise HTTPException(status_code=404, detail="Producto no encontrado")

    return producto


@router.post("", response_model=ProductoResponse, status_code=201)
def crear_producto(request: CrearProductoRequest):
    with db_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                INSERT INTO producto (
                    codigoBarras,
                    nombre,
                    descripcion,
                    tipo,
                    categoria,
                    manejaCaducidad
                )
                VALUES (%s, %s, %s, %s, %s, %s)
                """,
                [
                    _clean_optional(request.codigoBarras),
                    request.nombre.strip(),
                    _clean_optional(request.descripcion),
                    request.tipo,
                    _clean_optional(request.categoria),
                    1 if request.manejaCaducidad else 0,
                ],
            )
            id_producto = cursor.lastrowid

            if request.tipo == "MEDICAMENTO" and request.infoMedicamento:
                _upsert_info_medicamento(cursor, id_producto, request.infoMedicamento)

    return obtener_producto(id_producto)


@router.patch("/{id_producto}", response_model=ProductoResponse)
def actualizar_producto(id_producto: int, request: ActualizarProductoRequest):
    obtener_producto(id_producto)

    campos = {
        "codigoBarras": "codigoBarras",
        "nombre": "nombre",
        "descripcion": "descripcion",
        "tipo": "tipo",
        "categoria": "categoria",
        "manejaCaducidad": "manejaCaducidad",
    }
    updates: list[str] = []
    params: list[object] = []

    for field_name, column_name in campos.items():
        if field_name not in request.model_fields_set:
            continue

        value = getattr(request, field_name)
        if isinstance(value, str):
            value = _clean_optional(value)
        if field_name == "manejaCaducidad" and value is not None:
            value = 1 if value else 0

        updates.append(f"{column_name} = %s")
        params.append(value)

    with db_connection() as connection:
        with connection.cursor() as cursor:
            if updates:
                params.append(id_producto)
                cursor.execute(
                    f"UPDATE producto SET {', '.join(updates)} WHERE idProducto = %s",
                    params,
                )

            if request.infoMedicamento is not None:
                _upsert_info_medicamento(cursor, id_producto, request.infoMedicamento)

            if request.tipo == "PRODUCTO":
                cursor.execute(
                    "DELETE FROM info_medicamento WHERE idProducto = %s",
                    [id_producto],
                )

    return obtener_producto(id_producto)


@router.patch("/{id_producto}/estado", response_model=ProductoResponse)
def cambiar_estado_producto(id_producto: int, request: CambiarEstadoProductoRequest):
    obtener_producto(id_producto)

    with db_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                "UPDATE producto SET activo = %s WHERE idProducto = %s",
                [1 if request.activo else 0, id_producto],
            )

    return obtener_producto(id_producto)


def _select_productos_sql() -> str:
    return """
        SELECT
            p.idProducto,
            p.codigoBarras,
            p.nombre,
            p.descripcion,
            p.tipo,
            p.categoria,
            p.manejaCaducidad,
            p.activo,
            i.presentacion,
            i.viaAdministracion,
            i.edad,
            i.requiereReceta,
            i.sustanciaActiva,
            i.dosis
        FROM producto p
        LEFT JOIN info_medicamento i ON i.idProducto = p.idProducto
    """


def _upsert_info_medicamento(cursor, id_producto: int, info: InfoMedicamentoRequest):
    cursor.execute(
        """
        INSERT INTO info_medicamento (
            idProducto,
            presentacion,
            viaAdministracion,
            edad,
            requiereReceta,
            sustanciaActiva,
            dosis
        )
        VALUES (%s, %s, %s, %s, %s, %s, %s)
        ON DUPLICATE KEY UPDATE
            presentacion = VALUES(presentacion),
            viaAdministracion = VALUES(viaAdministracion),
            edad = VALUES(edad),
            requiereReceta = VALUES(requiereReceta),
            sustanciaActiva = VALUES(sustanciaActiva),
            dosis = VALUES(dosis)
        """,
        [
            id_producto,
            _clean_optional(info.presentacion),
            info.viaAdministracion,
            info.edad,
            1 if info.requiereReceta else 0,
            _clean_optional(info.sustanciaActiva),
            _clean_optional(info.dosis),
        ],
    )


def _clean_optional(value: str | None) -> str | None:
    if value is None:
        return None
    value = value.strip()
    return value or None
