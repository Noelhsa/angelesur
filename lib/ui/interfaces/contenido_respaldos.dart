import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/usuario.dart';
import '../../services/api_client.dart';
import '../../services/respaldos_api_service.dart';

const Color _fondoPagina = Color(0xFFE2E2E2);
const Color _verdeOscuro = Color(0xFF397800);
const Color _verdePrincipal = Color(0xFF3A7704);
const Color _azulPrincipal = Color(0xFF0067D9);
const Color _textoPrincipal = Color(0xFF101828);
const Color _textoSecundario = Color(0xFF667085);
const Color _bordeSuave = Color(0xFFD9E6D3);
const Color _grisCampo = Color(0xFFF6F4F1);
const Color _rojoError = Color(0xFFE02020);

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
  final RespaldosApiService _api = RespaldosApiService();

  bool _ocupado = false;
  bool _error = false;
  String? _resultado;
  _UltimoRespaldo? _ultimoRespaldo;

  Future<String?> _confirmar(bool restaurar, String ruta) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DialogoConfirmarRespaldo(
        restaurar: restaurar,
        ruta: ruta,
        username: widget.usuario.username,
      ),
    );
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
        restaurar: restaurar,
      );

      if (!mounted) return;

      if (restaurar) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Restauración completada'),
            content: SelectableText(
              'Inicia sesión con un usuario del respaldo.\n\nCopia anterior:\n${resultado['respaldoPrevio']}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Ir al inicio de sesión'),
              ),
            ],
          ),
        );

        if (mounted) widget.onRestaurado();
      } else {
        _registrarUltimoRespaldo(ruta);

        setState(() {
          _resultado = 'Respaldo guardado correctamente en:\n$ruta';
          _error = false;
        });
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
              'No se pudo confirmar la operación. Revisa la API antes de volver a intentarlo.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _ocupado = false);
        widget.onOcupado(false);
      }
    }
  }

  void _registrarUltimoRespaldo(String ruta) {
    int? bytes;

    try {
      final archivo = File(ruta);
      if (archivo.existsSync()) {
        bytes = archivo.lengthSync();
      }
    } catch (_) {
      bytes = null;
    }

    setState(() {
      _ultimoRespaldo = _UltimoRespaldo(
        fecha: DateTime.now(),
        ruta: ruta,
        bytes: bytes,
      );
    });
  }

  String _textoUltimoRespaldo() {
    final ultimo = _ultimoRespaldo;

    if (ultimo == null) {
      return 'Último respaldo: pendiente en esta sesión';
    }

    return 'Último respaldo: ${_formatoFechaCorta(ultimo.fecha)}';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Container(
        color: _fondoPagina,
        child: Align(
          alignment: Alignment.topLeft,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _EncabezadoRespaldos(
                  ultimoRespaldo: _textoUltimoRespaldo(),
                  ocupado: _ocupado,
                  onCrearRespaldo: () => _ejecutar(false),
                  onRestaurar: () => _ejecutar(true),
                ),
                const SizedBox(height: 24),
                _TarjetaUltimoRespaldo(
                  ultimoRespaldo: _ultimoRespaldo,
                ),
                if (_ocupado) ...[
                  const SizedBox(height: 24),
                  const _PanelOperacionEnCurso(),
                ],
                if (_resultado != null) ...[
                  const SizedBox(height: 24),
                  _PanelResultado(
                    error: _error,
                    mensaje: _resultado!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogoConfirmarRespaldo extends StatefulWidget {
  final bool restaurar;
  final String ruta;
  final String username;

  const _DialogoConfirmarRespaldo({
    required this.restaurar,
    required this.ruta,
    required this.username,
  });

  @override
  State<_DialogoConfirmarRespaldo> createState() =>
      _DialogoConfirmarRespaldoState();
}

class _DialogoConfirmarRespaldoState extends State<_DialogoConfirmarRespaldo> {
  final TextEditingController _passwordController = TextEditingController();
  bool _ocultarPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _confirmar() {
    final password = _passwordController.text.trim();

    if (password.isEmpty) {
      return;
    }

    Navigator.of(context).pop(password);
  }

  @override
  Widget build(BuildContext context) {
    final esRestauracion = widget.restaurar;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 690,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 26, 24, 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF7DF),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xFFB9E8A0)),
                    ),
                    child: Icon(
                      esRestauracion
                          ? Icons.restore_outlined
                          : Icons.storage_outlined,
                      color: _verdeOscuro,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                esRestauracion
                                    ? 'Restaurar respaldo'
                                    : 'Crear respaldo',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _textoPrincipal,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              height: 22,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF7DF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFB9E8A0),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified_user_outlined,
                                    color: _verdeOscuro,
                                    size: 13,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Seguro',
                                    style: TextStyle(
                                      color: _verdeOscuro,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          esRestauracion
                              ? 'Selecciona un respaldo confiable y autoriza la restauración de la base de datos de Farmacia Ángeles.'
                              : 'Genera una copia íntegra y cifrada de la base de datos de Farmacia Ángeles.',
                          style: const TextStyle(
                            color: _textoSecundario,
                            fontSize: 13,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFF98A2B3),
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE9EEF2)),
            Padding(
              padding: const EdgeInsets.fromLTRB(34, 24, 34, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _EtiquetaDialogo(
                    icono: Icons.folder_open_outlined,
                    texto: 'RUTA SELECCIONADA',
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDDE5EC)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.description_outlined,
                          color: _verdeOscuro,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SelectableText(
                            widget.ruta,
                            maxLines: 1,
                            style: const TextStyle(
                              color: _textoPrincipal,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 34,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: const Color(0xFFDDE5EC),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.folder_open_outlined,
                                color: _textoSecundario,
                                size: 15,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Examinar',
                                style: TextStyle(
                                  color: _textoPrincipal,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'CONTRASEÑA DE ADMINISTRADOR',
                    style: TextStyle(
                      color: _textoPrincipal,
                      fontSize: 11,
                      letterSpacing: .4,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _passwordController,
                    obscureText: _ocultarPassword,
                    autofocus: true,
                    cursorColor: _verdeOscuro,
                    onSubmitted: (_) => _confirmar(),
                    style: const TextStyle(
                      color: _textoPrincipal,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Introduce la contraseña para autorizar',
                      hintStyle: const TextStyle(
                        color: Color(0xFF98A2B3),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: _verdeOscuro,
                        size: 19,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _ocultarPassword = !_ocultarPassword;
                          });
                        },
                        icon: Icon(
                          _ocultarPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: const Color(0xFF98A2B3),
                          size: 19,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: const BorderSide(
                          color: Color(0xFFB9E8A0),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: const BorderSide(
                          color: Color(0xFFB9E8A0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: const BorderSide(
                          color: _verdePrincipal,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: _verdeOscuro,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          esRestauracion
                              ? 'Se requiere credencial con privilegios de Administrador para restaurar datos.'
                              : 'Se requiere credencial con privilegios de Administrador para exportar datos.',
                          style: const TextStyle(
                            color: _textoSecundario,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE9EEF2)),
            Padding(
              padding: const EdgeInsets.fromLTRB(34, 18, 34, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        color: _textoPrincipal,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _confirmar,
                      icon: const Icon(
                        Icons.save_outlined,
                        color: Colors.white,
                        size: 17,
                      ),
                      label: Text(
                        esRestauracion
                            ? 'Restaurar respaldo'
                            : 'Guardar respaldo',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _verdePrincipal,
                        elevation: 7,
                        shadowColor: _verdePrincipal.withOpacity(.28),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EtiquetaDialogo extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _EtiquetaDialogo({
    required this.icono,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icono,
          color: _textoSecundario,
          size: 13,
        ),
        const SizedBox(width: 6),
        Text(
          texto,
          style: const TextStyle(
            color: _textoSecundario,
            fontSize: 11,
            letterSpacing: .35,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _EncabezadoRespaldos extends StatelessWidget {
  final String ultimoRespaldo;
  final bool ocupado;
  final VoidCallback onCrearRespaldo;
  final VoidCallback onRestaurar;

  const _EncabezadoRespaldos({
    required this.ultimoRespaldo,
    required this.ocupado,
    required this.onCrearRespaldo,
    required this.onRestaurar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: const [
                  Text(
                    'Respaldos y Base de Datos',
                    style: TextStyle(
                      color: _textoPrincipal,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  _BadgeBaseDatos(),
                ],
              ),
              const SizedBox(height: 10),
              _ChipUltimoRespaldo(
                texto: ultimoRespaldo,
              ),
              const SizedBox(height: 12),
              const SizedBox(
                width: 680,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text:
                            'Gestiona, programa y restaura copias de seguridad locales para salvaguardar el catálogo, ventas e historial de prescripciones de ',
                      ),
                      TextSpan(
                        text: 'Farmacia Ángeles.',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  style: TextStyle(
                    color: Color(0xFF214025),
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            _BotonAccionRespaldo(
              texto: 'Crear respaldo manual',
              icono: Icons.add_circle_outline,
              color: _verdePrincipal,
              foregroundColor: Colors.white,
              onTap: ocupado ? null : onCrearRespaldo,
              width: 220,
            ),
            _BotonAccionRespaldo(
              texto: 'Restaurar / Cargar',
              icono: Icons.restore_outlined,
              color: _azulPrincipal,
              foregroundColor: Colors.white,
              onTap: ocupado ? null : onRestaurar,
              width: 190,
            ),
          ],
        ),
      ],
    );
  }
}

class _BadgeBaseDatos extends StatelessWidget {
  const _BadgeBaseDatos();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7DF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB9E8A0)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            color: _verdeOscuro,
            size: 7,
          ),
          SizedBox(width: 6),
          Text(
            'Base de Datos: Conectada y Segura',
            style: TextStyle(
              color: _verdeOscuro,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipUltimoRespaldo extends StatelessWidget {
  final String texto;

  const _ChipUltimoRespaldo({
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _bordeSuave),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.access_time,
            color: _textoSecundario,
            size: 13,
          ),
          const SizedBox(width: 6),
          Text(
            texto,
            style: const TextStyle(
              color: _textoPrincipal,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonAccionRespaldo extends StatelessWidget {
  final String texto;
  final IconData icono;
  final Color color;
  final Color foregroundColor;
  final VoidCallback? onTap;
  final double width;

  const _BotonAccionRespaldo({
    required this.texto,
    required this.icono,
    required this.color,
    required this.foregroundColor,
    required this.onTap,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 46,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(
          icono,
          color: foregroundColor,
          size: 17,
        ),
        label: Text(
          texto,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: foregroundColor,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withOpacity(0.45),
          elevation: 4,
          shadowColor: color.withOpacity(0.25),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
        ),
      ),
    );
  }
}

class _TarjetaUltimoRespaldo extends StatelessWidget {
  final _UltimoRespaldo? ultimoRespaldo;

  const _TarjetaUltimoRespaldo({
    required this.ultimoRespaldo,
  });

  @override
  Widget build(BuildContext context) {
    final respaldo = ultimoRespaldo;

    return Container(
      width: 210,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: _bordeSuave),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'ÚLTIMO RESPALDO',
                  style: TextStyle(
                    color: Color(0xFF6A736C),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .2,
                  ),
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7DF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.settings_backup_restore_outlined,
                  color: _verdeOscuro,
                  size: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            respaldo == null ? 'Sin respaldo' : _textoRelativo(respaldo.fecha),
            style: const TextStyle(
              color: _textoPrincipal,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            respaldo == null ? 'Pendiente en esta sesión' : '(Éxito)',
            style: TextStyle(
              color: respaldo == null ? _textoSecundario : _verdeOscuro,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tamaño: ${respaldo == null ? 'No disponible' : _formatearTamano(respaldo.bytes)}',
            style: const TextStyle(
              color: _textoPrincipal,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _MiniBadgeDestino(
                icono: Icons.cloud_done_outlined,
                texto: respaldo == null ? 'Local pendiente' : 'Local (C:)',
              ),
              const _MiniBadgeDestino(
                icono: Icons.cloud_outlined,
                texto: 'Nube opcional',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniBadgeDestino extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _MiniBadgeDestino({
    required this.icono,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _bordeSuave),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icono,
            color: _azulPrincipal,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            texto,
            style: const TextStyle(
              color: _textoPrincipal,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelOperacionEnCurso extends StatelessWidget {
  const _PanelOperacionEnCurso();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 520,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: _bordeSuave),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            color: _verdeOscuro,
            backgroundColor: Color(0xFFEAF7DF),
          ),
          SizedBox(height: 12),
          Text(
            'Operación en curso. No cierres la aplicación ni la API.',
            style: TextStyle(
              color: _textoPrincipal,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelResultado extends StatelessWidget {
  final bool error;
  final String mensaje;

  const _PanelResultado({
    required this.error,
    required this.mensaje,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 620,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: error ? _rojoError.withOpacity(.35) : _bordeSuave,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            error ? Icons.error_outline : Icons.check_circle_outline,
            color: error ? _rojoError : _verdeOscuro,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(
              mensaje,
              style: const TextStyle(
                color: _textoPrincipal,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UltimoRespaldo {
  final DateTime fecha;
  final String ruta;
  final int? bytes;

  const _UltimoRespaldo({
    required this.fecha,
    required this.ruta,
    required this.bytes,
  });
}

String _formatoFechaCorta(DateTime fecha) {
  final ahora = DateTime.now();
  final esHoy = ahora.year == fecha.year &&
      ahora.month == fecha.month &&
      ahora.day == fecha.day;

  final hora = _formatoHora(fecha);

  if (esHoy) {
    return 'Hoy a las $hora';
  }

  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');

  return '$dia/$mes/${fecha.year} a las $hora';
}

String _formatoHora(DateTime fecha) {
  final hour12 = fecha.hour == 0
      ? 12
      : fecha.hour > 12
          ? fecha.hour - 12
          : fecha.hour;

  final minutos = fecha.minute.toString().padLeft(2, '0');
  final periodo = fecha.hour >= 12 ? 'PM' : 'AM';

  return '$hour12:$minutos $periodo';
}

String _textoRelativo(DateTime fecha) {
  final diferencia = DateTime.now().difference(fecha);

  if (diferencia.inMinutes < 1) {
    return 'Ahora';
  }

  if (diferencia.inMinutes < 60) {
    return 'Hace ${diferencia.inMinutes} min';
  }

  if (diferencia.inHours < 24) {
    return 'Hace ${diferencia.inHours} horas';
  }

  return 'Hace ${diferencia.inDays} días';
}

String _formatearTamano(int? bytes) {
  if (bytes == null) return 'No disponible';

  final mb = bytes / (1024 * 1024);

  if (mb >= 1) {
    return '${mb.toStringAsFixed(1)} MB';
  }

  final kb = bytes / 1024;
  return '${kb.toStringAsFixed(1)} KB';
}
