from pathlib import Path

from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel, Field

from app.database import fetch_one
from app.security import verify_password
from app.services import respaldos

router = APIRouter(prefix="/respaldos", tags=["respaldos"])


class RespaldoRequest(BaseModel):
    username: str = Field(min_length=1, max_length=60)
    password: str = Field(min_length=1, max_length=128)
    ruta: str = Field(min_length=1, max_length=2048)
    confirmar: bool = False


def autorizar(datos: RespaldoRequest, request: Request):
    if not request.client or request.client.host not in {"127.0.0.1", "::1"}:
        raise HTTPException(403, "Los respaldos solo estan disponibles en la PC local.")
    usuario = fetch_one("SELECT rol, activo, password_hash FROM usuario WHERE username=%s", [datos.username])
    if not usuario or not usuario["activo"] or not verify_password(datos.password, usuario["password_hash"]):
        raise HTTPException(401, "Usuario o contrasena incorrectos.")
    if usuario["rol"] != "JEFE":
        raise HTTPException(403, "Solo un jefe puede gestionar respaldos.")
    if not Path(datos.ruta).is_absolute():
        raise HTTPException(400, "La ruta del respaldo debe ser absoluta.")


@router.post("/crear")
def crear(datos: RespaldoRequest, request: Request):
    autorizar(datos, request)
    try:
        respaldos.crear(Path(datos.ruta))
    except OSError as error:
        raise HTTPException(400, "No se pudo escribir el respaldo. Revisa la carpeta, los permisos y el espacio disponible.") from error
    return {"mensaje": "Respaldo creado correctamente.", "ruta": datos.ruta}


@router.post("/restaurar")
def restaurar(datos: RespaldoRequest, request: Request):
    autorizar(datos, request)
    if not datos.confirmar:
        raise HTTPException(400, "Debes confirmar que se reemplazaran los datos actuales.")
    try:
        return respaldos.restaurar(Path(datos.ruta))
    except respaldos.RecuperacionFallida as error:
        request.app.state.recuperacion_requerida = error.detail
        raise
    except OSError as error:
        raise HTTPException(400, "No se pudo leer el archivo o guardar la copia previa. Revisa permisos y espacio disponible.") from error
