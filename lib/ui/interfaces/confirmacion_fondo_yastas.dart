import 'package:flutter/material.dart';
import '../../services/servicios_yastas_api_service.dart';
import '../../utils/config_moneda.dart';
import 'menu_carta_venta_yastas.dart';

double numeroCotizacion(Object? value) => double.tryParse('$value') ?? 0;

/// Cotiza todo el carrito antes de registrar ventas; vuelve a cotizar despues
/// de cada eleccion porque cambia el saldo de las siguientes operaciones.
Future<List<Map<String, dynamic>>?> confirmarFondoYastas(
  BuildContext context,
  ServiciosYastasApiService api,
  List<ServicioYastasCarrito> servicios,
) async {
  if (servicios.isEmpty) return [];
  final elegidos = <int, double>{};
  while (context.mounted) {
    final cotizaciones = await api.cotizarServicios([
      for (var i = 0; i < servicios.length; i++)
        {
          'idTarifa': servicios[i].tarifa.idTarifa,
          'montoServicio': servicios[i].montoServicio,
          if (elegidos.containsKey(i)) 'porcentajeElegido': elegidos[i],
        },
    ]);
    if (!context.mounted) return null;
    final indice =
        cotizaciones.indexWhere((c) => c['requiereSeleccion'] == true);
    if (indice >= 0) {
      final c = cotizaciones[indice];
      final servicio = servicios[indice];
      final propio = numeroCotizacion(c['saldoPropio']);
      final fondo = numeroCotizacion(c['fondoDisponible']);
      final opciones = {
        numeroCotizacion(c['porcentajeNormal']),
        numeroCotizacion(c['porcentajeFondo']),
      };
      final elegido = await showDialog<double>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Esta operación necesita fondo Yastas'),
          content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${servicio.tarifa.nombreServicio}: ${ConfigMoneda.formato(servicio.montoServicio)}'),
                Text(
                    'Saldo propio: ${ConfigMoneda.formato(propio)}\nFondo disponible: ${ConfigMoneda.formato(fondo)}'),
                const SizedBox(height: 12),
                const Text(
                    'Selecciona el porcentaje que indicó Yastas. Se añadirá una observación con el desglose.'),
                for (final tasa in opciones)
                  Builder(builder: (_) {
                    final salida = servicio.montoServicio +
                        servicio.tarifa.comisionYastas -
                        (servicio.montoServicio * tasa).round() / 100;
                    final usoPropio = salida < propio ? salida : propio;
                    final usoFondo = salida - usoPropio;
                    return ListTile(
                      title: Text('$tasa%'),
                      subtitle: Text(
                          'Propio: ${ConfigMoneda.formato(usoPropio)} · Fondo: ${ConfigMoneda.formato(usoFondo)}${usoFondo > fondo ? " (insuficiente)" : ""}'),
                      enabled: usoFondo <= fondo,
                      onTap: () => Navigator.pop(dialogContext, tasa),
                    );
                  }),
              ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'))
          ],
        ),
      );
      if (elegido == null) return null;
      elegidos[indice] = elegido;
      continue;
    }
    final conFondo = cotizaciones
        .where((c) => numeroCotizacion(c['montoFondo']) > 0)
        .toList();
    if (conFondo.isNotEmpty) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Confirmar uso del fondo Yastas'),
          content: SingleChildScrollView(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                for (final c in conFondo)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                        '${c["nombreServicio"]} · ${c["porcentajeAplicado"]}%\nPropio: ${ConfigMoneda.formato(numeroCotizacion(c["montoPropio"]))}\nFondo: ${ConfigMoneda.formato(numeroCotizacion(c["montoFondo"]))}'),
                  ),
                const Text(
                    'El desglose quedará en las observaciones de cada operación.'),
              ])),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Confirmar')),
          ],
        ),
      );
      if (confirmar != true) return null;
    }
    for (var i = 0; i < cotizaciones.length; i++) {
      cotizaciones[i]['porcentajeElegido'] = elegidos[i];
    }
    return cotizaciones;
  }
  return null;
}
