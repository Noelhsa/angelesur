import 'api_client.dart';

class ProductoCatalogoApi {
  final int idProducto;
  final String? codigoBarras;
  final String nombre;
  final String? descripcion;
  final String tipo;
  final String? categoria;
  final bool manejaCaducidad;
  final bool activo;
  final String? presentacion;
  final String? viaAdministracion;
  final String? edad;
  final bool requiereReceta;
  final String? sustanciaActiva;
  final String? dosis;

  const ProductoCatalogoApi({
    required this.idProducto,
    required this.codigoBarras,
    required this.nombre,
    required this.descripcion,
    required this.tipo,
    required this.categoria,
    required this.manejaCaducidad,
    required this.activo,
    required this.presentacion,
    required this.viaAdministracion,
    required this.edad,
    required this.requiereReceta,
    required this.sustanciaActiva,
    required this.dosis,
  });

  factory ProductoCatalogoApi.fromJson(Map<String, dynamic> map) {
    return ProductoCatalogoApi(
      idProducto: _asInt(map['idProducto']),
      codigoBarras: _asNullableString(map['codigoBarras']),
      nombre: map['nombre']?.toString() ?? 'Producto sin nombre',
      descripcion: _asNullableString(map['descripcion']),
      tipo: map['tipo']?.toString() ?? 'PRODUCTO',
      categoria: _asNullableString(map['categoria']),
      manejaCaducidad: _asBool(map['manejaCaducidad']),
      activo: _asBool(map['activo'], defaultValue: true),
      presentacion: _asNullableString(map['presentacion']),
      viaAdministracion: _asNullableString(map['viaAdministracion']),
      edad: _asNullableString(map['edad']),
      requiereReceta: _asBool(map['requiereReceta']),
      sustanciaActiva: _asNullableString(map['sustanciaActiva']),
      dosis: _asNullableString(map['dosis']),
    );
  }

  bool get esMedicamento => tipo.toUpperCase() == 'MEDICAMENTO';

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _asBool(dynamic value, {bool defaultValue = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().toLowerCase();
    if (text == 'true' || text == '1') return true;
    if (text == 'false' || text == '0') return false;
    return defaultValue;
  }

  static String? _asNullableString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}

class ProductoPayload {
  final String? codigoBarras;
  final String nombre;
  final String? descripcion;
  final String tipo;
  final String? categoria;
  final bool manejaCaducidad;
  final Map<String, dynamic>? infoMedicamento;

  const ProductoPayload({
    required this.codigoBarras,
    required this.nombre,
    required this.descripcion,
    required this.tipo,
    required this.categoria,
    required this.manejaCaducidad,
    required this.infoMedicamento,
  });

  Map<String, dynamic> toJson() {
    return {
      'codigoBarras': codigoBarras,
      'nombre': nombre,
      'descripcion': descripcion,
      'tipo': tipo,
      'categoria': categoria,
      'manejaCaducidad': manejaCaducidad,
      'infoMedicamento': infoMedicamento,
    };
  }
}

class ProductosApiService {
  final ApiClient _apiClient;

  ProductosApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<List<ProductoCatalogoApi>> listarProductos({
    String? busqueda,
    String? tipo,
    bool incluirInactivos = true,
    int limite = 500,
  }) async {
    final params = <String, String>{
      'incluirInactivos': incluirInactivos.toString(),
      'limite': limite.toString(),
      if (busqueda != null && busqueda.trim().isNotEmpty)
        'busqueda': busqueda.trim(),
      if (tipo != null && tipo.isNotEmpty) 'tipo': tipo,
    };
    final query = Uri(queryParameters: params).query;
    final response = await _apiClient.get('/productos?$query');
    final list = response as List<dynamic>;
    return list
        .map((item) =>
            ProductoCatalogoApi.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ProductoCatalogoApi> obtenerProducto(int idProducto) async {
    final response = await _apiClient.get('/productos/$idProducto');
    return ProductoCatalogoApi.fromJson(response as Map<String, dynamic>);
  }

  Future<ProductoCatalogoApi> crearProducto(ProductoPayload payload) async {
    final response = await _apiClient.post('/productos', payload.toJson());
    return ProductoCatalogoApi.fromJson(response as Map<String, dynamic>);
  }

  Future<ProductoCatalogoApi> actualizarProducto(
    int idProducto,
    ProductoPayload payload,
  ) async {
    final response =
        await _apiClient.patch('/productos/$idProducto', payload.toJson());
    return ProductoCatalogoApi.fromJson(response as Map<String, dynamic>);
  }

  Future<ProductoCatalogoApi> cambiarEstado(
    int idProducto, {
    required bool activo,
  }) async {
    final response = await _apiClient.patch('/productos/$idProducto/estado', {
      'activo': activo,
    });
    return ProductoCatalogoApi.fromJson(response as Map<String, dynamic>);
  }
}
