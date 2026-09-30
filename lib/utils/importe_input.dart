import 'package:flutter/services.dart';

/// Sin separadores de miles: coma y punto representan centavos.
double? leerImporte(String texto) {
  if (!RegExp(r'^\d+(?:[.,]\d{0,2})?$').hasMatch(texto)) return null;
  final valor = double.tryParse(texto.replaceAll(',', '.'));
  return valor != null && valor.isFinite ? valor : null;
}

class ImporteInputFormatter extends TextInputFormatter {
  const ImporteInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty || leerImporte(newValue.text) != null) {
      return newValue;
    }
    // Rechazar todo el cambio evita convertir texto pegado en otro monto.
    return oldValue;
  }
}
