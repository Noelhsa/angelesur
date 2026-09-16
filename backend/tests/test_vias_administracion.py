from pathlib import Path
import unittest

from pydantic import ValidationError
from app.routers.productos import InfoMedicamentoRequest


class ViasAdministracionTest(unittest.TestCase):
    def test_vias_validas_con_presentacion_independiente(self):
        vias = ['ORAL', 'SUBLINGUAL', 'RECTAL', 'INTRAVENOSA', 'INTRAMUSCULAR',
                'SUBCUTANEA', 'INTRADERMICA', 'TOPICA', 'INHALATORIA',
                'OFTALMICA', 'OTICA', 'NASAL', 'VAGINAL']
        for via in vias:
            with self.subTest(via=via):
                datos = InfoMedicamentoRequest(presentacion='Gotas', viaAdministracion=via)
                self.assertEqual(datos.viaAdministracion, via)
                self.assertEqual(datos.presentacion, 'Gotas')

    def test_rechaza_presentaciones_como_vias(self):
        for via in ['TABLETA', 'CAPSULA', 'GOTAS', 'INYECCION', 'OTRO']:
            with self.subTest(via=via), self.assertRaises(ValidationError):
                InfoMedicamentoRequest(viaAdministracion=via)

    def test_via_pendiente_no_inventa_un_valor(self):
        self.assertIsNone(InfoMedicamentoRequest().viaAdministracion)

    def test_base_inicial_coincide_con_api(self):
        from typing import get_args
        from app.routers.productos import ViaAdministracion
        sql = (Path(__file__).resolve().parents[1] / 'database/base_inicial_limpia.sql').read_text(encoding='utf-8')
        columna = next(line for line in sql.splitlines() if '`viaAdministracion` enum(' in line)
        valores = columna.split('enum(', 1)[1].split(')', 1)[0]
        self.assertEqual(tuple(value.strip("'") for value in valores.split(',')), get_args(ViaAdministracion))
