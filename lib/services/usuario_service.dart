import '../models/usuario.dart';
import '../repositories/usuario_repository.dart';

class UsuarioService {
  final UsuarioRepository _repository = UsuarioRepository();

  Future<List<Usuario>> listarUsuarios() {
    return _repository.obtenerUsuarios();
  }

  Future<Usuario?> buscarUsuario(int id) {
    return _repository.obtenerUsuarioPorId(id);
  }

  Future<bool> registrarUsuario(Usuario usuario) async {
    final resultado = await _repository.insertarUsuario(usuario);
    return resultado > 0;
  }

  Future<bool> modificarUsuario(Usuario usuario) async {
    final resultado = await _repository.actualizarUsuario(usuario);
    return resultado > 0;
  }

  Future<bool> borrarUsuario(int id) async {
    final resultado = await _repository.eliminarUsuario(id);
    return resultado > 0;
  }
}
