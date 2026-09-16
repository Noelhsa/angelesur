import asyncio
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from fastapi import HTTPException
from app.services import respaldos
from app.routers.respaldos import autorizar, RespaldoRequest
from app.main import app, mantenimiento_respaldos


class RespaldosTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.config = SimpleNamespace(db_name="farmacia_angeles_v2", backup_dir=str(self.root))
        self.patcher = patch.object(respaldos, "get_settings", return_value=self.config)
        self.patcher.start()
        self.addCleanup(self.patcher.stop)

    def test_no_sobrescribe_respaldo(self):
        destino = self.root / "original.sql"
        destino.write_text("datos originales")
        with patch.object(respaldos, "herramienta", return_value="dump"):
            with self.assertRaises(HTTPException) as error:
                respaldos.crear(destino)
        self.assertEqual(error.exception.status_code, 409)
        self.assertEqual(destino.read_text(), "datos originales")

    def test_elimina_archivo_incompleto(self):
        destino = self.root / "fallido.sql"
        with patch.object(respaldos, "herramienta"), patch.object(respaldos, "ejecutar", side_effect=HTTPException(500, "fallo")):
            with self.assertRaises(HTTPException):
                respaldos.crear(destino)
        self.assertFalse(destino.exists())

    def test_rechaza_otra_base(self):
        destino = self.root / "otra.sql"
        destino.write_text("USE `otra`; CREATE TABLE prueba(id int);")
        with self.assertRaises(HTTPException):
            respaldos.validar(destino)

    def test_restauracion_fallida_recupera_copia_previa(self):
        origen = self.root / "original.sql"
        origen.write_text("USE `farmacia_angeles_v2`; CREATE TABLE usuario(id int);")
        with patch.object(respaldos, "herramienta"), patch.object(respaldos, "crear") as crear, patch.object(respaldos, "importar", side_effect=[HTTPException(500, "SQL invalido"), None]) as importar, patch("app.database.fetch_all", return_value=[]):
            with self.assertRaises(HTTPException) as error:
                respaldos.restaurar(origen)
        self.assertIn("se recuperaron", error.exception.detail)
        self.assertEqual(importar.call_count, 2)
        self.assertEqual(importar.call_args_list[1].args[0], crear.call_args.args[0])

    def test_no_importa_si_falla_copia_previa(self):
        origen = self.root / "original.sql"
        origen.write_text("USE `farmacia_angeles_v2`; CREATE TABLE usuario(id int);")
        with patch.object(respaldos, "herramienta"), patch.object(respaldos, "crear", side_effect=HTTPException(500, "sin espacio")), patch.object(respaldos, "importar") as importar, patch("app.database.fetch_all", return_value=[]):
            with self.assertRaises(HTTPException):
                respaldos.restaurar(origen)
        importar.assert_not_called()

    def test_restauracion_exitosa_conserva_copia(self):
        origen = self.root / "original.sql"
        origen.write_text("USE `farmacia_angeles_v2`; CREATE TABLE usuario(id int);")
        with patch.object(respaldos, "herramienta"), patch.object(respaldos, "crear") as crear, patch.object(respaldos, "importar") as importar, patch("app.database.fetch_all", return_value=[]), patch("app.database.fetch_one", return_value={"idUsuario": 1}):
            result = respaldos.restaurar(origen)
        self.assertEqual(result["respaldoPrevio"], str(crear.call_args.args[0]))
        importar.assert_called_once()

    def test_sin_jefe_recupera_datos_previos(self):
        origen = self.root / "original.sql"
        origen.write_text("USE `farmacia_angeles_v2`; CREATE TABLE usuario(id int);")
        with patch.object(respaldos, "herramienta"), patch.object(respaldos, "crear"), patch.object(respaldos, "importar") as importar, patch("app.database.fetch_all", return_value=[]), patch("app.database.fetch_one", return_value=None):
            with self.assertRaises(HTTPException):
                respaldos.restaurar(origen)
        self.assertEqual(importar.call_count, 2)

    def test_recuperacion_fallida_informa_ruta(self):
        origen = self.root / "original.sql"
        origen.write_text("USE `farmacia_angeles_v2`; CREATE TABLE usuario(id int);")
        with patch.object(respaldos, "herramienta"), patch.object(respaldos, "crear"), patch.object(respaldos, "importar", side_effect=HTTPException(500, "fallo")), patch("app.database.fetch_all", return_value=[]):
            with self.assertRaises(respaldos.RecuperacionFallida) as error:
                respaldos.restaurar(origen)
        self.assertIn("antes_restaurar_", error.exception.detail)

    def test_empleado_no_autorizado(self):
        datos = RespaldoRequest(username="empleado", password="1234", ruta=str(self.root / "copia.sql"))
        request = SimpleNamespace(client=SimpleNamespace(host="127.0.0.1"))
        with patch("app.routers.respaldos.fetch_one", return_value={"activo": 1, "rol": "EMPLEADO", "password_hash": "hash"}), patch("app.routers.respaldos.verify_password", return_value=True):
            with self.assertRaises(HTTPException) as error:
                autorizar(datos, request)
        self.assertEqual(error.exception.status_code, 403)

    def test_bloquea_solicitudes_durante_respaldo(self):
        async def escenario():
            app.state.respaldo_en_curso = True
            try:
                result = await mantenimiento_respaldos(SimpleNamespace(url=SimpleNamespace(path="/ventas"), method="POST"), None)
                self.assertEqual(result.status_code, 503)
            finally:
                app.state.respaldo_en_curso = False
        asyncio.run(escenario())


if __name__ == "__main__":
    unittest.main()
