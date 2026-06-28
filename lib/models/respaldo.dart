class Respaldo {
  final int? id;
  final String fecha;
  final String rutaArchivo;
  final String tamano;

  Respaldo({
    this.id,
    required this.fecha,
    required this.rutaArchivo,
    required this.tamano,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha': fecha,
      'ruta_archivo': rutaArchivo,
      'tamano': tamano,
    };
  }

  factory Respaldo.fromMap(Map<String, dynamic> map) {
    return Respaldo(
      id: map['id'] as int?,
      fecha: map['fecha'] as String,
      rutaArchivo: map['ruta_archivo'] as String,
      tamano: map['tamano'] as String,
    );
  }
}
