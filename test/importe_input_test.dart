import 'package:angelesur/utils/importe_input.dart';
import 'package:angelesur/ui/interfaces/menu_carta_carrito.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Descuento conserva coma decimal al reconstruir carrito',
      (tester) async {
    double descuento = 0;
    await tester.binding.setSurfaceSize(const Size(1400, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: StatefulBuilder(
      builder: (context, setState) => MenuCartaCarrito(
        medicamentos: const [],
        cantidades: const {},
        subtotal: 100,
        descuento: descuento,
        total: 100 - descuento,
        onDescuentoChanged: (valor) => setState(() => descuento = valor),
        onIncrementar: (_) {},
        onDisminuir: (_) {},
        onEliminar: (_) {},
        onPagar: () {},
      ),
    ))));
    final campo = find.byType(TextField).first;
    await tester.enterText(campo, '5,50');
    await tester.pump();
    expect(descuento, 5.5);
    expect(tester.widget<TextField>(campo).controller!.text, '5,50');
    await tester.enterText(campo, '5,500');
    await tester.pump();
    expect(descuento, 5.5);
    await tester.enterText(campo, '');
    await tester.pump();
    expect(descuento, 0);
  });
  test('Importes con punto o coma conservan sus centavos', () {
    expect(leerImporte('20,50'), 20.5);
    expect(leerImporte('20.50'), 20.5);
    expect(leerImporte('0,05'), 0.05);
    expect(leerImporte('1000'), 1000);
  });
  test('Rechaza el cambio completo, sin limpiar ni truncar el monto', () {
    const formatter = ImporteInputFormatter();
    const anterior = TextEditingValue(text: '20');
    for (final texto in [
      'abc',
      '20a',
      '-2',
      '+2',
      '1,000',
      '1.000',
      '1,000.50',
      '2.345',
      '2..5',
      '2,5.0',
      '\$20',
      '2 0',
      '1e2',
      'NaN',
      'Infinity',
      '.',
      ','
    ]) {
      expect(leerImporte(texto), isNull, reason: texto);
      expect(
          formatter.formatEditUpdate(anterior, TextEditingValue(text: texto)),
          anterior);
    }
    for (final texto in ['', '2', '20,', '20.', '20,50', '20.50']) {
      final nuevo = TextEditingValue(text: texto);
      expect(formatter.formatEditUpdate(anterior, nuevo), nuevo);
    }
  });
  testWidgets('Cobro rechaza texto invalido y envia 20,50 como 20.50',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    DatosPagoVenta? resultado;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
      builder: (context) => TextButton(
          onPressed: () async {
            resultado =
                await mostrarDialogoPagoVenta(context: context, total: 20);
          },
          child: const Text('Abrir')),
    ))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    final campo = find.byType(TextField).first;
    await tester.enterText(campo, '20,50');
    await tester.pump();
    for (final invalido in ['20abc', '1,000', '-20', '20.555']) {
      await tester.enterText(campo, invalido);
      await tester.pump();
      expect(tester.widget<TextField>(campo).controller!.text, '20,50');
    }
    await tester.tap(find.text('Confirmar venta'));
    await tester.pumpAndSettle();
    expect(resultado!.montoRecibido, 20.5);
  });
}
