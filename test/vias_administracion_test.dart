import 'package:angelesur/models/vias_administracion.dart';
import 'package:angelesur/ui/interfaces/menu_carta_catalogo_producto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Medicamento muestra vias reales separadas de presentacion',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: MenuCartaCatalogoProducto(
      onCerrar: () {},
      onGuardarProducto: (_) {},
    ))));
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Medicamento').last);
    await tester.pumpAndSettle();
    final campos = tester.widgetList<DropdownButton<String>>(
        find.byType(DropdownButton<String>));
    final via = campos.singleWhere(
        (campo) => campo.items!.any((item) => item.value == 'ORAL'));
    expect(via.items!.map((item) => item.value), viasAdministracion.keys);
    expect(via.value, isNull);
    expect(via.items!.any((item) => item.value == 'TABLETA'), isFalse);
    expect(etiquetaViaAdministracion('OTICA'), '\u00d3tica');
    expect(tester.takeException(), isNull);
  });
}
