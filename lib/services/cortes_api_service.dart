import 'api_client.dart';
import 'caja_api_service.dart';

class CorteResumen {
  final int idCorte;
  final String estado;
  final DateTime? fechaApertura;
  final DateTime? fechaCierre;
  final int? usuarioAbre;
  final int? usuarioCierra;
  final String usuarioAbreNombre;
  final String usuarioCierraNombre;
  final double efectivoInicial;
  final double electronicoInicial;
  final double efectivoContado;
  final double electronicoContado;
  final double ventasEfectivo;
  final double ventasElectronico;
  final double entradasEfectivo;
  final double entradasElectronico;
  final double otrosIngresos;
  final double salidasEfectivo;
  final double salidasElectronico;
  final double salidas;
  final double efectivoEsperado;
  final double electronicoEsperado;
  final double totalEsperado;
  final double diferenciaEfectivo;
  final double diferenciaElectronico;
  final String observacionesCorte;

  const CorteResumen({
    required this.idCorte,
    required this.estado,
    required this.fechaApertura,
    required this.fechaCierre,
    required this.usuarioAbre,
    required this.usuarioCierra,
    required this.usuarioAbreNombre,
    required this.usuarioCierraNombre,
    required this.efectivoInicial,
    required this.electronicoInicial,
    required this.efectivoContado,
    required this.electronicoContado,
    required this.ventasEfectivo,
    required this.ventasElectronico,
    required this.entradasEfectivo,
    required this.entradasElectronico,
    required this.otrosIngresos,
    required this.salidasEfectivo,
    required this.salidasElectronico,
    required this.salidas,
    required this.efectivoEsperado,
    required this.electronicoEsperado,
    required this.totalEsperado,
    required this.diferenciaEfectivo,
    required this.diferenciaElectronico,
    required this.observacionesCorte,
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
    final efectivoContado = _asDoubleAny(map, [
      'efectivoContado',
      'efectivoFinal',
    ]);
    final electronicoContado = _asDoubleAny(map, [
      'electronicoContado',
      'electronicoFinal',
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
    final entradasEfectivo = _asDoubleAny(map, [
      'entradasEfectivo',
    ]);
    final entradasElectronico = _asDoubleAny(map, [
      'entradasElectronico',
    ]);
    final otrosIngresos = _asDoubleAny(map, [
      'otrosIngresos',
      'entradas',
      'entradasEfectivo',
    ]);
    final salidasEfectivo = _asDoubleAny(map, [
      'salidasEfectivo',
      'retirosEfectivo',
      'egresosEfectivo',
    ]);
    final salidasElectronico = _asDoubleAny(map, [
      'salidasElectronico',
      'retirosElectronico',
      'egresosElectronico',
    ]);
    final salidasRegistradas = _asDoubleAny(map, [
      'salidas',
      'retiros',
      'egresos',
    ]);
    final salidas = salidasRegistradas == 0
        ? salidasEfectivo + salidasElectronico
        : salidasRegistradas;
    final salidasEfectivoFinal = salidasEfectivo == 0 && salidasElectronico == 0
        ? salidas
        : salidasEfectivo;
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
    final diferenciaEfectivo = _asDoubleAny(map, [
      'diferenciaEfectivoCalculada',
      'diferenciaEfectivo',
    ]);
    final diferenciaElectronico = _asDoubleAny(map, [
      'diferenciaElectronicoCalculada',
      'diferenciaElectronico',
    ]);

    return CorteResumen(
      idCorte: _asIntAny(map, ['idCorte']),
      estado: _asStringAny(map, ['estado', 'estatus']),
      fechaApertura: _asDateAny(map, ['fechaApertura', 'apertura']),
      fechaCierre: _asDateAny(map, ['fechaCierre', 'cierre']),
      usuarioAbre: _asNullableIntAny(map, ['usuarioAbre']),
      usuarioCierra: _asNullableIntAny(map, ['usuarioCierra']),
      usuarioAbreNombre: _asStringAny(map, ['usuarioAbreNombre']),
      usuarioCierraNombre: _asStringAny(map, ['usuarioCierraNombre']),
      efectivoInicial: efectivoInicial,
      electronicoInicial: electronicoInicial,
      efectivoContado: efectivoContado,
      electronicoContado: electronicoContado,
      ventasEfectivo: ventasEfectivo,
      ventasElectronico: ventasElectronico,
      entradasEfectivo: entradasEfectivo,
      entradasElectronico: entradasElectronico,
      otrosIngresos: otrosIngresos,
      salidasEfectivo: salidasEfectivoFinal,
      salidasElectronico: salidasElectronico,
      salidas: salidas,
      efectivoEsperado: efectivoEsperado == 0
          ? efectivoInicial +
              ventasEfectivo +
              otrosIngresos -
              salidasEfectivoFinal
          : efectivoEsperado,
      electronicoEsperado: electronicoEsperado == 0
          ? electronicoInicial + ventasElectronico - salidasElectronico
          : electronicoEsperado,
      totalEsperado: totalEsperado == 0
          ? efectivoInicial +
              electronicoInicial +
              ventasEfectivo +
              ventasElectronico +
              otrosIngresos -
              salidas
          : totalEsperado,
      diferenciaEfectivo: diferenciaEfectivo,
      diferenciaElectronico: diferenciaElectronico,
      observacionesCorte: _asStringAny(map, ['observacionesCorte']),
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

  static int? _asNullableIntAny(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      final parsed = int.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return null;
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

class CorteDetalle extends CorteResumen {
  final TotalesMovimientosCorte totalesMovimientos;
  final List<MovimientoCaja> movimientos;

  const CorteDetalle({
    required super.idCorte,
    required super.estado,
    required super.fechaApertura,
    required super.fechaCierre,
    required super.usuarioAbre,
    required super.usuarioCierra,
    required super.usuarioAbreNombre,
    required super.usuarioCierraNombre,
    required super.efectivoInicial,
    required super.electronicoInicial,
    required super.efectivoContado,
    required super.electronicoContado,
    required super.ventasEfectivo,
    required super.ventasElectronico,
    required super.entradasEfectivo,
    required super.entradasElectronico,
    required super.otrosIngresos,
    required super.salidasEfectivo,
    required super.salidasElectronico,
    required super.salidas,
    required super.efectivoEsperado,
    required super.electronicoEsperado,
    required super.totalEsperado,
    required super.diferenciaEfectivo,
    required super.diferenciaElectronico,
    required super.observacionesCorte,
    required this.totalesMovimientos,
    required this.movimientos,
  });

  factory CorteDetalle.fromJson(Map<String, dynamic> map) {
    final base = CorteResumen.fromJson(map);
    final movimientos = (map['movimientos'] as List<dynamic>? ?? [])
        .map((item) => MovimientoCaja.fromJson(item as Map<String, dynamic>))
        .toList();

    return CorteDetalle(
      idCorte: base.idCorte,
      estado: base.estado,
      fechaApertura: base.fechaApertura,
      fechaCierre: base.fechaCierre,
      usuarioAbre: base.usuarioAbre,
      usuarioCierra: base.usuarioCierra,
      usuarioAbreNombre: base.usuarioAbreNombre,
      usuarioCierraNombre: base.usuarioCierraNombre,
      efectivoInicial: base.efectivoInicial,
      electronicoInicial: base.electronicoInicial,
      efectivoContado: base.efectivoContado,
      electronicoContado: base.electronicoContado,
      ventasEfectivo: base.ventasEfectivo,
      ventasElectronico: base.ventasElectronico,
      entradasEfectivo: base.entradasEfectivo,
      entradasElectronico: base.entradasElectronico,
      otrosIngresos: base.otrosIngresos,
      salidasEfectivo: base.salidasEfectivo,
      salidasElectronico: base.salidasElectronico,
      salidas: base.salidas,
      efectivoEsperado: base.efectivoEsperado,
      electronicoEsperado: base.electronicoEsperado,
      totalEsperado: base.totalEsperado,
      diferenciaEfectivo: base.diferenciaEfectivo,
      diferenciaElectronico: base.diferenciaElectronico,
      observacionesCorte: base.observacionesCorte,
      totalesMovimientos: TotalesMovimientosCorte.fromJson(
        map['totalesMovimientos'] as Map<String, dynamic>? ?? {},
      ),
      movimientos: movimientos,
    );
  }
}

class TotalesMovimientosCorte {
  final double entradasEfectivo;
  final double salidasEfectivo;
  final double entradasElectronico;
  final double salidasElectronico;
  final double entradas;
  final double salidas;
  final int totalMovimientos;

  const TotalesMovimientosCorte({
    required this.entradasEfectivo,
    required this.salidasEfectivo,
    required this.entradasElectronico,
    required this.salidasElectronico,
    required this.entradas,
    required this.salidas,
    required this.totalMovimientos,
  });

  factory TotalesMovimientosCorte.fromJson(Map<String, dynamic> map) {
    return TotalesMovimientosCorte(
      entradasEfectivo: CorteResumen._asDoubleAny(map, ['entradasEfectivo']),
      salidasEfectivo: CorteResumen._asDoubleAny(map, ['salidasEfectivo']),
      entradasElectronico:
          CorteResumen._asDoubleAny(map, ['entradasElectronico']),
      salidasElectronico:
          CorteResumen._asDoubleAny(map, ['salidasElectronico']),
      entradas: CorteResumen._asDoubleAny(map, ['entradas']),
      salidas: CorteResumen._asDoubleAny(map, ['salidas']),
      totalMovimientos: CorteResumen._asIntAny(map, ['totalMovimientos']),
    );
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

  Future<List<CorteResumen>> listarResumen({
    String? busqueda,
    String? estado,
    String? fechaAperturaDesde,
    String? fechaAperturaHasta,
    String? fechaCierreDesde,
    String? fechaCierreHasta,
    int limite = 100,
  }) async {
    final params = <String, String>{
      'limite': limite.toString(),
      if (busqueda != null && busqueda.trim().isNotEmpty)
        'busqueda': busqueda.trim(),
      if (estado != null && estado.isNotEmpty) 'estado': estado,
      if (fechaAperturaDesde != null && fechaAperturaDesde.isNotEmpty)
        'fechaAperturaDesde': fechaAperturaDesde,
      if (fechaAperturaHasta != null && fechaAperturaHasta.isNotEmpty)
        'fechaAperturaHasta': fechaAperturaHasta,
      if (fechaCierreDesde != null && fechaCierreDesde.isNotEmpty)
        'fechaCierreDesde': fechaCierreDesde,
      if (fechaCierreHasta != null && fechaCierreHasta.isNotEmpty)
        'fechaCierreHasta': fechaCierreHasta,
    };
    final query = Uri(queryParameters: params).query;
    final response = await _apiClient.get('/cortes/resumen?$query');
    final list = response as List<dynamic>;
    return list
        .map((item) => CorteResumen.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<CorteDetalle> obtenerDetalle(
    int idCorte, {
    int limiteMovimientos = 1000,
  }) async {
    final response = await _apiClient.get(
      '/cortes/$idCorte?limiteMovimientos=$limiteMovimientos',
    );
    return CorteDetalle.fromJson(response as Map<String, dynamic>);
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
