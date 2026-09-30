import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:angelesur/ui/interfaces/menu_carta_yastas.dart';

void main() {
  testWidgets('Alta calcula ganancia y bloquea reparto excedido',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    DatosMenuTarifaYastas? resultado;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: MenuCartaYastas(
      onCerrar: () {},
      onGuardarTarifa: (datos) => resultado = datos,
    ))));
    final campos = find.byType(TextField);
    await tester.enterText(campos.at(0), 'Prueba');
    await tester.enterText(campos.at(1), '10');
    await tester.enterText(campos.at(2), '2');
    await tester.enterText(campos.at(3), '1');
    await tester.pump();
    expect(tester.widget<TextField>(campos.at(4)).readOnly, isTrue);
    expect(tester.widget<TextField>(campos.at(4)).controller!.text, '7.00');
    await tester.tap(find.text('Guardar Tarifa'));
    await tester.pump();
    expect(resultado!.gananciaFarmacia, 7);
    resultado = null;
    await tester.enterText(campos.at(2), '11');
    await tester.tap(find.text('Guardar Tarifa'));
    await tester.pump();
    expect(resultado, isNull);
  });
}
