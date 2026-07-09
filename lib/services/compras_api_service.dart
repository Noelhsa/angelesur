import 'api_client.dart';

class CompraResumen {
  final int idCompra;
  final String? folioProveedor;
  final int? idProveedor;
  final String proveedor;
  final int idUsuario;
  final String usuario;
  final DateTime? fecha;
  final double subtotal;
  final double descuento;
  final double total;
  final String estatus;
  final String observaciones;

  const CompraResumen({
    required this.idCompra,
    required this.folioProveedor,
    required this.idProveedor,
    required this.proveedor,
    required this.idUsuario,
    required this.usuario,
    required this.fecha,
    required this.subtotal,
    required this.descuento,
    required this.total,
    required this.estatus,
    required this.observaciones,
  });

  factory CompraResumen.fromJson(Map<String, dynamic> map) {
    return CompraResumen(
      idCompra: _asInt(map['idCompra']),
      folioProveedor: _asNullableString(map['folioProveedor']),
      idProveedor: _asNullableInt(map['idProveedor']),
      proveedor: map['proveedor']?.toString() ?? 'Sin proveedor',
      idUsuario: _asInt(map['idUsuario']),
      usuario: map['usuario']?.toString() ?? '',
      fecha: DateTime.tryParse(map['fecha']?.toString() ?? ''),
      subtotal: _asDouble(map['subtotal']),
      descuento: _asDouble(map['descuento']),
      total: _asDouble(map['total']),
      estatus: map['estatus']?.toString() ?? '',
      observaciones: map['observaciones']?.toString() ?? '',
    );
  }
}

class CompraDetalle extends CompraResumen {
  final List<CompraProductoDetalle> detalles;

  const CompraDetalle({
    required super.idCompra,
    required super.folioProveedor,
    required super.idProveedor,
    required super.proveedor,
    required super.idUsuario,
    required super.usuario,
    required super.fecha,
    required super.subtotal,
    required super.descuento,
    required super.total,
    required super.estatus,
    required super.observaciones,
    required this.detalles,
  });

  factory CompraDetalle.fromJson(Map<String, dynamic> map) {
    final base = CompraResumen.fromJson(map);
    final detalles = (map['detalles'] as List<dynamic>? ?? [])
        .map((item) =>
            CompraProductoDetalle.fromJson(item as Map<String, dynamic>))
        .toList();

    return CompraDetalle(
      idCompra: base.idCompra,
      folioProveedor: base.folioProveedor,
      idProveedor: base.idProveedor,
      proveedor: base.proveedor,
      idUsuario: base.idUsuario,
      usuario: base.usuario,
      fecha: base.fecha,
      subtotal: base.subtotal,
      descuento: base.descuento,
      total: base.total,
      estatus: base.estatus,
      observaciones: base.observaciones,
      detalles: detalles,
    );
  }
}

class CompraProductoDetalle {
  final int idCompraDetalle;
  final int idCompra;
  final int idProducto;
  final String producto;
  final int? idInventario;
  final String codigoLote;
  final int cantidad;
  final double costoUnitario;
  final double precioVentaSugerido;
  final DateTime? fechaCaducidad;
  final double subtotal;

  const CompraProductoDetalle({
    required this.idCompraDetalle,
    required this.idCompra,
    required this.idProducto,
    required this.producto,
    required this.idInventario,
    required this.codigoLote,
    required this.cantidad,
    required this.costoUnitario,
    required this.precioVentaSugerido,
    required this.fechaCaducidad,
    required this.subtotal,
  });

  factory CompraProductoDetalle.fromJson(Map<String, dynamic> map) {
    return CompraProductoDetalle(
      idCompraDetalle: _asInt(map['idCompraDetalle']),
      idCompra: _asInt(map['idCompra']),
      idProducto: _asInt(map['idProducto']),
      producto: map['producto']?.toString() ?? 'Producto sin nombre',
      idInventario: _asNullableInt(map['idInventario']),
      codigoLote: map['codigoLote']?.toString() ?? 'SIN_LOTE',
      cantidad: _asInt(map['cantidad']),
      costoUnitario: _asDouble(map['costoUnitario']),
      precioVentaSugerido: _asDouble(map['precioVentaSugerido']),
      fechaCaducidad:
          DateTime.tryParse(map['fechaCaducidad']?.toString() ?? ''),
      subtotal: _asDouble(map['subtotal']),
    );
  }
}

class CompraDetallePayload {
  final int idProducto;
  final int cantidad;
  final double costoUnitario;
  final double precioVenta;
  final String? codigoLote;
  final String? fechaCaducidad;

  const CompraDetallePayload({
    required this.idProducto,
    required this.cantidad,
    required this.costoUnitario,
    required this.precioVenta,
    required this.codigoLote,
    required this.fechaCaducidad,
  });

  Map<String, dynamic> toJson() {
    return {
      'idProducto': idProducto,
      'cantidad': cantidad,
      'costoUnitario': costoUnitario,
      'precioVenta': precioVenta,
      'codigoLote': codigoLote,
      'fechaCaducidad': fechaCaducidad,
    };
  }
}

class CompraPayload {
  final int idUsuario;
  final int? idProveedor;
  final String? folioProveedor;
  final double descuento;
  final String? observaciones;
  final List<CompraDetallePayload> detalles;
  final String? medioPago;
  final double montoPagado;

  const CompraPayload({
    required this.idUsuario,
    required this.idProveedor,
    required this.folioProveedor,
    required this.descuento,
    required this.observaciones,
    required this.detalles,
    required this.medioPago,
    required this.montoPagado,
  });

  Map<String, dynamic> toJson() {
    return {
      'idUsuario': idUsuario,
      'idProveedor': idProveedor,
      'folioProveedor': folioProveedor,
      'descuento': descuento,
      'observaciones': observaciones,
      'detalles': detalles.map((detalle) => detalle.toJson()).toList(),
      'medioPago': medioPago,
      'montoPagado': montoPagado,
    };
  }
}

class ComprasApiService {
  final ApiClient _apiClient;

  ComprasApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<List<CompraResumen>> listarCompras({
    String? estatus,
    int? idProveedor,
    int limite = 100,
  }) async {
    final params = <String, String>{
      'limite': limite.toString(),
      if (estatus != null && estatus.isNotEmpty) 'estatus': estatus,
      if (idProveedor != null) 'idProveedor': idProveedor.toString(),
    };
    final query = Uri(queryParameters: params).query;
    final response = await _apiClient.get('/compras?$query');
    final list = response as List<dynamic>;
    return list
        .map((item) => CompraResumen.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<CompraDetalle> obtenerCompra(int idCompra) async {
    final response = await _apiClient.get('/compras/$idCompra');
    return CompraDetalle.fromJson(response as Map<String, dynamic>);
  }

  Future<CompraDetalle> registrarCompra(CompraPayload payload) async {
    final response = await _apiClient.post('/compras', payload.toJson());
    return CompraDetalle.fromJson(response as Map<String, dynamic>);
  }

  Future<CompraDetalle> cancelarCompra({
    required int idCompra,
    required int idUsuario,
    String? observaciones,
  }) async {
    final response = await _apiClient.post('/compras/$idCompra/cancelar', {
      'idUsuario': idUsuario,
      'observaciones': observaciones,
    });
    return CompraDetalle.fromJson(response as Map<String, dynamic>);
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _asNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String? _asNullableString(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}
