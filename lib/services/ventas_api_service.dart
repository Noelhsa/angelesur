import '../models/medicamento.dart';
import 'api_client.dart';

class VentaRegistrada {
  final int idVenta;
  final String folio;
  final double total;
  final double cambio;

  const VentaRegistrada({
    required this.idVenta,
    required this.folio,
    required this.total,
    required this.cambio,
  });

  factory VentaRegistrada.fromJson(Map<String, dynamic> map) {
    return VentaRegistrada(
      idVenta: _asInt(map['idVenta']),
      folio: map['folio']?.toString() ?? '',
      total: _asDouble(map['total']),
      cambio: _asDouble(map['cambio']),
    );
  }

  static int _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _asDouble(Object? value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class VentaResumen {
  final int idVenta;
  final String folio;
  final String usuario;
  final DateTime? fecha;
  final double total;
  final String estatus;

  const VentaResumen({
    required this.idVenta,
    required this.folio,
    required this.usuario,
    required this.fecha,
    required this.total,
    required this.estatus,
  });

  factory VentaResumen.fromJson(Map<String, dynamic> map) {
    return VentaResumen(
      idVenta: VentaRegistrada._asInt(map['idVenta']),
      folio: map['folio']?.toString() ?? '',
      usuario: map['usuario']?.toString() ?? '',
      fecha: DateTime.tryParse(map['fecha']?.toString() ?? ''),
      total: VentaRegistrada._asDouble(map['total']),
      estatus: map['estatus']?.toString() ?? '',
    );
  }
}

class VentaDetalleCompleta {
  final int idVenta;
  final String folio;
  final String usuario;
  final DateTime? fecha;
  final double subtotal;
  final double descuento;
  final double total;
  final double montoRecibido;
  final double cambio;
  final String estatus;
  final String? observaciones;
  final List<VentaProductoDetalle> detalles;
  final List<VentaPagoDetalle> pagos;

  const VentaDetalleCompleta({
    required this.idVenta,
    required this.folio,
    required this.usuario,
    required this.fecha,
    required this.subtotal,
    required this.descuento,
    required this.total,
    required this.montoRecibido,
    required this.cambio,
    required this.estatus,
    required this.observaciones,
    required this.detalles,
    required this.pagos,
  });

  factory VentaDetalleCompleta.fromJson(Map<String, dynamic> map) {
    final detalles = (map['detalles'] as List<dynamic>? ?? [])
        .map((item) =>
            VentaProductoDetalle.fromJson(item as Map<String, dynamic>))
        .toList();
    final pagos = (map['pagos'] as List<dynamic>? ?? [])
        .map((item) => VentaPagoDetalle.fromJson(item as Map<String, dynamic>))
        .toList();

    return VentaDetalleCompleta(
      idVenta: VentaRegistrada._asInt(map['idVenta']),
      folio: map['folio']?.toString() ?? '',
      usuario: map['usuario']?.toString() ?? '',
      fecha: DateTime.tryParse(map['fecha']?.toString() ?? ''),
      subtotal: VentaRegistrada._asDouble(map['subtotal']),
      descuento: VentaRegistrada._asDouble(map['descuento']),
      total: VentaRegistrada._asDouble(map['total']),
      montoRecibido: VentaRegistrada._asDouble(map['montoRecibido']),
      cambio: VentaRegistrada._asDouble(map['cambio']),
      estatus: map['estatus']?.toString() ?? '',
      observaciones: map['observaciones']?.toString(),
      detalles: detalles,
      pagos: pagos,
    );
  }
}

class VentaProductoDetalle {
  final int idVentaDetalle;
  final int idInventario;
  final String producto;
  final String codigoLote;
  final DateTime? fechaCaducidad;
  final int cantidad;
  final double precioUnitario;
  final double descuento;
  final double subtotal;

  const VentaProductoDetalle({
    required this.idVentaDetalle,
    required this.idInventario,
    required this.producto,
    required this.codigoLote,
    required this.fechaCaducidad,
    required this.cantidad,
    required this.precioUnitario,
    required this.descuento,
    required this.subtotal,
  });

  factory VentaProductoDetalle.fromJson(Map<String, dynamic> map) {
    return VentaProductoDetalle(
      idVentaDetalle: VentaRegistrada._asInt(map['idVentaDetalle']),
      idInventario: VentaRegistrada._asInt(map['idInventario']),
      producto: map['producto']?.toString() ?? '',
      codigoLote: map['codigoLote']?.toString() ?? '',
      fechaCaducidad:
          DateTime.tryParse(map['fechaCaducidad']?.toString() ?? ''),
      cantidad: VentaRegistrada._asInt(map['cantidad']),
      precioUnitario: VentaRegistrada._asDouble(map['precioUnitario']),
      descuento: VentaRegistrada._asDouble(map['descuento']),
      subtotal: VentaRegistrada._asDouble(map['subtotal']),
    );
  }
}

class VentaPagoDetalle {
  final int idPagoVenta;
  final String medio;
  final double monto;
  final String referencia;
  final DateTime? fecha;

  const VentaPagoDetalle({
    required this.idPagoVenta,
    required this.medio,
    required this.monto,
    required this.referencia,
    required this.fecha,
  });

  factory VentaPagoDetalle.fromJson(Map<String, dynamic> map) {
    return VentaPagoDetalle(
      idPagoVenta: VentaRegistrada._asInt(map['idPagoVenta']),
      medio: map['medio']?.toString() ?? '',
      monto: VentaRegistrada._asDouble(map['monto']),
      referencia: map['referencia']?.toString() ?? '',
      fecha: DateTime.tryParse(map['fecha']?.toString() ?? ''),
    );
  }
}

class VentasApiService {
  final ApiClient _apiClient;

  VentasApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<VentaRegistrada> registrarVenta({
    required int idUsuario,
    required List<Medicamento> medicamentos,
    required Map<int, int> cantidades,
    required double descuentoGeneral,
    required String medioPago,
    required double total,
    double? montoRecibido,
    String? referencia,
    String? observaciones,
  }) async {
    final response = await _apiClient.post('/ventas', {
      'idUsuario': idUsuario,
      'descuentoGeneral': descuentoGeneral,
      'montoRecibido': montoRecibido,
      'observaciones': observaciones,
      'detalles': medicamentos.map((medicamento) {
        return {
          'idInventario': medicamento.id,
          'cantidad': cantidades[medicamento.id] ?? 0,
          'descuento': 0,
        };
      }).toList(),
      'pagos': [
        {
          'medio': medioPago,
          'monto': total,
          'referencia': referencia ?? '',
        },
      ],
    });

    return VentaRegistrada.fromJson(response as Map<String, dynamic>);
  }

  Future<List<VentaResumen>> listarVentas({
    String? estatus,
    int limite = 100,
  }) async {
    final params = <String>['limite=$limite'];

    if (estatus != null && estatus.isNotEmpty) {
      params.add('estatus=$estatus');
    }

    final response = await _apiClient.get('/ventas?${params.join('&')}');
    final items = response as List<dynamic>;

    return items
        .map((item) => VentaResumen.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<VentaDetalleCompleta> obtenerVenta(int idVenta) async {
    final response = await _apiClient.get('/ventas/$idVenta');
    return VentaDetalleCompleta.fromJson(response as Map<String, dynamic>);
  }
}
