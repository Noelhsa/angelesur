import unittest
from unittest.mock import MagicMock, patch

from app.routers import productos


class ProductoPatchTest(unittest.TestCase):
    def setUp(self):
        self.cursor = MagicMock()

    def ejecutar(self, datos, parcial=True):
        productos._upsert_info_medicamento(
            self.cursor, 7, productos.InfoMedicamentoRequest(**datos),
            parcial=parcial,
        )
        sql, parametros = self.cursor.execute.call_args.args
        return sql.split('ON DUPLICATE KEY UPDATE')[1].strip(), parametros

    def test_dosis_no_sobrescribe_otros_campos(self):
        cambios, parametros = self.ejecutar({'dosis': '20 mg'})
        self.assertEqual(cambios, 'dosis = VALUES(dosis)')
        self.assertEqual(parametros[-1], '20 mg')

    def test_cada_campo_se_actualiza_independientemente(self):
        datos = {
            'presentacion': 'Gotas', 'viaAdministracion': 'ORAL',
            'edad': 'ADULTO', 'requiereReceta': True,
            'sustanciaActiva': 'Ibuprofeno', 'dosis': '100 ml',
        }
        for campo, valor in datos.items():
            with self.subTest(campo=campo):
                cambios, _ = self.ejecutar({campo: valor})
                self.assertEqual(cambios, f'{campo} = VALUES({campo})')

    def test_null_explicito_borra_solo_el_campo_solicitado(self):
        cambios, parametros = self.ejecutar({'dosis': None})
        self.assertEqual(cambios, 'dosis = VALUES(dosis)')
        self.assertIsNone(parametros[-1])

    def test_texto_vacio_se_limpia_explicito(self):
        _, parametros = self.ejecutar({'sustanciaActiva': '  '})
        self.assertIsNone(parametros[-2])

    def test_false_explicito_no_se_ignora(self):
        cambios, parametros = self.ejecutar({'requiereReceta': False})
        self.assertEqual(cambios, 'requiereReceta = VALUES(requiereReceta)')
        self.assertEqual(parametros[4], 0)

    def test_objeto_vacio_no_escribe(self):
        productos._upsert_info_medicamento(
            self.cursor, 7, productos.InfoMedicamentoRequest(), parcial=True
        )
        self.cursor.execute.assert_not_called()

    def test_alta_conserva_valores_iniciales(self):
        cambios, parametros = self.ejecutar({'dosis': '10 ml'}, parcial=False)
        self.assertEqual(len(cambios.split(',')), 6)
        self.assertEqual(parametros, [7, None, None, 'GENERAL', 0, None, '10 ml'])

    def test_objeto_completo_actualiza_todos_los_campos(self):
        cambios, _ = self.ejecutar({
            'presentacion': 'Jarabe', 'viaAdministracion': 'ORAL',
            'edad': 'INFANTIL', 'requiereReceta': False,
            'sustanciaActiva': None, 'dosis': '100 ml',
        })
        self.assertEqual(len(cambios.split(',')), 6)

    def test_endpoint_usa_actualizacion_parcial(self):
        with patch.object(productos, 'obtener_producto', return_value={}), \
                patch.object(productos, 'db_connection') as conexion:
            conexion.return_value.__enter__.return_value.cursor.return_value.__enter__.return_value = self.cursor
            productos.actualizar_producto(
                7, productos.ActualizarProductoRequest(infoMedicamento={'dosis': '20 mg'})
            )
        sql, _ = self.cursor.execute.call_args.args
        self.assertEqual(sql.split('ON DUPLICATE KEY UPDATE')[1].strip(),
                         'dosis = VALUES(dosis)')

    def test_endpoint_omitir_info_o_enviar_null_no_borra_datos(self):
        for datos in ({}, {'infoMedicamento': None}, {'infoMedicamento': {}}):
            with self.subTest(datos=datos), \
                    patch.object(productos, 'obtener_producto', return_value={}), \
                    patch.object(productos, 'db_connection') as conexion:
                self.cursor.reset_mock()
                conexion.return_value.__enter__.return_value.cursor.return_value.__enter__.return_value = self.cursor
                productos.actualizar_producto(7, productos.ActualizarProductoRequest(**datos))
                self.cursor.execute.assert_not_called()


if __name__ == '__main__':
    unittest.main()
