import '../models/usuario.dart';

class UsuarioRepository {
  Future<List<Usuario>> obtenerUsuarios() async {
    // Consulta a la base de datos
    return [];
  }

  Future<Usuario?> obtenerUsuarioPorId(int id) async {
    // Consulta a la base de datos
    return null;
  }

  Future<int> insertarUsuario(Usuario usuario) async {
    // Inserción en la base de datos
    return 0;
  }

  Future<int> actualizarUsuario(Usuario usuario) async {
    // Actualización en la base de datos
    return 0;
  }

  Future<int> eliminarUsuario(int id) async {
    // Eliminación en la base de datos
    return 0;
  }
}
