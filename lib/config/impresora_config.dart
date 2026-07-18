class ImpresoraConfig {
  ImpresoraConfig._();

  /// Dirección IP que aparece en la autoprueba de la impresora.
  static const String ip = '192.168.1.100';

  /// Puerto RAW utilizado para recibir comandos ESC/POS.
  static const int puerto = 9100;

  /// Tiempo máximo para establecer la conexión o enviar el ticket.
  static const Duration tiempoEspera = Duration(seconds: 5);
}