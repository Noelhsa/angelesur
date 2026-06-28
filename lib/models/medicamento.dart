class Medicamento {
  final int id;
  final String nombre;
  final String detalle;
  final String categoria;
  final double precio;
  final int stock;
  final String? imagenAsset;

  const Medicamento({
    required this.id,
    required this.nombre,
    required this.detalle,
    required this.categoria,
    required this.precio,
    required this.stock,
    this.imagenAsset,
  });
}