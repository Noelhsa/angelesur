import 'dart:async';
import 'dart:io';

import '../config/impresora_config.dart';

/// Excepción controlada para errores relacionados con la impresión.
class TicketServiceException implements Exception {
  const TicketServiceException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Representa un producto que se imprimirá en el ticket.
class TicketProducto {
  final String nombre;
  final int cantidad;
  final double precioUnitario;
  final double descuento;
  final double subtotal;

  const TicketProducto({
    required this.nombre,
    required this.cantidad,
    required this.precioUnitario,
    required this.descuento,
    required this.subtotal,
  });
}

/// Contiene toda la información de una venta real que será impresa.
class TicketVenta {
  final String folio;
  final DateTime fecha;
  final String cajero;
  final List<TicketProducto> productos;
  final double subtotal;
  final double descuento;
  final double total;
  final double montoRecibido;
  final double cambio;
  final String metodoPago;
  final String? referencia;

  const TicketVenta({
    required this.folio,
    required this.fecha,
    required this.cajero,
    required this.productos,
    required this.subtotal,
    required this.descuento,
    required this.total,
    required this.montoRecibido,
    required this.cambio,
    required this.metodoPago,
    this.referencia,
  });
}

/// Servicio encargado de crear y enviar tickets ESC/POS por Ethernet.
class TicketService {
  const TicketService({
    this.ip = ImpresoraConfig.ip,
    this.puerto = ImpresoraConfig.puerto,
    this.tiempoEspera = ImpresoraConfig.tiempoEspera,
  });

  static const int _anchoTicket = 48;

  static const String _separador =
      '------------------------------------------------';

  final String ip;
  final int puerto;
  final Duration tiempoEspera;

  /// Genera y envía el ticket correspondiente a una venta registrada.
  Future<void> imprimirTicketVenta(TicketVenta venta) async {
    final bytes = _crearTicketVenta(venta);

    await _enviarAImpresora(bytes);
  }

  /// Conserva una prueba manual para comprobar la impresora.
  ///
  /// La aplicación de ventas no utiliza este método.
  Future<void> imprimirTicketPrueba() async {
    final ahora = DateTime.now();

    await imprimirTicketVenta(
      TicketVenta(
        folio: 'TEST-5332',
        fecha: ahora,
        cajero: 'TEST',
        productos: const [
          TicketProducto(
            nombre: 'Paracetamol 500 mg',
            cantidad: 1,
            precioUnitario: 45,
            descuento: 0,
            subtotal: 45,
          ),
          TicketProducto(
            nombre: 'Ibuprofeno 400 mg',
            cantidad: 1,
            precioUnitario: 68,
            descuento: 0,
            subtotal: 68,
          ),
        ],
        subtotal: 113,
        descuento: 13,
        total: 100,
        montoRecibido: 200,
        cambio: 100,
        metodoPago: 'EFECTIVO',
      ),
    );
  }

  /// Abre la conexión TCP y envía los comandos ESC/POS.
  Future<void> _enviarAImpresora(List<int> bytes) async {
    Socket? socket;

    try {
      socket = await Socket.connect(
        ip,
        puerto,
        timeout: tiempoEspera,
      );

      socket.setOption(
        SocketOption.tcpNoDelay,
        true,
      );

      socket.add(bytes);

      await socket.flush().timeout(
            tiempoEspera,
          );

      /*
       * Se da un pequeño tiempo a la impresora para procesar
       * todos los comandos antes de cerrar la conexión.
       */
      await Future<void>.delayed(
        const Duration(milliseconds: 400),
      );

      await socket.close().timeout(
            tiempoEspera,
          );
    } on TimeoutException {
      throw TicketServiceException(
        'La impresora no respondió dentro del tiempo esperado '
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
        'Ocurrió un error inesperado al imprimir: $error',
      );
    } finally {
      socket?.destroy();
    }
  }

  /// Construye todos los bytes ESC/POS del ticket.
  List<int> _crearTicketVenta(TicketVenta venta) {
    final bytes = <int>[];

    void comando(List<int> valores) {
      bytes.addAll(valores);
    }

    void linea([String texto = '']) {
      bytes.addAll(
        _codificarTexto(texto),
      );

      bytes.add(0x0A);
    }

    final fecha = _formatearFecha(
      venta.fecha,
    );

    final hora = _formatearHora(
      venta.fecha,
    );

    final metodo = _formatearMetodoPago(
      venta.metodoPago,
    );

    final referencia = _limpiarOpcional(
      venta.referencia,
    );

    final esEfectivo =
        venta.metodoPago.trim().toUpperCase() ==
            'EFECTIVO';

    /*
     * Inicializar la impresora.
     */
    comando(
      <int>[0x1B, 0x40],
    );

    /*
     * Encabezado centrado.
     */
    comando(
      <int>[0x1B, 0x61, 0x01],
    );

    /*
     * Negritas activadas.
     */
    comando(
      <int>[0x1B, 0x45, 0x01],
    );

    /*
     * Doble ancho y doble alto.
     */
    comando(
      <int>[0x1D, 0x21, 0x11],
    );

    linea(
      'Farmacia Angeles',
    );

    /*
     * Regresar al tamaño normal.
     */
    comando(
      <int>[0x1D, 0x21, 0x00],
    );

    /*
     * Desactivar negritas.
     */
    comando(
      <int>[0x1B, 0x45, 0x00],
    );

    linea('Farmacia');

    linea(
      'Prolongacion Antenas # 95',
    );

    linea();

    /*
     * Información general alineada a la izquierda.
     */
    comando(
      <int>[0x1B, 0x61, 0x00],
    );

    linea(
      _limitarTexto(
        'Fecha: $fecha   $hora',
        _anchoTicket,
      ),
    );

    linea(
      _limitarTexto(
        'Cajero: ${venta.cajero}',
        _anchoTicket,
      ),
    );

    linea(
      _limitarTexto(
        'Ticket: ${venta.folio}',
        _anchoTicket,
      ),
    );

    linea(_separador);

    /*
     * Encabezados de los productos.
     */
    linea(
      '${_izquierda('PRODUCTO', 28)}'
      '${_derecha('CANT.', 6)}'
      '${_derecha('IMPORTE', 14)}',
    );

    linea(_separador);

    /*
     * Productos reales registrados en la venta.
     */
    if (venta.productos.isEmpty) {
      linea(
        'Sin productos para mostrar',
      );
    } else {
      for (final producto in venta.productos) {
        linea(
          _formatearProducto(producto),
        );
      }
    }

    linea(_separador);

    linea(
      _formatearTotal(
        'Subtotal:',
        venta.subtotal,
      ),
    );

    linea(
      _formatearTotal(
        'Descuento:',
        venta.descuento,
      ),
    );

    /*
     * Total centrado, grande y en negritas.
     */
    linea();

    comando(
      <int>[0x1B, 0x61, 0x01],
    );

    comando(
      <int>[0x1B, 0x45, 0x01],
    );

    comando(
      <int>[0x1D, 0x21, 0x11],
    );

    linea(
      'TOTAL: \$${venta.total.toStringAsFixed(2)}',
    );

    /*
     * Regresar al tamaño normal.
     */
    comando(
      <int>[0x1D, 0x21, 0x00],
    );

    comando(
      <int>[0x1B, 0x45, 0x00],
    );

    linea();

    /*
     * Datos del pago.
     */
    comando(
      <int>[0x1B, 0x61, 0x00],
    );

    linea(
      _formatearTotal(
        esEfectivo
            ? 'Efectivo:'
            : 'Monto pagado:',
        venta.montoRecibido,
      ),
    );

    linea(
      _formatearTotal(
        'Cambio:',
        venta.cambio,
      ),
    );

    linea(
      _limitarTexto(
        'Metodo: $metodo',
        _anchoTicket,
      ),
    );

    /*
     * La referencia solamente se imprime cuando existe.
     */
    if (referencia != null) {
      linea(
        _limitarTexto(
          'Referencia: $referencia',
          _anchoTicket,
        ),
      );
    }

    linea();

    /*
     * Mensaje final centrado.
     */
    comando(
      <int>[0x1B, 0x61, 0x01],
    );

    linea(
      _centrar(
        'Gracias por su compra!',
        _anchoTicket,
      ),
    );

    linea(
      _centrar(
        'Vuelva pronto',
        _anchoTicket,
      ),
    );

    /*
     * Alimentar cuatro líneas de papel.
     */
    comando(
      <int>[0x1B, 0x64, 0x04],
    );

    /*
     * Corte parcial.
     */
    comando(
      <int>[0x1D, 0x56, 0x01],
    );

    return bytes;
  }

  /// Formatea una fila de producto en 48 caracteres.
  String _formatearProducto(
    TicketProducto producto,
  ) {
    final nombre = _izquierda(
      producto.nombre,
      28,
    );

    final cantidad = _derecha(
      producto.cantidad.toString(),
      6,
    );

    final importe = _derecha(
      '\$${producto.subtotal.toStringAsFixed(2)}',
      14,
    );

    return '$nombre$cantidad$importe';
  }

  /// Formatea subtotal, descuento, efectivo y cambio.
  String _formatearTotal(
    String etiqueta,
    double valor,
  ) {
    final importe =
        '\$${valor.toStringAsFixed(2)}';

    return '${_izquierda(etiqueta, 30)}'
        '${_derecha(importe, 18)}';
  }

  /// Convierte el texto a caracteres compatibles con ASCII.
  List<int> _codificarTexto(String texto) {
    final normalizado = _convertirAscii(
      texto,
    );

    final bytes = <int>[];

    for (final codigo in normalizado.runes) {
      bytes.add(
        codigo <= 0x7F
            ? codigo
            : 0x3F,
      );
    }

    return bytes;
  }

  String _izquierda(
    String valor,
    int ancho,
  ) {
    final texto = _limitarTexto(
      valor,
      ancho,
    );

    if (texto.length >= ancho) {
      return texto;
    }

    return texto +
        _espacios(
          ancho - texto.length,
        );
  }

  String _derecha(
    String valor,
    int ancho,
  ) {
    final texto = _limitarTexto(
      valor,
      ancho,
    );

    if (texto.length >= ancho) {
      return texto;
    }

    return _espacios(
          ancho - texto.length,
        ) +
        texto;
  }

  String _centrar(
    String valor,
    int ancho,
  ) {
    final texto = _limitarTexto(
      valor,
      ancho,
    );

    if (texto.length >= ancho) {
      return texto;
    }

    final espaciosTotales =
        ancho - texto.length;

    final espaciosIzquierda =
        espaciosTotales ~/ 2;

    final espaciosDerecha =
        espaciosTotales -
            espaciosIzquierda;

    return '${_espacios(espaciosIzquierda)}'
        '$texto'
        '${_espacios(espaciosDerecha)}';
  }

  String _limitarTexto(
    String valor,
    int ancho,
  ) {
    final texto = _convertirAscii(
      valor,
    );

    if (texto.length <= ancho) {
      return texto;
    }

    return texto.substring(
      0,
      ancho,
    );
  }

  String _espacios(int cantidad) {
    if (cantidad <= 0) {
      return '';
    }

    return List<String>.filled(
      cantidad,
      ' ',
    ).join();
  }

  String _formatearFecha(DateTime fecha) {
    final dia = _dosDigitos(
      fecha.day,
    );

    final mes = _dosDigitos(
      fecha.month,
    );

    final anio = fecha.year.toString();

    return '$dia/$mes/$anio';
  }

  String _formatearHora(DateTime fecha) {
    final hora = _dosDigitos(
      fecha.hour,
    );

    final minuto = _dosDigitos(
      fecha.minute,
    );

    final segundo = _dosDigitos(
      fecha.second,
    );

    return '$hora:$minuto:$segundo';
  }

  String _formatearMetodoPago(String medio) {
    switch (medio.trim().toUpperCase()) {
      case 'EFECTIVO':
        return 'Efectivo';

      case 'TARJETA':
        return 'Tarjeta';

      case 'TRANSFERENCIA':
        return 'Transferencia';

      case 'ELECTRONICO':
        return 'Electronico';

      case 'OTRO':
        return 'Otro';

      default:
        final valor = medio.trim();

        return valor.isEmpty
            ? 'Sin especificar'
            : valor;
    }
  }

  String? _limpiarOpcional(String? valor) {
    final texto = valor?.trim() ?? '';

    return texto.isEmpty
        ? null
        : texto;
  }

  String _convertirAscii(String texto) {
    return texto
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('Á', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ú', 'U')
        .replaceAll('ñ', 'n')
        .replaceAll('Ñ', 'N')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'U')
        .replaceAll('¿', '')
        .replaceAll('¡', '');
  }

  String _dosDigitos(int numero) {
    return numero.toString().padLeft(
          2,
          '0',
        );
  }
}