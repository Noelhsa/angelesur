class ConfigMoneda {
  static String formato(double cantidad, {bool decimales = true}) {
    if (decimales) {
      return '\$${cantidad.toStringAsFixed(2)}';
    }

    return '\$${cantidad.toStringAsFixed(0)}';
  }
}