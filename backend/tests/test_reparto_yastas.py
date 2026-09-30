from decimal import Decimal
import unittest
from fastapi import HTTPException
from app.routers.servicios_yastas import _validar_reparto_tarifa


class RepartoYastasTest(unittest.TestCase):
    def test_repartos_exactos(self):
        for valores in [('10', '2', '1', '7'), ('0', '0', '0', '0'),
                        ('0.30', '0.10', '0.10', '0.10')]:
            _validar_reparto_tarifa(*(Decimal(v) for v in valores))

    def test_rechaza_faltantes_excedentes_y_fracciones_de_centavo(self):
        for valores in [('10', '2', '1', '3'), ('10', '2', '1', '8'),
                        ('0.003', '0.001', '0.001', '0.001'),
                        ('10', '-1', '1', '10')]:
            with self.subTest(valores=valores), self.assertRaises(HTTPException):
                _validar_reparto_tarifa(*(Decimal(v) for v in valores))

    def test_null_explicito_es_error_de_validacion(self):
        with self.assertRaises(HTTPException):
            _validar_reparto_tarifa(None, Decimal('0'), Decimal('0'), Decimal('0'))
