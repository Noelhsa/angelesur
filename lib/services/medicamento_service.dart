import '../models/medicamento.dart';
import '../repositories/medicamento_repository.dart';

class MedicamentoService {
  final MedicamentoRepository _repository = MedicamentoRepository();

  Future<List<Medicamento>> listarMedicamentos() {
    return _repository.obtenerMedicamentos();
  }

  Future<Medicamento?> buscarMedicamento(int id) {
    return _repository.obtenerMedicamentoPorId(id);
  }

  Future<bool> registrarMedicamento(Medicamento medicamento) async {
    final resultado = await _repository.insertarMedicamento(medicamento);
    return resultado > 0;
  }

  Future<bool> modificarMedicamento(Medicamento medicamento) async {
    final resultado = await _repository.actualizarMedicamento(medicamento);
    return resultado > 0;
  }

  Future<bool> borrarMedicamento(int id) async {
    final resultado = await _repository.eliminarMedicamento(id);
    return resultado > 0;
  }
}
