from typing import Literal

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field

from app.database import db_connection, fetch_all, fetch_one
from app.security import hash_password, verify_password

router = APIRouter(tags=["usuarios"])


class UsuarioResponse(BaseModel):
    idUsuario: int
    nombre: str
    username: str
    telefono: str | None
    rol: Literal["JEFE", "EMPLEADO"]
    activo: bool


class CrearUsuarioRequest(BaseModel):
    nombre: str = Field(min_length=1, max_length=120)
    username: str = Field(min_length=1, max_length=60)
    password: str = Field(min_length=4, max_length=128)
    rol: Literal["JEFE", "EMPLEADO"]
    telefono: str | None = Field(default=None, max_length=20)


class ActualizarUsuarioRequest(BaseModel):
    nombre: str | None = Field(default=None, min_length=1, max_length=120)
    username: str | None = Field(default=None, min_length=1, max_length=60)
    password: str | None = Field(default=None, min_length=4, max_length=128)
    rol: Literal["JEFE", "EMPLEADO"] | None = None
    telefono: str | None = Field(default=None, max_length=20)


class LoginRequest(BaseModel):
    username: str
    password: str


class CambiarEstadoUsuarioRequest(BaseModel):
    activo: bool


@router.get("/usuarios", response_model=list[UsuarioResponse])
def listar_usuarios(
    incluir_inactivos: bool = Query(default=False, alias="incluirInactivos"),
):
    sql = """
        SELECT idUsuario, nombre, username, telefono, rol, activo
        FROM usuario
    """
    params: list[object] = []

    if not incluir_inactivos:
        sql += " WHERE activo = %s"
        params.append(1)

    sql += " ORDER BY nombre"
    return fetch_all(sql, params)


@router.get("/usuarios/{id_usuario}", response_model=UsuarioResponse)
def obtener_usuario(id_usuario: int):
    usuario = fetch_one(
        """
        SELECT idUsuario, nombre, username, telefono, rol, activo
        FROM usuario
        WHERE idUsuario = %s
        """,
        [id_usuario],
    )

    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    return usuario


@router.post("/usuarios", response_model=UsuarioResponse, status_code=201)
def crear_usuario(request: CrearUsuarioRequest):
    password_hash = hash_password(request.password)

    with db_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                INSERT INTO usuario (nombre, username, telefono, password_hash, rol)
                VALUES (%s, %s, %s, %s, %s)
                """,
                [
                    request.nombre.strip(),
                    request.username.strip(),
                    request.telefono.strip() if request.telefono else None,
                    password_hash,
                    request.rol,
                ],
            )
            id_usuario = cursor.lastrowid

    return obtener_usuario(id_usuario)


@router.patch("/usuarios/{id_usuario}", response_model=UsuarioResponse)
def actualizar_usuario(id_usuario: int, request: ActualizarUsuarioRequest):
    obtener_usuario(id_usuario)

    updates: list[str] = []
    params: list[object] = []

    if "nombre" in request.model_fields_set:
        if request.nombre is None or not request.nombre.strip():
            raise HTTPException(status_code=400, detail="El nombre es obligatorio")
        updates.append("nombre = %s")
        params.append(request.nombre.strip())

    if "username" in request.model_fields_set:
        if request.username is None or not request.username.strip():
            raise HTTPException(status_code=400, detail="El username es obligatorio")
        existente = fetch_one(
            """
            SELECT idUsuario
            FROM usuario
            WHERE username = %s AND idUsuario <> %s
            LIMIT 1
            """,
            [request.username.strip(), id_usuario],
        )
        if existente:
            raise HTTPException(status_code=400, detail="El username ya esta en uso")
        updates.append("username = %s")
        params.append(request.username.strip())

    if "telefono" in request.model_fields_set:
        updates.append("telefono = %s")
        params.append(request.telefono.strip() if request.telefono else None)

    if "rol" in request.model_fields_set:
        updates.append("rol = %s")
        params.append(request.rol)

    if "password" in request.model_fields_set and request.password:
        updates.append("password_hash = %s")
        params.append(hash_password(request.password))

    if updates:
        params.append(id_usuario)
        with db_connection() as connection:
            with connection.cursor() as cursor:
                cursor.execute(
                    f"UPDATE usuario SET {', '.join(updates)} WHERE idUsuario = %s",
                    params,
                )

    return obtener_usuario(id_usuario)


@router.patch("/usuarios/{id_usuario}/estado", response_model=UsuarioResponse)
def cambiar_estado_usuario(id_usuario: int, request: CambiarEstadoUsuarioRequest):
    if not obtener_usuario(id_usuario):
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    with db_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                "UPDATE usuario SET activo = %s WHERE idUsuario = %s",
                [1 if request.activo else 0, id_usuario],
            )

    return obtener_usuario(id_usuario)


@router.post("/auth/login", response_model=UsuarioResponse)
def login(request: LoginRequest):
    usuario = fetch_one(
        """
        SELECT idUsuario, nombre, username, telefono, password_hash, rol, activo
        FROM usuario
        WHERE username = %s
        LIMIT 1
        """,
        [request.username.strip()],
    )

    if not usuario or not usuario["activo"]:
        raise HTTPException(status_code=401, detail="Usuario o contrasena incorrectos")

    if not verify_password(request.password, usuario["password_hash"]):
        raise HTTPException(status_code=401, detail="Usuario o contrasena incorrectos")

    usuario.pop("password_hash", None)
    return usuario
