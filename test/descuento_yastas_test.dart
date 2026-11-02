import 'package:flutter_test/flutter_test.dart';
import 'package:angelesur/services/servicios_yastas_api_service.dart';

void main() {
  test('Descuento reduce salida sin registrar ganancia adicional', () {
    final tarifa = TarifaServicioYastas.fromJson({
      'tipoServicio': 'RECARGA', 'porcentajeDescuentoElectronico': '5.00',
    });
    expect(tarifa.totalCobrado(50), 50);
    expect(tarifa.salidaElectronica(50), 47.50);
    expect(tarifa.gananciaPara(50), 0);
    expect(tarifa.descuentoPara(33.33), 1.67);
  });
  test('Tarifa anterior mantiene comisiones', () {
    final tarifa = TarifaServicioYastas.fromJson({
      'comisionCliente': 10, 'comisionYastas': 2, 'gananciaFarmacia': 8,
    });
    expect(tarifa.totalCobrado(50), 60);
    expect(tarifa.salidaElectronica(50), 52);
    expect(tarifa.gananciaPara(50), 8);
  });
}
