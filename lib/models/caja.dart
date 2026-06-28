class Caja {
  final int? id;
  final String fecha;
  final double saldoInicial;
  final double ingresos;
  final double egresos;
  final double saldoFinal;
  final String estado; // 'abierta' o 'cerrada'

  Caja({
    this.id,
    required this.fecha,
    required this.saldoInicial,
    required this.ingresos,
    required this.egresos,
    required this.saldoFinal,
    required this.estado,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha': fecha,
      'saldo_inicial': saldoInicial,
      'ingresos': ingresos,
      'egresos': egresos,
      'saldo_final': saldoFinal,
      'estado': estado,
    };
  }

  factory Caja.fromMap(Map<String, dynamic> map) {
    return Caja(
      id: map['id'] as int?,
      fecha: map['fecha'] as String,
      saldoInicial: (map['saldo_inicial'] as num).toDouble(),
      ingresos: (map['ingresos'] as num).toDouble(),
      egresos: (map['egresos'] as num).toDouble(),
      saldoFinal: (map['saldo_final'] as num).toDouble(),
      estado: map['estado'] as String,
    );
  }
}
