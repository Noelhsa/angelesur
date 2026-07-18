import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config/impresora_config.dart';

/// Excepcion controlada para errores relacionados con la impresion.
class TicketServiceException implements Exception {
  const TicketServiceException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Servicio encargado de crear y enviar tickets ESC/POS.
///
/// En esta version imprime un ticket de prueba con un formato
/// mas parecido al ejemplo que mostraste.
class TicketService {
  const TicketService({
    this.ip = ImpresoraConfig.ip,
    this.puerto = ImpresoraConfig.puerto,
    this.tiempoEspera = ImpresoraConfig.tiempoEspera,
  });

  final String ip;
  final int puerto;
  final Duration tiempoEspera;

  /// Genera un ticket de prueba y lo envia a la impresora por Ethernet.
  Future<void> imprimirTicketPrueba() async {
    Socket? socket;

    try {
      socket = await Socket.connect(
        ip,
        puerto,
        timeout: tiempoEspera,
      );

      socket.setOption(SocketOption.tcpNoDelay, true);

      final List<int> ticket = _crearTicketPrueba();

      socket.add(ticket);
      await socket.flush().timeout(tiempoEspera);

      await Future<void>.delayed(
        const Duration(milliseconds: 400),
      );

      await socket.close().timeout(tiempoEspera);
    } on TimeoutException {
      throw TicketServiceException(
        'La impresora no respondio dentro del tiempo esperado '
        'en $ip:$puerto.',
      );
    } on SocketException catch (error) {
      throw TicketServiceException(
        'No fue posible conectar con la impresora '
        '$ip:$puerto. Detalle: ${error.message}',
      );
    } on TicketServiceException {
      rethrow;
    } catch (error) {
      throw TicketServiceException(
        'Ocurrio un error inesperado al imprimir: $error',
      );
    } finally {
      socket?.destroy();
    }
  }

  /// Construye los bytes ESC/POS del ticket de prueba.
  List<int> _crearTicketPrueba() {
    final List<int> bytes = <int>[];

    void agregarComando(List<int> comando) {
      bytes.addAll(comando);
    }

    void agregarTexto(String texto) {
      bytes.addAll(ascii.encode(texto));
    }

    void agregarLinea([String texto = '']) {
      agregarTexto(texto);
      bytes.add(0x0A);
    }

    String derecha(String valor, int ancho) {
      if (valor.length >= ancho) {
        return valor;
      }
      return ' ' * (ancho - valor.length) + valor;
    }

    String izquierda(String valor, int ancho) {
      if (valor.length >= ancho) {
        return valor.substring(0, ancho);
      }
      return valor + (' ' * (ancho - valor.length));
    }

    String centrar(String texto, int ancho) {
      if (texto.length >= ancho) {
        return texto;
      }

      final int espaciosTotales = ancho - texto.length;
      final int espaciosIzquierda = espaciosTotales ~/ 2;
      final int espaciosDerecha = espaciosTotales - espaciosIzquierda;

      return (' ' * espaciosIzquierda) +
          texto +
          (' ' * espaciosDerecha);
    }

    String formatearProducto({
      required String nombre,
      required int cantidad,
      required double importe,
    }) {
      final String nombreAjustado = izquierda(nombre, 24);
      final String cantidadTexto = derecha(cantidad.toString(), 4);
      final String importeTexto = derecha(
        '\$${importe.toStringAsFixed(2)}',
        12,
      );

      return '$nombreAjustado$cantidadTexto$importeTexto';
    }

    String formatearTotal(String etiqueta, double valor) {
      final String importeTexto = '\$${valor.toStringAsFixed(2)}';
      return izquierda(etiqueta, 30) + derecha(importeTexto, 18);
    }

    const int anchoTicket = 48;
    const String separador =
        '------------------------------------------------';

    final DateTime ahora = DateTime.now();
    final String fecha = _formatearFecha(ahora);
    final String hora = _formatearHora(ahora);

    const String cajero = 'TEST';
    const String ticket = 'TEST-5332';

    const double subtotal = 113.00;
    const double descuento = 13.00;
    const double total = 100.00;
    const double efectivo = 200.00;
    const double cambio = 100.00;
    const String metodo = 'efectivo';

    /// Inicializa la impresora
    agregarComando(<int>[0x1B, 0x40]);

    /// Centrado
    agregarComando(<int>[0x1B, 0x61, 0x01]);

    /// Negritas on
    agregarComando(<int>[0x1B, 0x45, 0x01]);

    /// Doble ancho y doble alto
    agregarComando(<int>[0x1D, 0x21, 0x11]);
    agregarLinea('Farmacia Angeles');

    /// Tamano normal
    agregarComando(<int>[0x1D, 0x21, 0x00]);

    /// Negritas off
    agregarComando(<int>[0x1B, 0x45, 0x00]);

    agregarLinea('Farmacia');
    agregarLinea('Prolongacion Antenas # 95');
    agregarLinea();

    /// Alinear a la izquierda
    agregarComando(<int>[0x1B, 0x61, 0x00]);

    agregarLinea('Fecha: $fecha   $hora');
    agregarLinea('Cajero: $cajero');
    agregarLinea('Ticket: $ticket');
    agregarLinea(separador);

    agregarLinea('PRODUCTO                  CANT.     IMPORTE');
    agregarLinea(separador);

    agregarLinea(
      formatearProducto(
        nombre: 'Paracetamol 500 mg',
        cantidad: 1,
        importe: 45.00,
      ),
    );

    agregarLinea(
      formatearProducto(
        nombre: 'Ibuprofeno 400 mg',
        cantidad: 1,
        importe: 68.00,
      ),
    );

    agregarLinea(separador);

    agregarLinea(formatearTotal('Subtotal:', subtotal));
    agregarLinea(formatearTotal('Descuento:', descuento));

    /// Total centrado y en grande
    agregarLinea();
    agregarComando(<int>[0x1B, 0x61, 0x01]);
    agregarComando(<int>[0x1B, 0x45, 0x01]);
    agregarComando(<int>[0x1D, 0x21, 0x11]);
    agregarLinea('TOTAL: \$${total.toStringAsFixed(2)}');

    /// Regresar a tamano normal
    agregarComando(<int>[0x1D, 0x21, 0x00]);
    agregarComando(<int>[0x1B, 0x45, 0x00]);

    agregarLinea();
    agregarComando(<int>[0x1B, 0x61, 0x00]);
    agregarLinea(formatearTotal('Efectivo:', efectivo));
    agregarLinea(formatearTotal('Cambio:', cambio));
    agregarLinea('Metodo: $metodo');

    agregarLinea();
    agregarComando(<int>[0x1B, 0x61, 0x01]);
    agregarLinea(centrar('Gracias por su compra!', anchoTicket));
    agregarLinea(centrar('Vuelva pronto', anchoTicket));

    /// Alimentar 4 lineas
    agregarComando(<int>[0x1B, 0x64, 0x04]);

    /// Corte parcial
    agregarComando(<int>[0x1D, 0x56, 0x01]);

    return bytes;
  }

  String _formatearFecha(DateTime fecha) {
    final String dia = _dosDigitos(fecha.day);
    final String mes = _dosDigitos(fecha.month);
    final String anio = fecha.year.toString();

    return '$dia/$mes/$anio';
  }

  String _formatearHora(DateTime fecha) {
    final String hora = _dosDigitos(fecha.hour);
    final String minuto = _dosDigitos(fecha.minute);
    final String segundo = _dosDigitos(fecha.second);

    return '$hora:$minuto:$segundo';
  }

  String _dosDigitos(int numero) {
    return numero.toString().padLeft(2, '0');
  }
}