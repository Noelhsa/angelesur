import 'api_client.dart';

class TarifaServicioYastas {
  final int idTarifa;
  final String tipoServicio;
  final String nombreServicio;
  final double montoBase;
  final double comisionCliente;
  final double comisionYastas;
  final double regaliaYastas;
  final double gananciaFarmacia;
  final bool activo;

  const TarifaServicioYastas({
    required this.idTarifa,
    required this.tipoServicio,
    required this.nombreServicio,
    required this.montoBase,
    required this.comisionCliente,
    required this.comisionYastas,
    required this.regaliaYastas,
    required this.gananciaFarmacia,
    required this.activo,
  });

  factory TarifaServicioYastas.fromJson(Map<String, dynamic> map) {
    return TarifaServicioYastas(
      idTarifa: _asInt(map['idTarifa']),
      tipoServicio: map['tipoServicio']?.toString() ?? '',
      nombreServicio: map['nombreServicio']?.toString() ?? '',
      montoBase: _asDouble(map['montoBase']),
      comisionCliente: _asDouble(map['comisionCliente']),
      comisionYastas: _asDouble(map['comisionYastas']),
      regaliaYastas: _asDouble(map['regaliaYastas']),
      gananciaFarmacia: _asDouble(map['gananciaFarmacia']),
      activo: _asBool(map['activo']),
    );
  }

  double totalCobrado(double montoServicio) {
    return montoServicio + comisionCliente;
  }

  String get tipoVisible {
    switch (tipoServicio) {
      case 'RECARGA':
        return 'Recarga';
      case 'DEPOSITO':
        return 'Deposito';
      case 'RETIRO':
        return 'Retiro';
      case 'PAGO_SERVICIO':
        return 'Pago de servicio';
      case 'CFE':
        return 'CFE';
      case 'TELMEX':
        return 'Telmex';
      case 'IZZI':
        return 'Izzi';
      case 'INTERNET':
        return 'Internet';
      default:
        return 'Otro';
    }
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _asDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _asBool(Object? value) {
    return value == true || value == 1 || value?.toString() == '1';
  }
}

class ServicioYastasRegistrado {
  final int idServicioOperacion;
  final int? idUsuario;
  final int? idCorte;
  final String usuario;
  final String nombreServicio;
  final String tipoServicio;
  final String referenciaOperacion;
  final double montoServicio;
  final double comisionCliente;
  final double comisionYastas;
  final double regaliaYastas;
  final double gananciaFarmacia;
  final double totalCobradoCliente;
  final String estatus;
  final DateTime? fecha;
  final String observaciones;

  const ServicioYastasRegistrado({
    required this.idServicioOperacion,
    required this.idUsuario,
    required this.idCorte,
    required this.usuario,
    required this.nombreServicio,
    required this.tipoServicio,
    required this.referenciaOperacion,
    required this.montoServicio,
    required this.comisionCliente,
    required this.comisionYastas,
    required this.regaliaYastas,
    required this.gananciaFarmacia,
    required this.totalCobradoCliente,
    required this.estatus,
    required this.fecha,
    required this.observaciones,
  });

  factory ServicioYastasRegistrado.fromJson(Map<String, dynamic> map) {
    return ServicioYastasRegistrado(
      idServicioOperacion: TarifaServicioYastas._asInt(
        map['idServicioOperacion'],
      ),
      idUsuario: _asNullableInt(map['idUsuario']),
      idCorte: _asNullableInt(map['idCorte']),
      usuario: map['usuario']?.toString() ?? '',
      nombreServicio: map['nombreServicio']?.toString() ?? '',
      tipoServicio: map['tipoServicio']?.toString() ?? '',
      referenciaOperacion: map['referenciaOperacion']?.toString() ?? '',
      montoServicio: TarifaServicioYastas._asDouble(map['montoServicio']),
      comisionCliente: TarifaServicioYastas._asDouble(map['comisionCliente']),
      comisionYastas: TarifaServicioYastas._asDouble(map['comisionYastas']),
      regaliaYastas: TarifaServicioYastas._asDouble(map['regaliaYastas']),
      gananciaFarmacia: TarifaServicioYastas._asDouble(
        map['gananciaFarmacia'],
      ),
      totalCobradoCliente: TarifaServicioYastas._asDouble(
        map['totalCobradoCliente'],
      ),
      estatus: map['estatus']?.toString() ?? '',
      fecha: DateTime.tryParse(map['fecha']?.toString() ?? ''),
      observaciones: map['observaciones']?.toString() ?? '',
    );
  }

  static int? _asNullableInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

class ServiciosYastasApiService {
  final ApiClient _apiClient;

  ServiciosYastasApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<List<TarifaServicioYastas>> listarTarifas({
    String? tipoServicio,
    bool incluirInactivas = false,
    int limite = 200,
  }) async {
    final params = <String, String>{
      'incluirInactivas': incluirInactivas.toString(),
      'limite': limite.toString(),
      if (tipoServicio != null && tipoServicio.isNotEmpty)
        'tipoServicio': tipoServicio,
    };
    final query = Uri(queryParameters: params).query;
    final response = await _apiClient.get('/servicios-yastas/tarifas?$query');
    final items = response as List<dynamic>;

    return items
        .map(
          (item) => TarifaServicioYastas.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<ServicioYastasRegistrado> registrarServicio({
    required int idUsuario,
    required int idTarifa,
    required double montoServicio,
    String? referenciaOperacion,
    String? observaciones,
  }) async {
    final response = await _apiClient.post('/servicios-yastas', {
      'idUsuario': idUsuario,
      'idTarifa': idTarifa,
      'montoServicio': montoServicio,
      'referenciaOperacion': referenciaOperacion,
      'observaciones': observaciones,
    });

    return ServicioYastasRegistrado.fromJson(response as Map<String, dynamic>);
  }

  Future<List<ServicioYastasRegistrado>> listarServicios({
    String? estatus,
    String? tipoServicio,
    int? idCorte,
    int? idUsuario,
    int limite = 200,
  }) async {
    final params = <String, String>{
      'limite': limite.toString(),
      if (estatus != null && estatus.isNotEmpty) 'estatus': estatus,
      if (tipoServicio != null && tipoServicio.isNotEmpty)
        'tipoServicio': tipoServicio,
      if (idCorte != null) 'idCorte': idCorte.toString(),
      if (idUsuario != null) 'idUsuario': idUsuario.toString(),
    };
    final query = Uri(queryParameters: params).query;
    final response = await _apiClient.get('/servicios-yastas?$query');
    final items = response as List<dynamic>;

    return items
        .map(
          (item) =>
              ServicioYastasRegistrado.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<TarifaServicioYastas> crearTarifa({
    required String tipoServicio,
    required String nombreServicio,
    double montoBase = 0,
    required double comisionCliente,
    required double comisionYastas,
    required double regaliaYastas,
    required double gananciaFarmacia,
  }) async {
    final response = await _apiClient.post('/servicios-yastas/tarifas', {
      'tipoServicio': tipoServicio,
      'nombreServicio': nombreServicio,
      'montoBase': montoBase,
      'comisionCliente': comisionCliente,
      'comisionYastas': comisionYastas,
      'regaliaYastas': regaliaYastas,
      'gananciaFarmacia': gananciaFarmacia,
    });

    return TarifaServicioYastas.fromJson(response as Map<String, dynamic>);
  }

  Future<TarifaServicioYastas> actualizarTarifa({
    required int idTarifa,
    required String tipoServicio,
    required String nombreServicio,
    double montoBase = 0,
    required double comisionCliente,
    required double comisionYastas,
    required double regaliaYastas,
    required double gananciaFarmacia,
  }) async {
    final response = await _apiClient.patch(
      '/servicios-yastas/tarifas/$idTarifa',
      {
        'tipoServicio': tipoServicio,
        'nombreServicio': nombreServicio,
        'montoBase': montoBase,
        'comisionCliente': comisionCliente,
        'comisionYastas': comisionYastas,
        'regaliaYastas': regaliaYastas,
        'gananciaFarmacia': gananciaFarmacia,
      },
    );

    return TarifaServicioYastas.fromJson(response as Map<String, dynamic>);
  }

  Future<TarifaServicioYastas> cambiarEstadoTarifa({
    required int idTarifa,
    required bool activo,
  }) async {
    final response = await _apiClient.patch(
      '/servicios-yastas/tarifas/$idTarifa/estado',
      {'activo': activo},
    );

    return TarifaServicioYastas.fromJson(response as Map<String, dynamic>);
  }
}
