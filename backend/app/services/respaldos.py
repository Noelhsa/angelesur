"""Local MariaDB backup operations. Never invoke a shell for SQL files."""

from datetime import datetime
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

from fastapi import HTTPException

from app.config import get_settings


class RecuperacionFallida(HTTPException):
    pass


def herramienta(nombre: str) -> str:
    config = get_settings()
    candidatos = []
    if config.mariadb_bin:
        candidatos.append(Path(config.mariadb_bin) / f"{nombre}.exe")
    encontrado = shutil.which(nombre)
    if encontrado:
        candidatos.append(Path(encontrado))
    for root in [os.environ.get("ProgramFiles", "C:/Program Files"),
                 os.environ.get("ProgramFiles(x86)", "C:/Program Files (x86)")]:
        candidatos.extend(sorted(Path(root).glob(f"MariaDB*/bin/{nombre}.exe"), reverse=True))
    for candidato in candidatos:
        if candidato.is_file():
            return str(candidato.resolve())
    raise HTTPException(503, f"No se encontro {nombre}. Instala las herramientas de MariaDB "
                        "o configura ANGELESUR_MARIADB_BIN en .env.")


def ejecutar(nombre, argumentos, *, entrada=None, salida=None):
    config = get_settings()
    # A private temporary directory keeps credentials off process command lines.
    with tempfile.TemporaryDirectory(prefix="angelesur-db-") as temporal:
        opciones = Path(temporal) / "client.cnf"
        password = config.db_password.replace("\\", "\\\\").replace('"', '\\"')
        password = password.replace("\n", "\\n").replace("\r", "\\r")
        opciones.write_text(f'[client]\npassword="{password}"\n', encoding="utf-8")
        try:
            result = subprocess.run(
                [herramienta(nombre), f"--defaults-file={opciones}",
                 "--protocol=tcp", f"--host={config.db_host}", f"--port={config.db_port}",
                 f"--user={config.db_user}", "--default-character-set=utf8mb4",
                 *(["--skip-ssl"] if config.db_host in {"127.0.0.1", "localhost", "::1"} else []),
                 *argumentos],
                stdin=entrada, stdout=salida or subprocess.DEVNULL,
                stderr=subprocess.PIPE, timeout=1800,
                creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0),
            )
        except subprocess.TimeoutExpired as error:
            raise HTTPException(504, "MariaDB excedio el tiempo de espera de 30 minutos.") from error
        if result.returncode:
            detalle = result.stderr.decode("utf-8", errors="replace")[-1600:]
            if config.db_password:
                detalle = detalle.replace(config.db_password, "***")
            raise HTTPException(500, f"MariaDB no pudo completar la operacion: {detalle}")


def crear(destino: Path):
    if destino.suffix.lower() != ".sql" or not destino.parent.is_dir():
        raise HTTPException(400, "Selecciona una carpeta existente y un archivo .sql.")
    herramienta("mariadb-dump")
    try:
        archivo = destino.open("xb")
    except FileExistsError as error:
        raise HTTPException(409, "Ese archivo ya existe. Elige otro nombre para conservarlo.") from error
    try:
        with archivo:
            ejecutar("mariadb-dump", ["--single-transaction", "--quick", "--routines",
                     "--events", "--triggers", "--hex-blob", "--add-drop-database",
                     "--databases", get_settings().db_name], salida=archivo)
    except Exception:
        destino.unlink(missing_ok=True)
        raise


def validar(origen: Path):
    if origen.suffix.lower() != ".sql" or not origen.is_file():
        raise HTTPException(400, "Selecciona un respaldo SQL existente.")
    # Check the dump's database declaration before any destructive operation.
    with origen.open("rb") as archivo:
        encabezado = archivo.read(128 * 1024).decode("utf-8-sig", errors="replace")
    nombre = get_settings().db_name
    if f"USE `{nombre}`;" not in encabezado or "CREATE TABLE" not in encabezado:
        raise HTTPException(400, f"El archivo no es un volcado completo de {nombre}.")


def importar(origen: Path):
    with origen.open("rb") as archivo:
        ejecutar("mariadb", ["--binary-mode", "--batch"], entrada=archivo)


def restaurar(origen: Path):
    validar(origen)
    herramienta("mariadb")
    config = get_settings()
    carpeta = Path(config.backup_dir) if config.backup_dir else (
        Path(os.environ.get("LOCALAPPDATA", str(Path.home()))) / "Angelesur" / "Respaldos"
    )
    carpeta.mkdir(parents=True, exist_ok=True)
    previo = carpeta / f"antes_restaurar_{datetime.now():%Y%m%d_%H%M%S_%f}.sql"
    from app.database import fetch_all, fetch_one
    tablas = {row["TABLE_NAME"] for row in fetch_all(
        "SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA=%s", [config.db_name])}
    rutinas = {row["ROUTINE_NAME"] for row in fetch_all(
        "SELECT ROUTINE_NAME FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA=%s", [config.db_name])}
    # Copy the selected file first so it cannot change during the safety backup.
    with tempfile.TemporaryDirectory(prefix="angelesur-restaurar-") as temporal:
        copia = Path(temporal) / "restaurar.sql"
        shutil.copyfile(origen, copia)
        validar(copia)
        crear(previo)
        try:
            importar(copia)
            nuevas_tablas = {row["TABLE_NAME"] for row in fetch_all(
                "SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA=%s", [config.db_name])}
            nuevas_rutinas = {row["ROUTINE_NAME"] for row in fetch_all(
                "SELECT ROUTINE_NAME FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA=%s", [config.db_name])}
            if not tablas.issubset(nuevas_tablas) or not rutinas.issubset(nuevas_rutinas):
                raise HTTPException(400, "El respaldo esta incompleto: faltan tablas, vistas o procedimientos.")
            if not fetch_one("SELECT idUsuario FROM usuario WHERE rol='JEFE' AND activo=1 LIMIT 1"):
                raise HTTPException(400, "El respaldo no contiene un jefe activo.")
        except Exception as error:
            try:
                importar(previo)
            except Exception as recovery_error:
                raise RecuperacionFallida(500, f"Fallo la restauracion y la recuperacion automatica. "
                                    f"No uses el sistema. Recupera manualmente: {previo}") from recovery_error
            raise HTTPException(400, f"No se pudo restaurar; se recuperaron los datos anteriores. "
                                f"Copia de seguridad: {previo}. "
                                f"{getattr(error, 'detail', 'Archivo incompatible')}") from error
    return {"mensaje": "Respaldo restaurado. Inicia sesion nuevamente.", "respaldoPrevio": str(previo)}
