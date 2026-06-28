import '../models/medicamento.dart';

class MedicamentoRepository {
  Future<List<Medicamento>> obtenerMedicamentos() async {
    // Consulta a la base de datos
    return [];
  }

  Future<Medicamento?> obtenerMedicamentoPorId(int id) async {
    // Consulta a la base de datos
    return null;
  }

  Future<int> insertarMedicamento(Medicamento medicamento) async {
    // Inserción en la base de datos
    return 0;
  }

  Future<int> actualizarMedicamento(Medicamento medicamento) async {
    // Actualización en la base de datos
    return 0;
  }

  Future<int> eliminarMedicamento(int id) async {
    // Eliminación en la base de datos
    return 0;
  }
}
