import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:angelesur/services/cortes_api_service.dart';
import 'package:angelesur/services/servicios_yastas_api_service.dart';
import 'package:angelesur/ui/interfaces/confirmacion_fondo_yastas.dart';
import 'package:angelesur/ui/interfaces/menu_carta_venta_yastas.dart';

class ApiCotizacionPrueba extends ServiciosYastasApiService {
  final solicitudes = <List<Map<String, dynamic>>>[];
  @override
  Future<List<Map<String, dynamic>>> cotizarServicios(
      List<Map<String, dynamic>> servicios) async {
    solicitudes.add(servicios);
    final elegido = servicios.single['porcentajeElegido'] as double?;
    final salida = elegido == 3.5 ? 48.25 : 47.50;
    return [
      {
        'idCorte': 1,
        'nombreServicio': 'Recarga',
        'montoServicio': 50,
        'saldoPropio': 20,
        'fondoDisponible': 100,
        'porcentajeNormal': 5,
        'porcentajeFondo': 3.5,
        'porcentajeAplicado': elegido ?? 5,
        'requiereSeleccion': elegido == null,
        'salidaElectronica': salida,
        'montoPropio': 20,
        'montoFondo': salida - 20,
      }
    ];
  }
}

void main() {
  test('El cero propio se conserva y el fondo queda separado', () {
    final corte = CorteResumen.fromJson({
      'electronicoInicial': 20,
      'electronicoEsperado': 0,
      'fondoYastasInicial': 100,
      'fondoYastasDisponible': '71.75',
      'porcentajeDescuentoFondo': '3.5',
    });
    expect(corte.electronicoEsperado, 0);
    expect(corte.fondoYastasInicial, 100);
    expect(corte.fondoYastasDisponible, 71.75);
  });

  for (final cancelar in [false, true]) {
    testWidgets(
        cancelar
            ? 'Cancelar mezcla no confirma la operacion'
            : 'Mezcla exige elegir y confirmar porcentaje', (tester) async {
      final api = ApiCotizacionPrueba();
      List<Map<String, dynamic>>? resultado;
      var termino = false;
      await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: Builder(builder: (context) {
        return TextButton(
            onPressed: () async {
              resultado = await confirmarFondoYastas(context, api, [
                ServicioYastasCarrito(
                  idCarrito: 1,
                  tarifa: TarifaServicioYastas.fromJson({
                    'idTarifa': 1,
                    'nombreServicio': 'Recarga',
                    'porcentajeDescuentoElectronico': 5
                  }),
                  montoServicio: 50,
                  referenciaOperacion: null,
                  observaciones: null,
                )
              ]);
              termino = true;
            },
            child: const Text('Preparar'));
      }))));
      await tester.tap(find.text('Preparar'));
      await tester.pumpAndSettle();
      expect(find.text('Esta operación necesita fondo Yastas'), findsOneWidget);
      expect(termino, isFalse);
      if (cancelar) {
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
        expect(resultado, isNull);
        expect(api.solicitudes, hasLength(1));
      } else {
        await tester.tap(find.text('3.5%'));
        await tester.pumpAndSettle();
        expect(termino, isFalse);
        expect(find.text('Confirmar uso del fondo Yastas'), findsOneWidget);
        await tester.tap(find.text('Confirmar'));
        await tester.pumpAndSettle();
        expect(resultado!.single['porcentajeElegido'], 3.5);
        expect(resultado!.single['montoFondo'], 28.25);
        expect(api.solicitudes.last.single['porcentajeElegido'], 3.5);
      }
      expect(termino, isTrue);
    });
  }
}
