import 'api_client.dart';

class ProveedorApi {
  final int idProveedor;
  final String nombre;
  final String telefono;
  final String contacto;
  final String direccion;
  final bool activo;

  const ProveedorApi({
    required this.idProveedor,
    required this.nombre,
    required this.telefono,
    required this.contacto,
    required this.direccion,
    required this.activo,
  });

  factory ProveedorApi.fromJson(Map<String, dynamic> map) {
    return ProveedorApi(
      idProveedor: _asInt(map['idProveedor']),
      nombre: map['nombre']?.toString() ?? 'Proveedor sin nombre',
      telefono: map['telefono']?.toString() ?? '',
      contacto: map['contacto']?.toString() ?? '',
      direccion: map['direccion']?.toString() ?? '',
      activo: _asBool(map['activo'], defaultValue: true),
    );
  }
}

class ProveedorPayload {
  final String nombre;
  final String? telefono;
  final String? contacto;
  final String? direccion;

  const ProveedorPayload({
    required this.nombre,
    required this.telefono,
    required this.contacto,
    required this.direccion,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'telefono': telefono,
      'contacto': contacto,
      'direccion': direccion,
    };
  }
}

class ProveedoresApiService {
  final ApiClient _apiClient;

  ProveedoresApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<List<ProveedorApi>> listarProveedores({
    String? busqueda,
    bool incluirInactivos = true,
    int limite = 500,
  }) async {
    final params = <String, String>{
      'incluirInactivos': incluirInactivos.toString(),
      'limite': limite.toString(),
      if (busqueda != null && busqueda.trim().isNotEmpty)
        'busqueda': busqueda.trim(),
    };
    final query = Uri(queryParameters: params).query;
    final response = await _apiClient.get('/proveedores?$query');
    final list = response as List<dynamic>;
    return list
        .map((item) => ProveedorApi.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ProveedorApi> crearProveedor(ProveedorPayload payload) async {
    final response = await _apiClient.post('/proveedores', payload.toJson());
    return ProveedorApi.fromJson(response as Map<String, dynamic>);
  }

  Future<ProveedorApi> actualizarProveedor(
    int idProveedor,
    ProveedorPayload payload,
  ) async {
    final response = await _apiClient.patch(
      '/proveedores/$idProveedor',
      payload.toJson(),
    );
    return ProveedorApi.fromJson(response as Map<String, dynamic>);
  }

  Future<ProveedorApi> cambiarEstado(
    int idProveedor, {
    required bool activo,
  }) async {
    final response =
        await _apiClient.patch('/proveedores/$idProveedor/estado', {
      'activo': activo,
    });
    return ProveedorApi.fromJson(response as Map<String, dynamic>);
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _asBool(dynamic value, {bool defaultValue = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().toLowerCase();
  if (text == 'true' || text == '1') return true;
  if (text == 'false' || text == '0') return false;
  return defaultValue;
}
