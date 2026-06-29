from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field

from app.database import db_connection, fetch_all, fetch_one

router = APIRouter(prefix="/proveedores", tags=["proveedores"])


class ProveedorBase(BaseModel):
    nombre: str = Field(min_length=1, max_length=150)
    telefono: str | None = Field(default=None, max_length=30)
    contacto: str | None = Field(default=None, max_length=120)
    direccion: str | None = Field(default=None, max_length=255)


class CrearProveedorRequest(ProveedorBase):
    pass


class ActualizarProveedorRequest(BaseModel):
    nombre: str | None = Field(default=None, min_length=1, max_length=150)
    telefono: str | None = Field(default=None, max_length=30)
    contacto: str | None = Field(default=None, max_length=120)
    direccion: str | None = Field(default=None, max_length=255)


class CambiarEstadoProveedorRequest(BaseModel):
    activo: bool


class ProveedorResponse(BaseModel):
    idProveedor: int
    nombre: str
    telefono: str | None
    contacto: str | None
    direccion: str | None
    activo: bool


@router.get("", response_model=list[ProveedorResponse])
def listar_proveedores(
    busqueda: str | None = Query(default=None, min_length=1),
    incluir_inactivos: bool = Query(default=False, alias="incluirInactivos"),
    limite: int = Query(default=200, ge=1, le=1000),
):
    sql = """
        SELECT idProveedor, nombre, telefono, contacto, direccion, activo
        FROM proveedor
    """
    filtros: list[str] = []
    params: list[object] = []

    if not incluir_inactivos:
        filtros.append("activo = %s")
        params.append(1)

    if busqueda:
        filtros.append("(nombre LIKE %s OR contacto LIKE %s OR telefono LIKE %s)")
        like = f"%{busqueda}%"
        params.extend([like, like, like])

    if filtros:
        sql += " WHERE " + " AND ".join(filtros)

    sql += " ORDER BY nombre LIMIT %s"
    params.append(limite)
    return fetch_all(sql, params)


@router.get("/{id_proveedor}", response_model=ProveedorResponse)
def obtener_proveedor(id_proveedor: int):
    proveedor = fetch_one(
        """
        SELECT idProveedor, nombre, telefono, contacto, direccion, activo
        FROM proveedor
        WHERE idProveedor = %s
        """,
        [id_proveedor],
    )

    if not proveedor:
        raise HTTPException(status_code=404, detail="Proveedor no encontrado")

    return proveedor


@router.post("", response_model=ProveedorResponse, status_code=201)
def crear_proveedor(request: CrearProveedorRequest):
    with db_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                INSERT INTO proveedor (nombre, telefono, contacto, direccion)
                VALUES (%s, %s, %s, %s)
                """,
                [
                    request.nombre.strip(),
                    _clean_optional(request.telefono),
                    _clean_optional(request.contacto),
                    _clean_optional(request.direccion),
                ],
            )
            id_proveedor = cursor.lastrowid

    return obtener_proveedor(id_proveedor)


@router.patch("/{id_proveedor}", response_model=ProveedorResponse)
def actualizar_proveedor(id_proveedor: int, request: ActualizarProveedorRequest):
    obtener_proveedor(id_proveedor)

    campos = ["nombre", "telefono", "contacto", "direccion"]
    updates: list[str] = []
    params: list[object] = []

    for campo in campos:
        if campo not in request.model_fields_set:
            continue

        value = getattr(request, campo)
        if isinstance(value, str):
            value = _clean_optional(value)
        updates.append(f"{campo} = %s")
        params.append(value)

    if updates:
        params.append(id_proveedor)
        with db_connection() as connection:
            with connection.cursor() as cursor:
                cursor.execute(
                    f"UPDATE proveedor SET {', '.join(updates)} WHERE idProveedor = %s",
                    params,
                )

    return obtener_proveedor(id_proveedor)


@router.patch("/{id_proveedor}/estado", response_model=ProveedorResponse)
def cambiar_estado_proveedor(
    id_proveedor: int,
    request: CambiarEstadoProveedorRequest,
):
    obtener_proveedor(id_proveedor)

    with db_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                "UPDATE proveedor SET activo = %s WHERE idProveedor = %s",
                [1 if request.activo else 0, id_proveedor],
            )

    return obtener_proveedor(id_proveedor)


def _clean_optional(value: str | None) -> str | None:
    if value is None:
        return None
    value = value.strip()
    return value or None
