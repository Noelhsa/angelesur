import 'api_client.dart';

class MovimientoCaja {
  final int idMovDin;
  final int idCorte;
  final int idUsuario;
  final String usuario;
  final String medio;
  final String tipo;
  final String concepto;
  final double monto;
  final DateTime? fecha;
  final int? idVenta;
  final int? idPagoVenta;
  final int? idServicioOperacion;
  final int? idCompra;
  final int? idDevolucionCliente;
  final int? idDevolucionProveedor;
  final String observaciones;

  const MovimientoCaja({
    required this.idMovDin,
    required this.idCorte,
    required this.idUsuario,
    required this.usuario,
    required this.medio,
    required this.tipo,
    required this.concepto,
    required this.monto,
    required this.fecha,
    required this.idVenta,
    required this.idPagoVenta,
    required this.idServicioOperacion,
    required this.idCompra,
    required this.idDevolucionCliente,
    required this.idDevolucionProveedor,
    required this.observaciones,
  });

  factory MovimientoCaja.fromJson(Map<String, dynamic> map) {
    return MovimientoCaja(
      idMovDin: _asInt(map['idMovDin']),
      idCorte: _asInt(map['idCorte']),
      idUsuario: _asInt(map['idUsuario']),
      usuario: map['usuario']?.toString() ?? '',
      medio: map['medio']?.toString() ?? '',
      tipo: map['tipo']?.toString() ?? '',
      concepto: map['concepto']?.toString() ?? '',
      monto: _asDouble(map['monto']),
      fecha: DateTime.tryParse(map['fecha']?.toString() ?? ''),
      idVenta: _asNullableInt(map['idVenta']),
      idPagoVenta: _asNullableInt(map['idPagoVenta']),
      idServicioOperacion: _asNullableInt(map['idServicioOperacion']),
      idCompra: _asNullableInt(map['idCompra']),
      idDevolucionCliente: _asNullableInt(map['idDevolucionCliente']),
      idDevolucionProveedor: _asNullableInt(map['idDevolucionProveedor']),
      observaciones: map['observaciones']?.toString() ?? '',
    );
  }

  bool get esEntrada => tipo.toUpperCase() == 'ENTRADA';

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _asNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class CajaApiService {
  final ApiClient _apiClient;

  CajaApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<List<MovimientoCaja>> listarMovimientos({
    int? idCorte,
    String? medio,
    String? tipo,
    String? concepto,
    int limite = 100,
  }) async {
    final params = <String, String>{
      'limite': limite.toString(),
      if (idCorte != null) 'idCorte': idCorte.toString(),
      if (medio != null && medio.isNotEmpty) 'medio': medio,
      if (tipo != null && tipo.isNotEmpty) 'tipo': tipo,
      if (concepto != null && concepto.isNotEmpty) 'concepto': concepto,
    };
    final query = Uri(queryParameters: params).query;
    final response = await _apiClient.get('/caja/movimientos?$query');
    final list = response as List<dynamic>;
    return list
        .map((item) => MovimientoCaja.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> registrarMovimiento({
    required int idUsuario,
    required String medio,
    required String tipo,
    required String concepto,
    required double monto,
    int? idCompra,
    String? observaciones,
  }) async {
    await _apiClient.post('/caja/movimiento', {
      'idUsuario': idUsuario,
      'medio': medio,
      'tipo': tipo,
      'concepto': concepto,
      'monto': monto,
      'idCompra': idCompra,
      'observaciones': observaciones,
    });
  }
}
