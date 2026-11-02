import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:angelesur/ui/interfaces/menu_carta_yastas.dart';

void main() {
  testWidgets('Selector guarda descuento sin comisiones y conserva llenado normal',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    DatosMenuTarifaYastas? resultado;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: MenuCartaYastas(
        onCerrar: () {},
        onGuardarTarifa: (datos) => resultado = datos,
      )),
    ));
    await tester.enterText(find.byType(TextField).at(0), 'Recarga');
    await tester.enterText(find.byType(TextField).at(1), '10');
    await tester.enterText(find.byType(TextField).at(2), '2');
    await tester.tap(find.text('Con descuento'));
    await tester.pump();
    expect(find.text('Comisión cliente'), findsNothing);
    final porcentaje = find.byKey(const ValueKey('porcentajeDescuento'));
    expect(tester.widget<TextField>(porcentaje).controller!.text, '5');
    await tester.tap(find.text('Guardar Tarifa'));
    expect(resultado!.porcentajeDescuentoElectronico, 5);
    expect(resultado!.comisionCliente, 0);
    expect(resultado!.comisionYastas, 0);
    expect(resultado!.regaliaYastas, 0);
    expect(resultado!.gananciaFarmacia, 0);
    resultado = null;
    await tester.enterText(porcentaje, '0');
    await tester.tap(find.text('Guardar Tarifa'));
    await tester.pump();
    expect(resultado, isNull);
    await tester.tap(find.text('Normal'));
    await tester.pump();
    expect(porcentaje, findsNothing);
    await tester.tap(find.text('Guardar Tarifa'));
    expect(resultado!.porcentajeDescuentoElectronico, 0);
    expect(resultado!.comisionCliente, 10);
    expect(resultado!.comisionYastas, 2);
    expect(resultado!.gananciaFarmacia, 8);
  });

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
