import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:angelesur/services/api_client.dart';
import 'package:angelesur/services/compras_api_service.dart';
import 'package:angelesur/services/ventas_api_service.dart';
import 'package:angelesur/ui/interfaces/menu_carta_devolucion_cliente.dart';
import 'package:angelesur/ui/interfaces/menu_carta_devolucion_proveedor.dart';

void main() {
  for (final proveedor in [false, true]) {
    for (final fallaAnterior in [false, true]) {
      testWidgets(
          'Seleccion mas reciente proveedor=$proveedor error=$fallaAnterior',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(1400, 1600));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final anteriores = Completer<http.Response>();
        final actuales = Completer<http.Response>();
        int? guardado;
        Map<String, dynamic> registro(int id) => {
              'idVenta': id,
              'idCompra': id,
              'idProveedor': 1,
              'folio': 'V$id',
              'folioProveedor': 'C$id',
              'total': 10,
              'detalles': [
                {
                  'idVentaDetalle': id * 10,
                  'idCompraDetalle': id * 10,
                  'idInventario': id,
                  'idProducto': id,
                  'producto': 'Producto $id',
                  'cantidad': 2
                }
              ],
            };
        final cliente = ApiClient(client: MockClient((request) async {
          if (request.url.path.endsWith('/1')) return anteriores.future;
          if (request.url.path.endsWith('/2')) return actuales.future;
          return http.Response(jsonEncode([registro(1), registro(2)]), 200);
        }));
        await tester.pumpWidget(MaterialApp(
            home: Scaffold(
          body: proveedor
              ? MenuCartaDevolucionProveedor(
                  idUsuario: 1,
                  comprasApiService: ComprasApiService(apiClient: cliente),
                  onCerrar: () {},
                  onGuardarDevolucion: (datos) => guardado = datos.idCompra)
              : MenuCartaDevolucionCliente(
                  idUsuario: 1,
                  ventasApiService: VentasApiService(apiClient: cliente),
                  onCerrar: () {},
                  onGuardarDevolucion: (datos) => guardado = datos.idVenta),
        )));
        await tester.pumpAndSettle();
        void seleccionar(int id) {
          tester
              .widget<DropdownButtonFormField<int>>(
                  find.byType(DropdownButtonFormField<int>).first)
              .onChanged!(id);
        }

        seleccionar(1);
        await tester.pump();
        seleccionar(2);
        await tester.pump();
        await tester.tap(find.text('Guardar'));
        expect(guardado, isNull);
        actuales.complete(http.Response(jsonEncode(registro(2)), 200));
        await tester.pumpAndSettle();
        anteriores.complete(http.Response(
          jsonEncode(
              fallaAnterior ? {'detail': 'Error anterior'} : registro(1)),
          fallaAnterior ? 500 : 200,
        ));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Guardar'));
        await tester.pump();
        expect(guardado, 2);
        expect(
            find.textContaining('No se pudo cargar el detalle'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
