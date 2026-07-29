import '../models/medicamento.dart';
import 'api_client.dart';

class InventarioApiService {
  final ApiClient _apiClient;

  InventarioApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<List<Medicamento>> listarDisponibles({
    String? busqueda,
    int limite = 500,
  }) async {
    final params = <String>[
      'limite=$limite',
      if (busqueda != null && busqueda.trim().isNotEmpty)
        'busqueda=${Uri.encodeQueryComponent(busqueda.trim())}',
    ];
    final response =
        await _apiClient.get('/inventario/disponible?${params.join('&')}');
    final items = response as List<dynamic>;

    return items
        .map((item) =>
            Medicamento.fromInventarioJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Medicamento>> buscarDisponiblesPorCodigoBarras(
    String codigoBarras,
  ) async {
    final codigo = _normalizarCodigoBarras(codigoBarras);
    if (codigo.isEmpty) {
      return [];
    }

    final candidatos = await listarDisponibles(
      busqueda: codigoBarras,
      limite: 50,
    );

    return candidatos.where((medicamento) {
      return _normalizarCodigoBarras(medicamento.codigoBarras) == codigo;
    }).toList();
  }

  Future<InventarioPaginado> listarActualPaginado({
    String? busqueda,
    String? categoria,
    EstadoStockInventario? estadoStock,
    bool soloActivos = true,
    int pagina = 1,
    int limite = 25,
  }) async {
    final params = <String>[
      'soloActivos=$soloActivos',
      'pagina=$pagina',
      'limite=$limite',
    ];

    if (busqueda != null && busqueda.trim().isNotEmpty) {
      params.add('busqueda=${Uri.encodeQueryComponent(busqueda.trim())}');
    }
    if (categoria != null && categoria.trim().isNotEmpty) {
      params.add('categoria=${Uri.encodeQueryComponent(categoria.trim())}');
    }
    if (estadoStock != null) {
      params.add('estadoStock=${_estadoStockApi(estadoStock)}');
    }

    final response =
        await _apiClient.get('/inventario/actual?${params.join('&')}');
    return InventarioPaginado.fromResponse(response);
  }

  Future<List<InventarioItem>> listarActual({
    String? busqueda,
    String? categoria,
    EstadoStockInventario? estadoStock,
    bool soloActivos = true,
    int limite = 500,
  }) async {
    final items = <InventarioItem>[];
    var pagina = 1;
    const limitePagina = 100;

    while (items.length < limite) {
      final resultado = await listarActualPaginado(
        busqueda: busqueda,
        categoria: categoria,
        estadoStock: estadoStock,
        soloActivos: soloActivos,
        pagina: pagina,
        limite: limitePagina,
      );
      items.addAll(resultado.items);

      if (!resultado.haySiguiente || resultado.items.isEmpty) {
        break;
      }
      pagina += 1;
    }

    return items.take(limite).toList();
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

  Future<InventarioItem> actualizarDatosLote({
    required int idInventario,
    required String codigoLote,
    required String? fechaCaducidad,
    required double precioVenta,
    required String? ubicacionLetra,
    required int? ubicacionNumero,
  }) async {
    final response = await _apiClient.patch(
      '/inventario/$idInventario/datos-lote',
      {
        'codigoLote': codigoLote,
        'fechaCaducidad': fechaCaducidad,
        'precioVenta': precioVenta,
        'ubicacionLetra': ubicacionLetra,
        'ubicacionNumero': ubicacionNumero,
      },
    );

    return InventarioItem.fromJson(response as Map<String, dynamic>);
  }

  Future<UbicacionInventarioSugerida> obtenerUbicacionSugerida(
    int idProducto,
  ) async {
    final response = await _apiClient.get(
      '/inventario/ubicacion-sugerida?idProducto=$idProducto',
    );

    return UbicacionInventarioSugerida.fromJson(
      response as Map<String, dynamic>,
    );
  }
}

class UbicacionInventarioSugerida {
  final int idProducto;
  final String ubicacionLetra;
  final int? ubicacionNumero;
  final String ubicacionEstante;

  const UbicacionInventarioSugerida({
    required this.idProducto,
    required this.ubicacionLetra,
    required this.ubicacionNumero,
    required this.ubicacionEstante,
  });

  factory UbicacionInventarioSugerida.fromJson(Map<String, dynamic> map) {
    return UbicacionInventarioSugerida(
      idProducto: InventarioItem._asInt(map['idProducto']),
      ubicacionLetra: map['ubicacionLetra']?.toString() ?? '',
      ubicacionNumero: InventarioItem._asNullableInt(map['ubicacionNumero']),
      ubicacionEstante: map['ubicacionEstante']?.toString() ?? '',
    );
  }

  bool get tieneUbicacion =>
      ubicacionLetra.trim().isNotEmpty && ubicacionNumero != null;
}

class InventarioPaginado {
  final List<InventarioItem> items;
  final int pagina;
  final int limite;
  final int total;
  final int totalPaginas;
  final bool hayAnterior;
  final bool haySiguiente;

  const InventarioPaginado({
    required this.items,
    required this.pagina,
    required this.limite,
    required this.total,
    required this.totalPaginas,
    required this.hayAnterior,
    required this.haySiguiente,
  });

  factory InventarioPaginado.fromResponse(dynamic response) {
    if (response is List<dynamic>) {
      final items = response
          .map((item) => InventarioItem.fromJson(item as Map<String, dynamic>))
          .toList();
      return InventarioPaginado(
        items: items,
        pagina: 1,
        limite: items.length,
        total: items.length,
        totalPaginas: 1,
        hayAnterior: false,
        haySiguiente: false,
      );
    }

    final map = response as Map<String, dynamic>;
    final items = (map['items'] as List<dynamic>? ?? [])
        .map((item) => InventarioItem.fromJson(item as Map<String, dynamic>))
        .toList();
    return InventarioPaginado(
      items: items,
      pagina: InventarioItem._asInt(map['pagina']),
      limite: InventarioItem._asInt(map['limite']),
      total: InventarioItem._asInt(map['total']),
      totalPaginas: InventarioItem._asInt(map['totalPaginas']),
      hayAnterior: map['hayAnterior'] == true,
      haySiguiente: map['haySiguiente'] == true,
    );
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

String _estadoStockApi(EstadoStockInventario estado) {
  return switch (estado) {
    EstadoStockInventario.enExistencia => 'EN_EXISTENCIA',
    EstadoStockInventario.stockBajo => 'STOCK_BAJO',
    EstadoStockInventario.agotado => 'AGOTADO',
  };
}

String _normalizarCodigoBarras(String value) {
  return value.trim().replaceAll(RegExp(r'\s+'), '').toLowerCase();
}
