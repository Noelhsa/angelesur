class DosisMedicamento {
  static const sinUnidad = 'Sin unidad';

  final String? original;
  final String cantidad;
  final String unidad;

  const DosisMedicamento._(this.original, this.cantidad, this.unidad);

  factory DosisMedicamento.desdeTexto(String? texto) {
    final limpio = texto?.trim() ?? '';
    if (limpio.isEmpty) {
      return DosisMedicamento._(texto, '', 'mg');
    }
    final partes =
        RegExp(r'^(\d+(?:[.,]\d+)?)\s*([^\d\s].*)$').firstMatch(limpio);
    if (partes == null) {
      return DosisMedicamento._(texto, limpio, sinUnidad);
    }
    final unidad = partes.group(2)!.trim();
    const unidades = [
      'mg',
      'g',
      'mcg',
      'ml',
      'l',
      'UI',
      '%',
      'gotas',
      'tabletas',
      'capsulas'
    ];
    final normalizada = unidades.firstWhere(
      (valor) => valor.toLowerCase() == unidad.toLowerCase(),
      orElse: () => unidad,
    );
    return DosisMedicamento._(texto, partes.group(1)!, normalizada);
  }

  String? guardar(String nuevaCantidad, String nuevaUnidad) {
    // Una edicion de otro campo no debe reescribir la dosis almacenada.
    if (nuevaCantidad == cantidad && nuevaUnidad == unidad) return original;
    final valor = nuevaCantidad.trim();
    if (valor.isEmpty) return null;
    return nuevaUnidad == sinUnidad ? valor : '$valor $nuevaUnidad';
  }
}
