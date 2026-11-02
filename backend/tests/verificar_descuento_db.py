"""Prueba de integracion manual: python -m tests.verificar_descuento_db."""
from pathlib import Path
import os
import subprocess
import uuid
from decimal import Decimal
import pymysql
from pymysql.err import OperationalError
from app.config import get_settings
from app.yastas_fondo import cotizar
from unittest.mock import patch
from app.routers.servicios_yastas import CotizarServiciosRequest, cotizar_servicios

s = get_settings()
bin_dir = Path(r'C:\Program Files\MariaDB 11.6\bin')
env = {**os.environ, 'MYSQL_PWD': s.db_password}
args = [str(bin_dir / 'mariadb.exe'), '-h', s.db_host, '-P', str(s.db_port), '-u', s.db_user, '--skip-ssl', '--default-character-set=utf8mb4']
name = 'test_descuento_' + uuid.uuid4().hex
sql = (Path(__file__).resolve().parents[1] / 'database/base_inicial_limpia.sql').read_text(encoding='utf-8').replace('farmacia_angeles_v2', name)
result = subprocess.run(args, input=sql.encode(), env=env, capture_output=True)
if result.returncode:
    print(result.stderr.decode(errors='replace'))
    raise SystemExit(result.returncode)
connection = pymysql.connect(host=s.db_host, port=s.db_port, user=s.db_user, password=s.db_password, database=name, autocommit=True)
try:
    with connection.cursor() as c:
        c.execute("INSERT INTO usuario (nombre,username,password_hash,rol) VALUES ('Prueba','prueba','prueba','JEFE')")
        user = c.lastrowid
        c.execute('CALL sp_abrir_corte(%s,1000,1000,NULL,@corte)', [user])
        while c.nextset(): pass
        for tipo, monto, porcentaje, comision, costo, ganancia, salida in [
            ('RECARGA', '50', '5', '0', '0', '0', '47.50'),
            ('RECARGA', '100', '5', '0', '0', '0', '95'),
            ('PAGO_SERVICIO', '50', '3.5', '0', '0', '0', '48.25'),
            ('RECARGA', '33.33', '5', '0', '0', '0', '31.66'),
            ('PAGO_SERVICIO', '50', '0', '10', '2', '8', '52'),
        ]:
            c.execute('INSERT INTO tarifa_servicio (tipoServicio,nombreServicio,comisionCliente,comisionYastas,gananciaFarmacia,porcentajeDescuentoElectronico) VALUES (%s,%s,%s,%s,%s,%s)', [tipo,uuid.uuid4().hex,comision,costo,Decimal(comision)-Decimal(costo),porcentaje])
            tarifa = c.lastrowid
            c.execute('CALL sp_registrar_servicio_yastas(%s,%s,%s,NULL,NULL,@operacion)', [user,tarifa,monto])
            while c.nextset(): pass
            c.execute('SELECT totalCobradoCliente,gananciaFarmacia FROM servicio_operacion WHERE idServicioOperacion=@operacion')
            assert c.fetchone() == (Decimal(monto)+Decimal(comision),Decimal(ganancia))
            c.execute("SELECT monto FROM movimiento_dinero WHERE idServicioOperacion=@operacion AND medio='ELECTRONICO' AND tipo='SALIDA'")
            assert c.fetchone()[0] == Decimal(salida)
            c.execute("SELECT medio,tipo,monto FROM movimiento_dinero WHERE idServicioOperacion=@operacion ORDER BY medio")
            assert c.fetchall() == (('EFECTIVO', 'ENTRADA', Decimal(monto)+Decimal(comision)), ('ELECTRONICO', 'SALIDA', Decimal(salida)))
            c.execute('UPDATE tarifa_servicio SET porcentajeDescuentoElectronico=1 WHERE idTarifa=%s', [tarifa])
            c.execute('CALL sp_cancelar_servicio_yastas(%s,@operacion,NULL)', [user])
            while c.nextset(): pass
            c.execute("SELECT medio,SUM(IF(tipo='ENTRADA',monto,-monto)) FROM movimiento_dinero WHERE idServicioOperacion=@operacion GROUP BY medio")
            assert all(row[1] == 0 for row in c.fetchall())
        print('OK: 5 escenarios, comisiones anteriores, redondeo y cancelacion tras cambio de tarifa.')
        c.execute('CALL sp_cerrar_corte(%s,1000,1000,NULL)', [user])
        while c.nextset(): pass
        for propio, monto, tasa, esperado_fondo in [('20','50','3.5','28.25'), ('20','30','5','8.50'), ('0','50',None,'48.25'), ('60','50',None,'0')]:
            c.execute('CALL sp_abrir_corte_fondo(%s,1000,%s,100,3.5,NULL,@corte)', [user,propio])
            while c.nextset(): pass
            c.execute('SELECT @corte')
            corte = c.fetchone()[0]
            c.execute("INSERT INTO tarifa_servicio (tipoServicio,nombreServicio,porcentajeDescuentoElectronico) VALUES ('RECARGA',%s,5)", [uuid.uuid4().hex])
            tarifa = c.lastrowid
            t = {'tipoServicio':'RECARGA','comisionYastas':Decimal(0),'porcentajeDescuentoElectronico':Decimal(5)}
            q = cotizar(t,Decimal(monto),Decimal(propio),Decimal(100),Decimal('3.5'), Decimal(tasa) if tasa else None)
            parametros = [user,tarifa,monto,None,'Nota del usuario',tasa,corte,propio,100,q['salidaElectronica']]
            if tasa:
                try:
                    c.execute('CALL sp_registrar_servicio_yastas(%s,%s,%s,NULL,NULL,@operacion)', [user,tarifa,monto])
                    raise AssertionError('Se acepto una operacion mixta sin seleccion')
                except OperationalError as exc:
                    assert 'Selecciona' in str(exc)
            c.execute('CALL sp_registrar_servicio_yastas_fondo(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,@operacion)', parametros)
            while c.nextset(): pass
            c.execute('SELECT montoFondoYastas,montoElectronicoPropio,gananciaFarmacia,observaciones,porcentajeDescuentoElectronico FROM servicio_operacion WHERE idServicioOperacion=@operacion')
            fondo_usado, propio_usado, ganancia, nota, porcentaje = c.fetchone()
            assert fondo_usado == Decimal(esperado_fondo)
            assert propio_usado == q['montoPropio'] and ganancia == 0
            assert porcentaje == q['porcentajeAplicado']
            assert 'Nota del usuario' in nota
            if fondo_usado:
                assert 'fondo $' in nota
                if tasa: assert 'elegido por el usuario' in nota
            c.execute("SELECT fn_saldo_corte(%s,'ELECTRONICO'),fn_fondo_yastas_disponible(%s)", [corte,corte])
            assert c.fetchone() == (Decimal(propio)-propio_usado,Decimal(100)-fondo_usado)
            # La misma confirmacion ya no representa el saldo actual.
            try:
                c.execute('CALL sp_registrar_servicio_yastas_fondo(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,@otra)', parametros)
                raise AssertionError('Se acepto una confirmacion obsoleta')
            except OperationalError as exc:
                assert 'saldos cambiaron' in str(exc)
            c.execute('UPDATE tarifa_servicio SET porcentajeDescuentoElectronico=2 WHERE idTarifa=%s', [tarifa])
            c.execute('CALL sp_cancelar_servicio_yastas(%s,@operacion,NULL)', [user])
            while c.nextset(): pass
            c.execute("SELECT fn_saldo_corte(%s,'ELECTRONICO'),fn_fondo_yastas_disponible(%s)", [corte,corte])
            assert c.fetchone() == (Decimal(propio),Decimal(100))
            c.execute('CALL sp_cerrar_corte(%s,1000,%s,NULL)', [user,propio])
            while c.nextset(): pass
        # Insuficiencia del fondo revierte tambien la operacion y el efectivo.
        c.execute('CALL sp_abrir_corte_fondo(%s,1000,0,1,3.5,NULL,@corte)', [user])
        while c.nextset(): pass
        c.execute("SELECT COUNT(*) FROM servicio_operacion")
        antes = c.fetchone()[0]
        try:
            c.execute('CALL sp_registrar_servicio_yastas(%s,%s,50,NULL,NULL,@operacion)', [user,tarifa])
            raise AssertionError('Fondo insuficiente aceptado')
        except OperationalError as exc:
            assert 'insuficientes' in str(exc)
        c.execute('SELECT COUNT(*) FROM servicio_operacion')
        assert c.fetchone()[0] == antes
        c.execute('CALL sp_cerrar_corte(%s,1000,0,NULL)', [user])
        while c.nextset(): pass
        c.execute('CALL sp_abrir_corte_fondo(%s,1000,20,100,3.5,NULL,@corte)', [user])
        while c.nextset(): pass
        c.execute('UPDATE tarifa_servicio SET porcentajeDescuentoElectronico=5 WHERE idTarifa=%s', [tarifa])
        with patch('app.database.get_settings', return_value=s.model_copy(update={'db_name':name})):
            request = CotizarServiciosRequest(servicios=[dict(idTarifa=tarifa,montoServicio=30),dict(idTarifa=tarifa,montoServicio=50)])
            respuesta = cotizar_servicios(request)
            assert len(respuesta) == 1 and respuesta[0]['requiereSeleccion']
            request.servicios[0].porcentajeElegido = Decimal(5)
            respuesta = cotizar_servicios(request)
            assert len(respuesta) == 2
            assert respuesta[0]['montoFondo'] == Decimal('8.50')
            assert respuesta[1]['saldoPropio'] == 0 and respuesta[1]['fondoDisponible'] == Decimal('91.50')
            assert respuesta[1]['montoFondo'] == Decimal('48.25')
        print('OK: mixtas 20/50 al 3.5%, 20/30 al 5%, solo fondo, solo propio, notas, concurrencia, cancelacion y fondo insuficiente.')
finally:
    with connection.cursor() as c:
        c.execute(f'DROP DATABASE `{name}`')
    connection.close()


