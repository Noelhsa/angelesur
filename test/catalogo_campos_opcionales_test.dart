import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:angelesur/ui/interfaces/contenido_catalogo_producto.dart';

void main() {
  for (final medicamento in [false, true]) {
    for (final asignado in [false, true]) {
      for (final cambiar in [false, true]) {
        testWidgets(
            'Opcional medicamento=$medicamento asignado=$asignado cambiar=$cambiar',
            (tester) async {
          await tester.binding.setSurfaceSize(const Size(1600, 1200));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final campo = medicamento ? 'edad' : 'categoria';
          final valor = medicamento ? 'ADULTO' : 'Especial';
          Map<String, dynamic>? enviado;
          final producto = {
            'idProducto': 1,
            'nombre': 'Prueba',
            'tipo': medicamento ? 'MEDICAMENTO' : 'PRODUCTO',
            'activo': true,
            'presentacion': 'TABLETA',
            campo: asignado ? valor : null,
          };
          final client = MockClient((request) async {
            if (request.method == 'PATCH') {
              enviado = jsonDecode(request.body) as Map<String, dynamic>;
              return http.Response(jsonEncode(producto), 200);
            }
            return http.Response(jsonEncode([producto]), 200);
          });
          await http.runWithClient(() async {
            await tester.pumpWidget(const MaterialApp(
                home: Scaffold(body: ContenidoCatalogoProducto())));
            await tester.pumpAndSettle();
            await tester.tap(find.byTooltip('Editar'));
            await tester.pumpAndSettle();
            if (cambiar) {
              final selector = find.byWidgetPredicate((widget) =>
                  widget is DropdownButton<String> &&
                  (widget.items?.any((item) =>
                          item.value == (medicamento ? 'ADULTO' : 'General')) ??
                      false));
              tester
                  .widget<DropdownButton<String>>(find.descendant(
                    of: find.byType(Dialog), matching: selector))
                      .onChanged!(
                  asignado ? '' : (medicamento ? 'ADULTO' : 'General'));
              await tester.pump();
            }
            await tester.tap(find.text('Guardar'));
            await tester.pumpAndSettle();
            final datos = medicamento ? enviado!['infoMedicamento'] : enviado!;
            expect(
                datos[campo],
                cambiar
                    ? (asignado ? null : (medicamento ? 'ADULTO' : 'General'))
                    : (asignado ? valor : null));
            expect(tester.takeException(), isNull);
          }, () => client);
        });
      }
    }
  }
}
