import '../models/respaldo.dart';
import '../repositories/respaldo_repository.dart';

class RespaldoService {
  final RespaldoRepository _repository = RespaldoRepository();

  Future<List<Respaldo>> listarRespaldos() {
    return _repository.obtenerRespaldos();
  }

  Future<bool> crearRespaldo(Respaldo respaldo) async {
    final resultado = await _repository.registrarRespaldo(respaldo);
    return resultado > 0;
  }

  Future<bool> eliminarRespaldo(int id) async {
    final resultado = await _repository.eliminarRespaldo(id);
    return resultado > 0;
  }
}
