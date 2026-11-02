from decimal import Decimal as D
import unittest
from fastapi import HTTPException
from app.yastas_fondo import cotizar
from app.routers.cortes import AbrirCorteRequest


class FondoYastasTest(unittest.TestCase):
    def setUp(self):
        self.tarifa = dict(tipoServicio='RECARGA', comisionYastas=D(0), porcentajeDescuentoElectronico=D(5))

    def test_mixto_requiere_eleccion_y_respeta_ambos_porcentajes(self):
        for monto, tasa, salida in [('50','3.5','48.25'), ('30','5','28.50')]:
            q = cotizar(self.tarifa,D(monto),D(20),D(100),D('3.5'))
            self.assertTrue(q['requiereSeleccion'])
            q = cotizar(self.tarifa,D(monto),D(20),D(100),D('3.5'),D(tasa))
            self.assertFalse(q['requiereSeleccion'])
            self.assertEqual(q['salidaElectronica'],D(salida))
            self.assertEqual(q['montoFondo'],D(salida)-20)

    def test_tasa_fondo_configurable_y_normal_sin_cambios(self):
        q = cotizar(self.tarifa,D(50),D(0),D(100),D(4))
        self.assertEqual(q['montoFondo'],D(48))
        self.tarifa.update(porcentajeDescuentoElectronico=D(0),comisionYastas=D(2))
        q = cotizar(self.tarifa,D(50),D(20),D(100),D(4))
        self.assertFalse(q['requiereSeleccion'])
        self.assertEqual(q['porcentajeAplicado'],0)
        self.assertEqual(q['salidaElectronica'],52)

    def test_limites(self):
        with self.assertRaises(HTTPException):
            cotizar(self.tarifa,D(50),D(20),D(100),D('3.5'),D(9))
        with self.assertRaises(HTTPException):
            cotizar(self.tarifa,D(50),D(0),D(1),D('3.5'))
        req = AbrirCorteRequest(idUsuario=1)
        self.assertEqual(req.fondo_yastas,0)
        self.assertEqual(req.porcentaje_fondo,D('3.5'))
