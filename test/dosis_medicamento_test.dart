import 'dart:convert';
import 'package:angelesur/models/dosis_medicamento.dart';
import 'package:angelesur/ui/interfaces/contenido_catalogo_producto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('Separa unidades y conserva concentraciones completas', () {
    for (final texto in ['100 ML', '100ml']) {
      final dosis = DosisMedicamento.desdeTexto(texto);
      expect(dosis.cantidad, '100');
      expect(dosis.unidad, 'ml');
      expect(dosis.guardar('200', dosis.unidad), '200 ml');
      expect(dosis.guardar('', dosis.unidad), isNull);
    }
    final dosis = DosisMedicamento.desdeTexto('5 mg/5 ml');
    expect(dosis.unidad, 'mg/5 ml');
    expect(dosis.guardar('10', dosis.unidad), '10 mg/5 ml');
    final libre = DosisMedicamento.desdeTexto('Segun indicacion');
    expect(libre.unidad, DosisMedicamento.sinUnidad);
    expect(libre.guardar('Nueva indicacion', libre.unidad), 'Nueva indicacion');
    expect(DosisMedicamento.desdeTexto(null).guardar('2', 'g'), '2 g');
  });

  for (final texto in <String?>[
    '100 ML',
    '100ml',
    '5 mg/ml',
    '5 mg/5 ml',
    '10 ml',
    '0,5 g',
    'Segun indicacion',
    '100',
    '2 unidades especiales',
    null,
    '',
  ]) {
    testWidgets('Guardar edicion conserva dosis: $texto', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      Map<String, dynamic>? enviado;
      final producto = {
        'idProducto': 1,
        'nombre': 'Prueba',
        'tipo': 'MEDICAMENTO',
        'activo': true,
        'manejaCaducidad': true,
        'presentacion': 'TABLETA',
        'viaAdministracion': 'ORAL',
        'edad': 'GENERAL',
        'requiereReceta': false,
        'dosis': texto,
      };
      final cliente = MockClient((request) async {
        if (request.method == 'PATCH') {
          enviado = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(jsonEncode(producto), 200);
        }
        return http.Response(jsonEncode([producto]), 200);
      });
      await http.runWithClient(() async {
        await tester.pumpWidget(const MaterialApp(
          home: Scaffold(body: ContenidoCatalogoProducto()),
        ));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Editar'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Guardar'));
        await tester.pumpAndSettle();
        expect(enviado, isNotNull);
        expect(
            enviado!['infoMedicamento']['dosis'], texto == '' ? null : texto);
        expect(tester.takeException(), isNull);
      }, () => cliente);
    });
  }
}
