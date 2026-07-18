import 'dart:io';

import 'package:angelesur/config/impresora_config.dart';
import 'package:angelesur/services/ticket_service.dart';

Future<void> main(List<String> argumentos) async {
  /*
   * Puedes proporcionar una IP y un puerto desde la terminal.
   *
   * Si no proporcionas nada, se utilizarán los valores definidos
   * en ImpresoraConfig.
   */
  final String ip = argumentos.isNotEmpty
      ? argumentos[0]
      : ImpresoraConfig.ip;

  final int? puerto = argumentos.length > 1
      ? int.tryParse(argumentos[1])
      : ImpresoraConfig.puerto;

  if (puerto == null || puerto < 1 || puerto > 65535) {
    stderr.writeln(
      'El puerto proporcionado no es valido.',
    );

    stderr.writeln(
      'Uso:',
    );

    stderr.writeln(
      'dart run bin/imprimir_ticket_prueba.dart '
      '[IP] [PUERTO]',
    );

    exitCode = 64;
    return;
  }

  final TicketService ticketService = TicketService(
    ip: ip,
    puerto: puerto,
  );

  stdout.writeln(
    'Conectando con la impresora $ip:$puerto...',
  );

  try {
    await ticketService.imprimirTicketPrueba();

    stdout.writeln(
      'Ticket enviado correctamente.',
    );

    stdout.writeln(
      'Revisa que la impresora haya impreso y cortado el papel.',
    );
  } on TicketServiceException catch (error) {
    stderr.writeln(
      'Error de impresion: ${error.mensaje}',
    );

    exitCode = 1;
  } catch (error) {
    stderr.writeln(
      'Error no controlado: $error',
    );

    exitCode = 1;
  }
}