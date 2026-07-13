import 'api_client.dart';

class DevolucionClienteResumen {
  final int idDevolucionCliente;
  final String folio;
  final int idVenta;
  final String folioVenta;
  final int? idCorte;
  final int idUsuario;
  final String usuario;
  final DateTime? fecha;
  final String motivo;
  final double totalDevuelto;
  final String metodoDevolucion;
  final String estatus;
  final String observaciones;
  final DateTime? createdAt;

  const DevolucionClienteResumen({
    required this.idDevolucionCliente,
    required this.folio,
    required this.idVenta,
    required this.folioVenta,
    required this.idCorte,
    required this.idUsuario,
    required this.usuario,
    required this.fecha,
    required this.motivo,
    required this.totalDevuelto,
    required this.metodoDevolucion,
    required this.estatus,
    required this.observaciones,
    required this.createdAt,
  });

  factory DevolucionClienteResumen.fromJson(Map<String, dynamic> map) {
    return DevolucionClienteResumen(
      idDevolucionCliente: _asInt(map['idDevolucionCliente']),
      folio: map['folio']?.toString() ?? '',
      idVenta: _asInt(map['idVenta']),
      folioVenta: map['folioVenta']?.toString() ?? '',
      idCorte: _asNullableInt(map['idCorte']),
      idUsuario: _asInt(map['idUsuario']),
      usuario: map['usuario']?.toString() ?? '',
      fecha: DateTime.tryParse(map['fecha']?.toString() ?? ''),
      motivo: map['motivo']?.toString() ?? '',
      totalDevuelto: _asDouble(map['totalDevuelto']),
      metodoDevolucion: map['metodoDevolucion']?.toString() ?? '',
      estatus: map['estatus']?.toString() ?? '',
      observaciones: map['observaciones']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
    );
  }
}

class DevolucionClienteDetalle extends DevolucionClienteResumen {
  final List<DevolucionClienteProducto> detalles;

  const DevolucionClienteDetalle({
    required super.idDevolucionCliente,
    required super.folio,
    required super.idVenta,
    required super.folioVenta,
    required super.idCorte,
    required super.idUsuario,
    required super.usuario,
    required super.fecha,
    required super.motivo,
    required super.totalDevuelto,
    required super.metodoDevolucion,
    required super.estatus,
    required super.observaciones,
    required super.createdAt,
    required this.detalles,
  });

  factory DevolucionClienteDetalle.fromJson(Map<String, dynamic> map) {
    final base = DevolucionClienteResumen.fromJson(map);
    final detalles = (map['detalles'] as List<dynamic>? ?? [])
        .map((item) =>
            DevolucionClienteProducto.fromJson(item as Map<String, dynamic>))
        .toList();

    return DevolucionClienteDetalle(
      idDevolucionCliente: base.idDevolucionCliente,
      folio: base.folio,
      idVenta: base.idVenta,
      folioVenta: base.folioVenta,
      idCorte: base.idCorte,
      idUsuario: base.idUsuario,
      usuario: base.usuario,
      fecha: base.fecha,
      motivo: base.motivo,
      totalDevuelto: base.totalDevuelto,
      metodoDevolucion: base.metodoDevolucion,
      estatus: base.estatus,
      observaciones: base.observaciones,
      createdAt: base.createdAt,
      detalles: detalles,
    );
  }
}

class DevolucionClienteProducto {
  final int idDevolucionClienteDetalle;
  final int idDevolucionCliente;
  final int idVentaDetalle;
  final int idInventario;
  final String producto;
  final String codigoLote;
  final int cantidad;
  final double precioUnitarioDevuelto;
  final double subtotalDevuelto;
  final bool regresaAInventario;
  final String motivoDetalle;
  final String observaciones;

  const DevolucionClienteProducto({
    required this.idDevolucionClienteDetalle,
    required this.idDevolucionCliente,
    required this.idVentaDetalle,
    required this.idInventario,
    required this.producto,
    required this.codigoLote,
    required this.cantidad,
    required this.precioUnitarioDevuelto,
    required this.subtotalDevuelto,
    required this.regresaAInventario,
    required this.motivoDetalle,
    required this.observaciones,
  });

  factory DevolucionClienteProducto.fromJson(Map<String, dynamic> map) {
    return DevolucionClienteProducto(
      idDevolucionClienteDetalle: _asInt(map['idDevolucionClienteDetalle']),
      idDevolucionCliente: _asInt(map['idDevolucionCliente']),
      idVentaDetalle: _asInt(map['idVentaDetalle']),
      idInventario: _asInt(map['idInventario']),
      producto: map['producto']?.toString() ?? '',
      codigoLote: map['codigoLote']?.toString() ?? '',
      cantidad: _asInt(map['cantidad']),
      precioUnitarioDevuelto: _asDouble(map['precioUnitarioDevuelto']),
      subtotalDevuelto: _asDouble(map['subtotalDevuelto']),
      regresaAInventario: _asBool(map['regresaAInventario']),
      motivoDetalle: map['motivoDetalle']?.toString() ?? '',
      observaciones: map['observaciones']?.toString() ?? '',
    );
  }
}

class DevolucionProveedorResumen {
  final int idDevolucionProveedor;
  final String folio;
  final int? idCompra;
  final int? idProveedor;
  final String proveedor;
  final int? idCorte;
  final int idUsuario;
  final String usuario;
  final DateTime? fecha;
  final String motivo;
  final double totalDevolucion;
  final String tipoCompensacion;
  final String estatus;
  final String observaciones;
  final DateTime? createdAt;

  const DevolucionProveedorResumen({
    required this.idDevolucionProveedor,
    required this.folio,
    required this.idCompra,
    required this.idProveedor,
    required this.proveedor,
    required this.idCorte,
    required this.idUsuario,
    required this.usuario,
    required this.fecha,
    required this.motivo,
    required this.totalDevolucion,
    required this.tipoCompensacion,
    required this.estatus,
    required this.observaciones,
    required this.createdAt,
  });

  factory DevolucionProveedorResumen.fromJson(Map<String, dynamic> map) {
    return DevolucionProveedorResumen(
      idDevolucionProveedor: _asInt(map['idDevolucionProveedor']),
      folio: map['folio']?.toString() ?? '',
      idCompra: _asNullableInt(map['idCompra']),
      idProveedor: _asNullableInt(map['idProveedor']),
      proveedor: map['proveedor']?.toString() ?? 'Sin proveedor',
      idCorte: _asNullableInt(map['idCorte']),
      idUsuario: _asInt(map['idUsuario']),
      usuario: map['usuario']?.toString() ?? '',
      fecha: DateTime.tryParse(map['fecha']?.toString() ?? ''),
      motivo: map['motivo']?.toString() ?? '',
      totalDevolucion: _asDouble(map['totalDevolucion']),
      tipoCompensacion: map['tipoCompensacion']?.toString() ?? '',
      estatus: map['estatus']?.toString() ?? '',
      observaciones: map['observaciones']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
    );
  }
}

class DevolucionProveedorDetalle extends DevolucionProveedorResumen {
  final List<DevolucionProveedorProducto> detalles;

  const DevolucionProveedorDetalle({
    required super.idDevolucionProveedor,
    required super.folio,
    required super.idCompra,
    required super.idProveedor,
    required super.proveedor,
    required super.idCorte,
    required super.idUsuario,
    required super.usuario,
    required super.fecha,
    required super.motivo,
    required super.totalDevolucion,
    required super.tipoCompensacion,
    required super.estatus,
    required super.observaciones,
    required super.createdAt,
    required this.detalles,
  });

  factory DevolucionProveedorDetalle.fromJson(Map<String, dynamic> map) {
    final base = DevolucionProveedorResumen.fromJson(map);
    final detalles = (map['detalles'] as List<dynamic>? ?? [])
        .map((item) =>
            DevolucionProveedorProducto.fromJson(item as Map<String, dynamic>))
        .toList();

    return DevolucionProveedorDetalle(
      idDevolucionProveedor: base.idDevolucionProveedor,
      folio: base.folio,
      idCompra: base.idCompra,
      idProveedor: base.idProveedor,
      proveedor: base.proveedor,
      idCorte: base.idCorte,
      idUsuario: base.idUsuario,
      usuario: base.usuario,
      fecha: base.fecha,
      motivo: base.motivo,
      totalDevolucion: base.totalDevolucion,
      tipoCompensacion: base.tipoCompensacion,
      estatus: base.estatus,
      observaciones: base.observaciones,
      createdAt: base.createdAt,
      detalles: detalles,
    );
  }
}

class DevolucionProveedorProducto {
  final int idDevolucionProveedorDetalle;
  final int idDevolucionProveedor;
  final int? idCompraDetalle;
  final int idInventario;
  final String producto;
  final String codigoLote;
  final int cantidad;
  final double costoUnitario;
  final double subtotal;
  final String motivoDetalle;
  final String observaciones;

  const DevolucionProveedorProducto({
    required this.idDevolucionProveedorDetalle,
    required this.idDevolucionProveedor,
    required this.idCompraDetalle,
    required this.idInventario,
    required this.producto,
    required this.codigoLote,
    required this.cantidad,
    required this.costoUnitario,
    required this.subtotal,
    required this.motivoDetalle,
    required this.observaciones,
  });

  factory DevolucionProveedorProducto.fromJson(Map<String, dynamic> map) {
    return DevolucionProveedorProducto(
      idDevolucionProveedorDetalle: _asInt(map['idDevolucionProveedorDetalle']),
      idDevolucionProveedor: _asInt(map['idDevolucionProveedor']),
      idCompraDetalle: _asNullableInt(map['idCompraDetalle']),
      idInventario: _asInt(map['idInventario']),
      producto: map['producto']?.toString() ?? '',
      codigoLote: map['codigoLote']?.toString() ?? '',
      cantidad: _asInt(map['cantidad']),
      costoUnitario: _asDouble(map['costoUnitario']),
      subtotal: _asDouble(map['subtotal']),
      motivoDetalle: map['motivoDetalle']?.toString() ?? '',
      observaciones: map['observaciones']?.toString() ?? '',
    );
  }
}

class RegistrarDevolucionClientePayload {
  final int idUsuario;
  final int idVenta;
  final String metodoDevolucion;
  final String motivo;
  final String? observaciones;
  final List<DevolucionClienteDetallePayload> detalles;

  const RegistrarDevolucionClientePayload({
    required this.idUsuario,
    required this.idVenta,
    required this.metodoDevolucion,
    required this.motivo,
    required this.observaciones,
    required this.detalles,
  });

  Map<String, dynamic> toJson() {
    return {
      'idUsuario': idUsuario,
      'idVenta': idVenta,
      'metodoDevolucion': metodoDevolucion,
      'motivo': motivo,
      'observaciones': observaciones,
      'detalles': detalles.map((detalle) => detalle.toJson()).toList(),
    };
  }
}

class DevolucionClienteDetallePayload {
  final int idVentaDetalle;
  final int cantidad;
  final bool regresaAInventario;
  final String? motivoDetalle;
  final String? observaciones;

  const DevolucionClienteDetallePayload({
    required this.idVentaDetalle,
    required this.cantidad,
    required this.regresaAInventario,
    required this.motivoDetalle,
    required this.observaciones,
  });

  Map<String, dynamic> toJson() {
    return {
      'idVentaDetalle': idVentaDetalle,
      'cantidad': cantidad,
      'regresaAInventario': regresaAInventario,
      'motivoDetalle': motivoDetalle,
      'observaciones': observaciones,
    };
  }
}

class RegistrarDevolucionProveedorPayload {
  final int idUsuario;
  final int? idCompra;
  final int? idProveedor;
  final String tipoCompensacion;
  final String motivo;
  final String? observaciones;
  final List<DevolucionProveedorDetallePayload> detalles;
  final List<ReposicionProveedorDetallePayload>? reposicionDetalles;

  const RegistrarDevolucionProveedorPayload({
    required this.idUsuario,
    required this.idCompra,
    required this.idProveedor,
    required this.tipoCompensacion,
    required this.motivo,
    required this.observaciones,
    required this.detalles,
    required this.reposicionDetalles,
  });

  Map<String, dynamic> toJson() {
    return {
      'idUsuario': idUsuario,
      'idCompra': idCompra,
      'idProveedor': idProveedor,
      'tipoCompensacion': tipoCompensacion,
      'motivo': motivo,
      'observaciones': observaciones,
      'detalles': detalles.map((detalle) => detalle.toJson()).toList(),
      'reposicionDetalles':
          reposicionDetalles?.map((detalle) => detalle.toJson()).toList(),
    };
  }
}

class DevolucionProveedorDetallePayload {
  final int? idCompraDetalle;
  final int idInventario;
  final int cantidad;
  final String? motivoDetalle;
  final String? observaciones;

  const DevolucionProveedorDetallePayload({
    required this.idCompraDetalle,
    required this.idInventario,
    required this.cantidad,
    required this.motivoDetalle,
    required this.observaciones,
  });

  Map<String, dynamic> toJson() {
    return {
      'idCompraDetalle': idCompraDetalle,
      'idInventario': idInventario,
      'cantidad': cantidad,
      'motivoDetalle': motivoDetalle,
      'observaciones': observaciones,
    };
  }
}

class ReposicionProveedorDetallePayload {
  final int idProducto;
  final int cantidad;
  final double costoUnitario;
  final double precioVenta;
  final String? codigoLote;
  final String? fechaCaducidad;

  const ReposicionProveedorDetallePayload({
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

class DevolucionesApiService {
  final ApiClient _apiClient;

  DevolucionesApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<List<DevolucionClienteResumen>> listarClientes({
    String? estatus,
    int? idVenta,
    int limite = 100,
  }) async {
    final query = Uri(
      queryParameters: {
        'limite': limite.toString(),
        if (estatus != null && estatus.isNotEmpty) 'estatus': estatus,
        if (idVenta != null) 'idVenta': idVenta.toString(),
      },
    ).query;
    final response = await _apiClient.get('/devoluciones/clientes?$query');
    final list = response as List<dynamic>;
    return list
        .map((item) =>
            DevolucionClienteResumen.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<DevolucionClienteDetalle> obtenerCliente(int idDevolucion) async {
    final response =
        await _apiClient.get('/devoluciones/clientes/$idDevolucion');
    return DevolucionClienteDetalle.fromJson(response as Map<String, dynamic>);
  }

  Future<DevolucionClienteDetalle> registrarCliente(
    RegistrarDevolucionClientePayload payload,
  ) async {
    final response =
        await _apiClient.post('/devoluciones/clientes', payload.toJson());
    return DevolucionClienteDetalle.fromJson(response as Map<String, dynamic>);
  }

  Future<DevolucionClienteDetalle> cancelarCliente({
    required int idDevolucion,
    required int idUsuario,
    String? observaciones,
  }) async {
    final response = await _apiClient.post(
      '/devoluciones/clientes/$idDevolucion/cancelar',
      {
        'idUsuario': idUsuario,
        'observaciones': observaciones,
      },
    );
    return DevolucionClienteDetalle.fromJson(response as Map<String, dynamic>);
  }

  Future<List<DevolucionProveedorResumen>> listarProveedores({
    String? estatus,
    int? idCompra,
    int? idProveedor,
    int limite = 100,
  }) async {
    final query = Uri(
      queryParameters: {
        'limite': limite.toString(),
        if (estatus != null && estatus.isNotEmpty) 'estatus': estatus,
        if (idCompra != null) 'idCompra': idCompra.toString(),
        if (idProveedor != null) 'idProveedor': idProveedor.toString(),
      },
    ).query;
    final response = await _apiClient.get('/devoluciones/proveedores?$query');
    final list = response as List<dynamic>;
    return list
        .map((item) =>
            DevolucionProveedorResumen.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<DevolucionProveedorDetalle> obtenerProveedor(int idDevolucion) async {
    final response =
        await _apiClient.get('/devoluciones/proveedores/$idDevolucion');
    return DevolucionProveedorDetalle.fromJson(
        response as Map<String, dynamic>);
  }

  Future<DevolucionProveedorDetalle> registrarProveedor(
    RegistrarDevolucionProveedorPayload payload,
  ) async {
    final response =
        await _apiClient.post('/devoluciones/proveedores', payload.toJson());
    return DevolucionProveedorDetalle.fromJson(
        response as Map<String, dynamic>);
  }

  Future<DevolucionProveedorDetalle> cancelarProveedor({
    required int idDevolucion,
    required int idUsuario,
    String? observaciones,
  }) async {
    final response = await _apiClient.post(
      '/devoluciones/proveedores/$idDevolucion/cancelar',
      {
        'idUsuario': idUsuario,
        'observaciones': observaciones,
      },
    );
    return DevolucionProveedorDetalle.fromJson(
        response as Map<String, dynamic>);
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

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().toLowerCase();
  return text == 'true' || text == '1';
}
