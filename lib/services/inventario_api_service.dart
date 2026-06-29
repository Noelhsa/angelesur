import '../models/medicamento.dart';
import 'api_client.dart';

class InventarioApiService {
  final ApiClient _apiClient;

  InventarioApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<List<Medicamento>> listarDisponibles() async {
    final response = await _apiClient.get('/inventario/disponible');
    final items = response as List<dynamic>;

    return items
        .map((item) =>
            Medicamento.fromInventarioJson(item as Map<String, dynamic>))
        .toList();
  }
}
