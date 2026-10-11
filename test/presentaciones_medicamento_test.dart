import 'package:angelesur/models/presentaciones_medicamento.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Todas las opciones conservan su presentacion al crear, leer y editar',
      () {
    for (final opcion in presentacionesMedicamento.entries) {
      expect(normalizarPresentacion(opcion.value), opcion.key);
      expect(presentacionVisible(opcion.key), opcion.value);
      expect(presentacionVisible(opcion.value), opcion.value);
      expect(normalizarPresentacion(presentacionVisible(opcion.value)),
          opcion.key);
    }
  });
  test('Admite valores historicos con acentos, espacios y plurales', () {
    expect(presentacionVisible(' c\u00e1psulas '), 'Capsula');
    expect(presentacionVisible('TABLETAS'), 'Tableta');
    expect(presentacionVisible('Suspensi\u00f3n'), 'Suspension');
    expect(presentacionVisible('Inyectable'), 'Inyectable');
    expect(presentacionVisible('Spray'), 'Spray');
  });
  test('No convierte valores desconocidos ni ausentes en Otro', () {
    expect(presentacionVisible('Polvo para preparar'), 'Polvo para preparar');
    expect(normalizarPresentacion(presentacionVisible('Polvo para preparar')),
        'Polvo para preparar');
    expect(normalizarPresentacion(presentacionVisible(null)), '');
    expect(normalizarPresentacion('Otros'), 'OTRO');
  });
}
