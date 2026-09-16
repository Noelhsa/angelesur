import 'api_client.dart';

class RespaldosApiService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> ejecutar({
    required String username,
    required String password,
    required String ruta,
    required bool restaurar,
  }) async {
    final result =
        await _api.post('/respaldos/${restaurar ? 'restaurar' : 'crear'}', {
      'username': username,
      'password': password,
      'ruta': ruta,
      'confirmar': restaurar,
    });
    return Map<String, dynamic>.from(result as Map);
  }
}
