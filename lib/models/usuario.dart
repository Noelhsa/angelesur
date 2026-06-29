class Usuario {
  final int id;
  final String nombre;
  final String username;
  final String? telefono;
  final String rol;
  final bool activo;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.username,
    this.telefono,
    required this.rol,
    required this.activo,
  });

  Map<String, dynamic> toMap() {
    return {
      'idUsuario': id,
      'nombre': nombre,
      'username': username,
      'telefono': telefono,
      'rol': rol,
      'activo': activo,
    };
  }

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['idUsuario'] as int,
      nombre: map['nombre'] as String,
      username: map['username'] as String,
      telefono: map['telefono'] as String?,
      rol: map['rol'] as String,
      activo: map['activo'] == true || map['activo'] == 1,
    );
  }
}
