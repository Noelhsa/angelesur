import '../models/caja.dart';

class CajaRepository {
  Future<List<Caja>> obtenerRegistrosCaja() async {
    // Consulta a la base de datos
    return [];
  }

  Future<Caja?> obtenerCajaActiva() async {
    // Consulta a la base de datos
    return null;
  }

  Future<int> abrirCaja(Caja caja) async {
    // Inserción en la base de datos
    return 0;
  }

  Future<int> cerrarCaja(Caja caja) async {
    // Actualización en la base de datos
    return 0;
  }
}
