import '../models/usuario.dart';
import 'api_client.dart';

class UsuariosApiService {
  final ApiClient _apiClient;

  UsuariosApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<List<Usuario>> listarUsuarios({
    bool incluirInactivos = true,
  }) async {
    final query = Uri(
      queryParameters: {
        'incluirInactivos': incluirInactivos.toString(),
      },
    ).query;
    final response = await _apiClient.get('/usuarios?$query');
    final items = response as List<dynamic>;

    return items
        .map((item) => Usuario.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<Usuario> crearUsuario({
    required String nombre,
    required String username,
    required String password,
    required String rol,
    String? telefono,
  }) async {
    final response = await _apiClient.post('/usuarios', {
      'nombre': nombre,
      'username': username,
      'password': password,
      'rol': rol,
      'telefono': telefono,
    });

    return Usuario.fromMap(response as Map<String, dynamic>);
  }

  Future<Usuario> actualizarUsuario({
    required int idUsuario,
    String? nombre,
    String? username,
    String? password,
    String? rol,
    String? telefono,
  }) async {
    final body = <String, dynamic>{
      if (nombre != null) 'nombre': nombre,
      if (username != null) 'username': username,
      if (password != null && password.isNotEmpty) 'password': password,
      if (rol != null) 'rol': rol,
      if (telefono != null) 'telefono': telefono,
    };
    final response = await _apiClient.patch('/usuarios/$idUsuario', body);

    return Usuario.fromMap(response as Map<String, dynamic>);
  }

  Future<Usuario> cambiarEstado({
    required int idUsuario,
    required bool activo,
  }) async {
    final response = await _apiClient.patch('/usuarios/$idUsuario/estado', {
      'activo': activo,
    });

    return Usuario.fromMap(response as Map<String, dynamic>);
  }
}
