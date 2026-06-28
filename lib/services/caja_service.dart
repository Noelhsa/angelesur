import '../models/caja.dart';
import '../repositories/caja_repository.dart';

class CajaService {
  final CajaRepository _repository = CajaRepository();

  Future<List<Caja>> listarRegistrosCaja() {
    return _repository.obtenerRegistrosCaja();
  }

  Future<Caja?> obtenerCajaActiva() {
    return _repository.obtenerCajaActiva();
  }

  Future<bool> aperturaCaja(Caja caja) async {
    final resultado = await _repository.abrirCaja(caja);
    return resultado > 0;
  }

  Future<bool> cierreCaja(Caja caja) async {
    final resultado = await _repository.cerrarCaja(caja);
    return resultado > 0;
  }
}
