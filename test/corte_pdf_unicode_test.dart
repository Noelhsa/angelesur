import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:angelesur/services/corte_pdf_service.dart';
import 'package:angelesur/services/cortes_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('PDF con fuentes incluidas y caracteres espanoles', () async {
    final corte = CorteDetalle.fromJson({
      'idCorte': 1,
      'estado': 'CERRADO',
      'usuarioAbreNombre': 'José Muñoz',
      'usuarioCierraNombre': 'María Peña',
      'observacionesCorte': 'Vualá: á é í ó ú ñ ü Á É Í Ó Ú Ñ Ü ¿Sí? ¡Sí!',
    });
    final bytes = await const CortePdfService().generarPdf(corte);
    expect(bytes.take(5), [37, 80, 68, 70, 45]);
    final archivo = File('build/qa/corte_unicode.pdf');
    await archivo.parent.create(recursive: true);
    await archivo.writeAsBytes(bytes);
  });
}
