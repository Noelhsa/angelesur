class Medicamento {
  final int id;
  final int? idProducto;
  final String nombre;
  final String detalle;
  final String categoria;
  final double precio;
  final int stock;
  final String? imagenAsset;

  const Medicamento({
    required this.id,
    this.idProducto,
    required this.nombre,
    required this.detalle,
    required this.categoria,
    required this.precio,
    required this.stock,
    this.imagenAsset,
  });

  factory Medicamento.fromInventarioJson(Map<String, dynamic> map) {
    final fechaCaducidad = map['fechaCaducidad'];
    final codigoLote = map['codigoLote']?.toString() ?? 'SIN_LOTE';

    return Medicamento(
      id: _asInt(map['idInventario']),
      idProducto: _asNullableInt(map['idProducto']),
      nombre: map['nombre']?.toString() ?? 'Producto sin nombre',
      detalle: fechaCaducidad == null
          ? 'Lote $codigoLote'
          : 'Lote $codigoLote - Cad. $fechaCaducidad',
      categoria:
          map['categoria']?.toString() ?? map['tipo']?.toString() ?? 'General',
      precio: _asDouble(map['precioVenta']),
      stock: _asInt(map['stockActual']),
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

  static int? _asNullableInt(Object? value) {
    if (value == null) {
      return null;
    }
    return _asInt(value);
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
