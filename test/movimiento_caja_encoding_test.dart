import 'package:angelesur/services/caja_api_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Corrige observaciones historicas de salida y entrada Yastas', () {
    for (final prefijo in ['Salida', 'Entrada']) {
      final movimiento = MovimientoCaja.fromJson({
        'observaciones': '$prefijo electr\u00c3\u00b3nica servicio Yastas 2',
      });
      expect(movimiento.observaciones,
          '$prefijo electr\u00f3nica servicio Yastas 2');
    }
  });

  test('Conserva texto correcto, referencias y observaciones vacias', () {
    const texto = 'Salida electrónica servicio Yastas 2 | José Muñoz B';
    expect(
        MovimientoCaja.fromJson({'observaciones': texto}).observaciones, texto);
    expect(MovimientoCaja.fromJson({}).observaciones, '');
    expect(MovimientoCaja.fromJson({'observaciones': null}).observaciones, '');
  });
}
