class Usuario {
  final int? id;
  final String nombre;
  final String correo;
  final String rol;

  Usuario({
    this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'correo': correo,
      'rol': rol,
    };
  }

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      correo: map['correo'] as String,
      rol: map['rol'] as String,
    );
  }
}
