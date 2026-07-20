import '../models/medicamento.dart';
import 'api_client.dart';

class InventarioApiService {
  final ApiClient _apiClient;

  InventarioApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<List<Medicamento>> listarDisponibles() async {
    final response = await _apiClient.get('/inventario/disponible');
    final items = response as List<dynamic>;

    return items
        .map((item) =>
            Medicamento.fromInventarioJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<InventarioItem>> listarActual({
    String? busqueda,
    bool soloActivos = true,
    int limite = 500,
  }) async {
    final params = <String>[
      'soloActivos=$soloActivos',
      'limite=$limite',
    ];

    if (busqueda != null && busqueda.trim().isNotEmpty) {
      params.add('busqueda=${Uri.encodeQueryComponent(busqueda.trim())}');
    }

    final response =
        await _apiClient.get('/inventario/actual?${params.join('&')}');
    final items = response as List<dynamic>;

    return items
        .map((item) => InventarioItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<InventarioItem> actualizarUbicacion({
    required int idInventario,
    required String? ubicacionLetra,
    required int? ubicacionNumero,
  }) async {
    final response = await _apiClient.patch(
      '/inventario/$idInventario/ubicacion',
      {
        'ubicacionLetra': ubicacionLetra,
        'ubicacionNumero': ubicacionNumero,
      },
    );

    return InventarioItem.fromJson(response as Map<String, dynamic>);
  }
}

class InventarioItem {
  final int idInventario;
  final int? idProducto;
  final String codigo;
  final String codigoLote;
  final String nombre;
  final String categoria;
  final String unidad;
  final int stockActual;
  final double precioVenta;
  final String ubicacionLetra;
  final int? ubicacionNumero;
  final String ubicacionEstante;
  final bool inventarioActivo;
  final bool productoActivo;
  final DateTime? fechaCaducidad;

  const InventarioItem({
    required this.idInventario,
    required this.idProducto,
    required this.codigo,
    required this.codigoLote,
    required this.nombre,
    required this.categoria,
    required this.unidad,
    required this.stockActual,
    required this.precioVenta,
    required this.ubicacionLetra,
    required this.ubicacionNumero,
    required this.ubicacionEstante,
    required this.inventarioActivo,
    required this.productoActivo,
    required this.fechaCaducidad,
  });

  factory InventarioItem.fromJson(Map<String, dynamic> map) {
    return InventarioItem(
      idInventario: _asInt(map['idInventario']),
      idProducto: _asNullableInt(map['idProducto']),
      codigo: map['codigoBarras']?.toString() ??
          map['codigo']?.toString() ??
          map['clave']?.toString() ??
          '',
      codigoLote: map['codigoLote']?.toString() ?? '',
      nombre: map['nombre']?.toString() ?? 'Producto sin nombre',
      categoria:
          map['categoria']?.toString() ?? map['tipo']?.toString() ?? 'General',
      unidad: map['presentacion']?.toString() ??
          map['unidad']?.toString() ??
          map['unidadMedida']?.toString() ??
          '',
      stockActual: _asInt(map['stockActual']),
      precioVenta: _asDouble(map['precioVenta']),
      ubicacionLetra: map['ubicacionLetra']?.toString() ?? '',
      ubicacionNumero: _asNullableInt(map['ubicacionNumero']),
      ubicacionEstante: map['ubicacionEstante']?.toString() ?? '',
      inventarioActivo: _asBool(map['inventarioActivo']),
      productoActivo: _asBool(map['productoActivo']),
      fechaCaducidad:
          DateTime.tryParse(map['fechaCaducidad']?.toString() ?? ''),
    );
  }

  String get codigoVisible {
    if (codigo.isNotEmpty) {
      return codigo;
    }
    if (codigoLote.isNotEmpty) {
      return codigoLote;
    }
    return '#$idInventario';
  }

  String get ubicacionVisible {
    if (ubicacionEstante.trim().isNotEmpty) {
      return ubicacionEstante;
    }
    if (ubicacionLetra.trim().isNotEmpty && ubicacionNumero != null) {
      return '$ubicacionLetra$ubicacionNumero';
    }
    return '-';
  }

  EstadoStockInventario get estadoStock {
    if (stockActual <= 0) {
      return EstadoStockInventario.agotado;
    }
    if (stockActual <= 15) {
      return EstadoStockInventario.stockBajo;
    }
    return EstadoStockInventario.enExistencia;
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _asNullableInt(Object? value) {
    if (value == null) return null;
    return _asInt(value);
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

enum EstadoStockInventario {
  enExistencia,
  stockBajo,
  agotado,
}
