from decimal import Decimal, ROUND_HALF_UP
from fastapi import HTTPException


def cotizar(tarifa, monto, propio, fondo, porcentaje_fondo, elegido=None):
    """Vista previa; la rutina SQL vuelve a validar bajo bloqueo del corte."""
    normal = tarifa['porcentajeDescuentoElectronico']
    retiro = tarifa['tipoServicio'] == 'RETIRO'
    costo = tarifa['comisionYastas']
    def salida(tasa):
        return monto + costo - (monto * tasa / 100).quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)
    requiere = not retiro and normal > 0 and propio > 0 and salida(normal) > propio
    porcentaje = normal
    if not retiro and normal > 0 and salida(normal) > propio:
        if propio == 0:
            porcentaje = porcentaje_fondo
        elif elegido is not None:
            if elegido not in (normal, porcentaje_fondo):
                raise HTTPException(400, 'Selecciona el porcentaje normal o el del fondo')
            porcentaje = elegido
    debito = Decimal('0') if retiro else salida(porcentaje)
    uso_propio = min(propio, debito)
    uso_fondo = debito - uso_propio
    if not retiro and (debito <= 0 or (uso_fondo > fondo and (not requiere or elegido is not None))):
        raise HTTPException(400, 'Saldo propio y fondo Yastas insuficientes')
    return {
        'porcentajeNormal': normal, 'porcentajeFondo': porcentaje_fondo,
        'porcentajeAplicado': porcentaje, 'requiereSeleccion': requiere and elegido is None,
        'saldoPropio': propio, 'fondoDisponible': fondo,
        'montoPropio': uso_propio, 'montoFondo': uso_fondo, 'salidaElectronica': debito,
    }
