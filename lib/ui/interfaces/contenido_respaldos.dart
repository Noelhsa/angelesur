import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/usuario.dart';
import '../../services/api_client.dart';
import '../../services/respaldos_api_service.dart';

class ContenidoRespaldos extends StatefulWidget {
  final Usuario usuario;
  final VoidCallback onRestaurado;
  final ValueChanged<bool> onOcupado;

  const ContenidoRespaldos({
    super.key,
    required this.usuario,
    required this.onRestaurado,
    required this.onOcupado,
  });

  @override
  State<ContenidoRespaldos> createState() => _ContenidoRespaldosState();
}

class _ContenidoRespaldosState extends State<ContenidoRespaldos> {
  final _api = RespaldosApiService();
  bool _ocupado = false;
  bool _error = false;
  String? _resultado;

  Future<String?> _confirmar(bool restaurar, String ruta) async {
    final controller = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(restaurar ? 'Restaurar respaldo' : 'Crear respaldo'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (restaurar) ...[
                      const Text(
                          'Se reemplazaran todos los datos actuales, incluidos los usuarios y sus contrasenas. Se guardara una copia previa y se cerrara tu sesion. Usa solamente archivos de confianza.'),
                      const SizedBox(height: 16),
                    ],
                    SelectableText(ruta),
                    const SizedBox(height: 20),
                    TextField(
                      controller: controller,
                      obscureText: true,
                      autofocus: true,
                      decoration: InputDecoration(
                          labelText: 'Contrasena de ${widget.usuario.username}',
                          border: const OutlineInputBorder()),
                    ),
                  ]),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  Navigator.pop(context, controller.text);
                }
              },
              child: Text(
                  restaurar ? 'Reemplazar y restaurar' : 'Guardar respaldo'),
            ),
          ],
        ),
      );
    } finally {
      // The dialog route finishes its closing animation after its result.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      controller.dispose();
    }
  }

  Future<void> _ejecutar(bool restaurar) async {
    if (_ocupado) return;
    setState(() {
      _ocupado = true;
      _resultado = null;
      _error = false;
    });
    widget.onOcupado(true);
    try {
      String? ruta;
      if (restaurar) {
        final seleccion = await FilePicker.platform.pickFiles(
          dialogTitle: 'Seleccionar respaldo',
          type: FileType.custom,
          allowedExtensions: ['sql'],
          lockParentWindow: true,
        );
        ruta = seleccion?.files.single.path;
      } else {
        final fecha = DateTime.now()
            .toIso8601String()
            .replaceAll(':', '-')
            .replaceAll('.', '-');
        ruta = await FilePicker.platform.saveFile(
          dialogTitle: 'Guardar respaldo',
          fileName: 'angelesur_$fecha.sql',
          type: FileType.custom,
          allowedExtensions: ['sql'],
          lockParentWindow: true,
        );
        if (ruta != null && !ruta.toLowerCase().endsWith('.sql')) {
          ruta = '$ruta.sql';
        }
      }
      if (ruta == null || !mounted) return;
      final password = await _confirmar(restaurar, ruta);
      if (password == null || !mounted) return;
      final resultado = await _api.ejecutar(
          username: widget.usuario.username,
          password: password,
          ruta: ruta,
          restaurar: restaurar);
      if (!mounted) return;
      if (restaurar) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Restauracion completada'),
            content: SelectableText(
                'Inicia sesion con un usuario del respaldo.\n\nCopia anterior:\n${resultado['respaldoPrevio']}'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Ir al inicio de sesion'))
            ],
          ),
        );
        if (mounted) widget.onRestaurado();
      } else {
        setState(() => _resultado = 'Respaldo guardado en:\n$ruta');
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = true;
          _resultado = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = true;
          _resultado =
              'No se pudo confirmar la operacion. Revisa la API antes de volver a intentarlo.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _ocupado = false);
        widget.onOcupado(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Respaldos',
            style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w900,
                color: Color(0xFF181A20))),
        const SizedBox(height: 28),
        Wrap(spacing: 16, runSpacing: 16, children: [
          ElevatedButton.icon(
            onPressed: _ocupado ? null : () => _ejecutar(false),
            icon: const Icon(Icons.save_alt),
            label: const Text('Crear respaldo'),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF58D000),
                foregroundColor: const Color(0xFF181A20),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18)),
          ),
          OutlinedButton.icon(
            onPressed: _ocupado ? null : () => _ejecutar(true),
            icon: const Icon(Icons.restore),
            label: const Text('Cargar respaldo'),
            style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF316EE9),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18)),
          ),
        ]),
        if (_ocupado) ...[
          const SizedBox(height: 28),
          const LinearProgressIndicator(),
          const SizedBox(height: 12),
          const Text('Operacion en curso. No cierres la aplicacion ni la API.'),
        ],
        if (_resultado != null) ...[
          const SizedBox(height: 28),
          Icon(_error ? Icons.error_outline : Icons.check_circle_outline,
              color: _error ? Colors.red.shade700 : Colors.green.shade800),
          const SizedBox(height: 8),
          SelectableText(_resultado!, style: const TextStyle(fontSize: 15)),
        ],
      ]),
    );
  }
}
