import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../utils/config_moneda.dart';
import 'caja_api_service.dart';
import 'cortes_api_service.dart';

class CortePdfService {
  const CortePdfService();

  Future<String?> exportarCorte(CorteDetalle corte) async {
    final bytes = await generarPdf(corte);
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar corte #${corte.idCorte}',
      fileName: 'corte_${corte.idCorte}_${_fechaArchivo(DateTime.now())}.pdf',
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      bytes: bytes,
      lockParentWindow: true,
    );

    if (path == null) {
      return null;
    }

    final outputPath = _asegurarExtensionPdf(path);
    await File(outputPath).writeAsBytes(bytes, flush: true);

    return outputPath;
  }

  Future<Uint8List> generarPdf(CorteDetalle corte) async {
    final document = pw.Document(
      title: 'Corte #${corte.idCorte}',
      author: 'Angelesur',
      creator: 'Angelesur',
    );

    document.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.letter,
          margin: pw.EdgeInsets.all(28),
        ),
        header: (context) => _encabezado(corte),
        footer: (context) => _piePagina(context),
        build: (context) => [
          pw.SizedBox(height: 14),
          _seccionDatosGenerales(corte),
          pw.SizedBox(height: 12),
          _seccionSaldos(corte),
          pw.SizedBox(height: 12),
          _seccionMovimientos(corte),
          if (corte.observacionesCorte.trim().isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _seccionObservaciones(corte),
          ],
          pw.SizedBox(height: 16),
          ..._seccionTransacciones(corte.movimientos),
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _encabezado(CorteDetalle corte) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _colorFondo,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: 34,
            height: 34,
            decoration: pw.BoxDecoration(
              color: _colorVerde,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Center(
              child: pw.Text(
                r'$',
                style: pw.TextStyle(
                  color: _colorFondo,
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Registro de corte #${corte.idCorte}',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Farmacia Angelesur | ${_formatoFechaHora(DateTime.now())}',
                  style: const pw.TextStyle(
                    color: PdfColor.fromInt(0xFFD9E6D3),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          _estado(corte.estado),
        ],
      ),
    );
  }

  pw.Widget _piePagina(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(
            color: PdfColor.fromInt(0xFFD9E6D3),
            width: 0.8,
          ),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              'Documento generado desde Angelesur',
              style: const pw.TextStyle(
                color: _colorTextoSecundario,
                fontSize: 8,
              ),
            ),
          ),
          pw.Text(
            'Pagina ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(
              color: _colorTextoSecundario,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _seccionDatosGenerales(CorteDetalle corte) {
    return _panel(
      titulo: 'Datos generales',
      child: pw.Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _dato('Apertura', _formatoFechaHora(corte.fechaApertura)),
          _dato('Cierre', _formatoFechaHora(corte.fechaCierre)),
          _dato(
            'Abre',
            _nombreUsuarioCorte(corte.usuarioAbreNombre, corte.usuarioAbre),
          ),
          _dato(
            'Cierra',
            _nombreUsuarioCorte(corte.usuarioCierraNombre, corte.usuarioCierra),
          ),
        ],
      ),
    );
  }

  pw.Widget _seccionSaldos(CorteDetalle corte) {
    return _panel(
      titulo: 'Resumen del corte',
      child: pw.Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _dato('Efectivo inicial', _moneda(corte.efectivoInicial)),
          _dato(
            'Efectivo final',
            _moneda(
              corte.estado == 'CERRADO'
                  ? corte.efectivoContado
                  : corte.efectivoEsperado,
            ),
          ),
          _dato('Electronico inicial', _moneda(corte.electronicoInicial)),
          _dato(
            'Electronico final',
            _moneda(
              corte.estado == 'CERRADO'
                  ? corte.electronicoContado
                  : corte.electronicoEsperado,
            ),
          ),
          _dato('Esperado efectivo', _moneda(corte.efectivoEsperado)),
          _dato('Esperado electronico', _moneda(corte.electronicoEsperado)),
          _dato(
            'Diferencia efectivo',
            _moneda(corte.diferenciaEfectivo),
            destacado: corte.diferenciaEfectivo != 0,
          ),
          _dato(
            'Diferencia electronico',
            _moneda(corte.diferenciaElectronico),
            destacado: corte.diferenciaElectronico != 0,
          ),
        ],
      ),
    );
  }

  pw.Widget _seccionMovimientos(CorteDetalle corte) {
    return _panel(
      titulo: 'Movimientos',
      child: pw.Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _dato(
            'Entradas efectivo',
            _moneda(corte.totalesMovimientos.entradasEfectivo),
          ),
          _dato(
            'Salidas efectivo',
            _moneda(corte.totalesMovimientos.salidasEfectivo),
          ),
          _dato(
            'Entradas electronico',
            _moneda(corte.totalesMovimientos.entradasElectronico),
          ),
          _dato(
            'Salidas electronico',
            _moneda(corte.totalesMovimientos.salidasElectronico),
          ),
          _dato(
            'Total transacciones',
            corte.totalesMovimientos.totalMovimientos.toString(),
          ),
        ],
      ),
    );
  }

  pw.Widget _seccionObservaciones(CorteDetalle corte) {
    return _panel(
      titulo: 'Observaciones',
      child: pw.Text(
        corte.observacionesCorte.trim(),
        style: const pw.TextStyle(
          color: _colorTextoSecundario,
          fontSize: 9,
        ),
      ),
    );
  }

  List<pw.Widget> _seccionTransacciones(List<MovimientoCaja> movimientos) {
    if (movimientos.isEmpty) {
      return [
        _panel(
          titulo: 'Transacciones',
          child: pw.Text(
            'Este corte no tiene transacciones registradas.',
            style: const pw.TextStyle(
              color: _colorTextoSecundario,
              fontSize: 9,
            ),
          ),
        ),
      ];
    }

    return [
      _tituloTransacciones(movimientos.length),
      pw.Table(
        border: pw.TableBorder.all(
          color: const PdfColor.fromInt(0xFFD9E6D3),
          width: 0.5,
        ),
        columnWidths: const {
          0: pw.FlexColumnWidth(1.1),
          1: pw.FlexColumnWidth(0.9),
          2: pw.FlexColumnWidth(0.9),
          3: pw.FlexColumnWidth(1.4),
          4: pw.FlexColumnWidth(1.2),
          5: pw.FlexColumnWidth(1.2),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF1F9EA),
            ),
            children: [
              _celdaHeader('Fecha'),
              _celdaHeader('Medio'),
              _celdaHeader('Tipo'),
              _celdaHeader('Concepto'),
              _celdaHeader('Usuario'),
              _celdaHeader('Monto', alignRight: true),
            ],
          ),
          ...movimientos.map(
            (movimiento) => pw.TableRow(
              children: [
                _celda(_formatoFechaHora(movimiento.fecha)),
                _celda(_etiqueta(movimiento.medio)),
                _celda(_etiqueta(movimiento.tipo)),
                _celda(_conceptoMovimiento(movimiento)),
                _celda(
                  movimiento.usuario.isEmpty
                      ? 'Usuario #${movimiento.idUsuario}'
                      : movimiento.usuario,
                ),
                _celda(
                  '${movimiento.esEntrada ? '+' : '-'}${_moneda(movimiento.monto)}',
                  alignRight: true,
                  color: movimiento.esEntrada
                      ? _colorVerdeOscuro
                      : const PdfColor.fromInt(0xFFE02020),
                ),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  pw.Widget _tituloTransacciones(int total) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 9),
      decoration: const pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border(
          top: pw.BorderSide(
            color: PdfColor.fromInt(0xFFD9E6D3),
            width: 0.8,
          ),
          left: pw.BorderSide(
            color: PdfColor.fromInt(0xFFD9E6D3),
            width: 0.8,
          ),
          right: pw.BorderSide(
            color: PdfColor.fromInt(0xFFD9E6D3),
            width: 0.8,
          ),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              'Transacciones',
              style: pw.TextStyle(
                color: _colorTexto,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Text(
            '$total movimiento(s)',
            style: const pw.TextStyle(
              color: _colorTextoSecundario,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _panel({
    required String titulo,
    required pw.Widget child,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(
          color: const PdfColor.fromInt(0xFFD9E6D3),
          width: 0.8,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            titulo,
            style: pw.TextStyle(
              color: _colorTexto,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  pw.Widget _dato(
    String label,
    String value, {
    bool destacado = false,
  }) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF7F9F5),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(
              color: _colorTextoSecundario,
              fontSize: 8,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            maxLines: 2,
            style: pw.TextStyle(
              color:
                  destacado ? const PdfColor.fromInt(0xFFE02020) : _colorTexto,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _estado(String estado) {
    final cerrado = estado.toUpperCase() == 'CERRADO';
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: cerrado ? _colorVerde : const PdfColor.fromInt(0xFF0B63CE),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Text(
        _etiqueta(estado),
        style: pw.TextStyle(
          color: cerrado ? _colorFondo : PdfColors.white,
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _celdaHeader(String value, {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      child: pw.Text(
        value,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          color: _colorTexto,
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _celda(
    String value, {
    bool alignRight = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        value,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          color: color ?? _colorTextoSecundario,
          fontSize: 7.4,
        ),
      ),
    );
  }

  String _conceptoMovimiento(MovimientoCaja movimiento) {
    final observaciones = movimiento.observaciones.trim();
    if (observaciones.isEmpty) {
      return _etiqueta(movimiento.concepto);
    }
    return '${_etiqueta(movimiento.concepto)} | $observaciones';
  }

  String _moneda(double value) {
    return ConfigMoneda.formato(value);
  }

  String _nombreUsuarioCorte(String nombre, int? idUsuario) {
    if (nombre.trim().isNotEmpty) {
      return nombre;
    }
    if (idUsuario != null) {
      return 'Usuario #$idUsuario';
    }
    return 'Sin usuario';
  }

  String _formatoFechaHora(DateTime? fecha) {
    if (fecha == null) return 'Sin fecha';
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year} $hora:$minuto';
  }

  String _fechaArchivo(DateTime fecha) {
    final mes = fecha.month.toString().padLeft(2, '0');
    final dia = fecha.day.toString().padLeft(2, '0');
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '${fecha.year}$mes${dia}_$hora$minuto';
  }

  String _asegurarExtensionPdf(String path) {
    if (path.toLowerCase().endsWith('.pdf')) {
      return path;
    }
    return '$path.pdf';
  }

  String _etiqueta(String value) {
    final text = value.trim().replaceAll('_', ' ').toLowerCase();
    if (text.isEmpty) return '-';
    return text
        .split(' ')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

const PdfColor _colorFondo = PdfColor.fromInt(0xFF181A20);
const PdfColor _colorVerde = PdfColor.fromInt(0xFF58D000);
const PdfColor _colorVerdeOscuro = PdfColor.fromInt(0xFF397800);
const PdfColor _colorTexto = PdfColor.fromInt(0xFF1F2933);
const PdfColor _colorTextoSecundario = PdfColor.fromInt(0xFF667085);
