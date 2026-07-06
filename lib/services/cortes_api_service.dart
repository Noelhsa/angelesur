import 'api_client.dart';

class CorteResumen {
  final int idCorte;
  final String estado;
  final DateTime? fechaApertura;
  final DateTime? fechaCierre;
  final double efectivoInicial;
  final double electronicoInicial;
  final double ventasEfectivo;
  final double ventasElectronico;
  final double otrosIngresos;
  final double salidas;
  final double efectivoEsperado;
  final double electronicoEsperado;
  final double totalEsperado;

  const CorteResumen({
    required this.idCorte,
    required this.estado,
    required this.fechaApertura,
    required this.fechaCierre,
    required this.efectivoInicial,
    required this.electronicoInicial,
    required this.ventasEfectivo,
    required this.ventasElectronico,
    required this.otrosIngresos,
    required this.salidas,
    required this.efectivoEsperado,
    required this.electronicoEsperado,
    required this.totalEsperado,
  });

  factory CorteResumen.fromJson(Map<String, dynamic> map) {
    final efectivoInicial = _asDoubleAny(map, [
      'efectivoInicial',
      'fondoInicial',
      'saldoInicialEfectivo',
    ]);
    final electronicoInicial = _asDoubleAny(map, [
      'electronicoInicial',
      'saldoInicialElectronico',
    ]);
    final ventasEfectivo = _asDoubleAny(map, [
      'ventasEfectivo',
      'totalVentasEfectivo',
      'ingresosEfectivo',
    ]);
    final ventasElectronico = _asDoubleAny(map, [
      'ventasElectronico',
      'ventasTarjeta',
      'totalVentasElectronico',
      'ingresosElectronico',
    ]);
    final otrosIngresos = _asDoubleAny(map, [
      'otrosIngresos',
      'entradas',
      'entradasEfectivo',
    ]);
    final salidas = _asDoubleAny(map, [
      'salidas',
      'retiros',
      'egresos',
      'salidasEfectivo',
    ]);
    final efectivoEsperado = _asDoubleAny(map, [
      'efectivoEsperado',
      'saldoEfectivo',
      'balanceEfectivo',
      'totalEfectivo',
    ]);
    final electronicoEsperado = _asDoubleAny(map, [
      'electronicoEsperado',
      'saldoElectronico',
      'balanceElectronico',
      'totalElectronico',
    ]);
    final totalEsperado = _asDoubleAny(map, [
      'totalEsperado',
      'total',
      'balanceTotal',
    ]);

    return CorteResumen(
      idCorte: _asIntAny(map, ['idCorte']),
      estado: _asStringAny(map, ['estado', 'estatus']),
      fechaApertura: _asDateAny(map, ['fechaApertura', 'apertura']),
      fechaCierre: _asDateAny(map, ['fechaCierre', 'cierre']),
      efectivoInicial: efectivoInicial,
      electronicoInicial: electronicoInicial,
      ventasEfectivo: ventasEfectivo,
      ventasElectronico: ventasElectronico,
      otrosIngresos: otrosIngresos,
      salidas: salidas,
      efectivoEsperado: efectivoEsperado == 0
          ? efectivoInicial + ventasEfectivo + otrosIngresos - salidas
          : efectivoEsperado,
      electronicoEsperado: electronicoEsperado == 0
          ? electronicoInicial + ventasElectronico
          : electronicoEsperado,
      totalEsperado: totalEsperado == 0
          ? efectivoInicial +
              electronicoInicial +
              ventasEfectivo +
              ventasElectronico +
              otrosIngresos -
              salidas
          : totalEsperado,
    );
  }

  static int _asIntAny(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      final parsed = int.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return 0;
  }

  static double _asDoubleAny(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is double) return value;
      if (value is num) return value.toDouble();
      final parsed = double.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return 0;
  }

  static String _asStringAny(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value != null) return value.toString();
    }
    return '';
  }

  static DateTime? _asDateAny(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final parsed = DateTime.tryParse(map[key]?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return null;
  }
}

class CortesApiService {
  final ApiClient _apiClient;

  CortesApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<CorteResumen?> obtenerActual() async {
    final response = await _apiClient.get('/cortes/actual');
    if (response == null) return null;
    return CorteResumen.fromJson(response as Map<String, dynamic>);
  }

  Future<void> abrirCorte({
    required int idUsuario,
    required double efectivoInicial,
    required double electronicoInicial,
    String? observaciones,
  }) async {
    await _apiClient.post('/cortes/abrir', {
      'idUsuario': idUsuario,
      'efectivoInicial': efectivoInicial,
      'electronicoInicial': electronicoInicial,
      'observaciones': observaciones,
    });
  }

  Future<void> cerrarCorte({
    required int idUsuario,
    required double efectivoContado,
    required double electronicoContado,
    String? observaciones,
  }) async {
    await _apiClient.post('/cortes/cerrar', {
      'idUsuario': idUsuario,
      'efectivoContado': efectivoContado,
      'electronicoContado': electronicoContado,
      'observaciones': observaciones,
    });
  }
}
