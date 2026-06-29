import '../models/usuario.dart';
import 'api_client.dart';

class AuthApiService {
  final ApiClient _apiClient;

  AuthApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<Usuario> login({
    required String username,
    required String password,
  }) async {
    final response = await _apiClient.post('/auth/login', {
      'username': username,
      'password': password,
    });

    return Usuario.fromMap(response as Map<String, dynamic>);
  }
}
