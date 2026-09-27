import 'package:flutter/material.dart';

import '../../services/proveedores_api_service.dart';

const Color _blanco = Color(0xFFFFFFFF);
const Color _fondoCampo = Color(0xFFF2F2F2);
const Color _verdeOscuro = Color(0xFF397800);
const Color _textoPrincipal = Color(0xFF101828);
const Color _textoSecundario = Color(0xFF667085);
const Color _bordeSuave = Color(0xFFD9E6D3);
const Color _bordeCampo = Color(0xFFE0E0E0);
const Color _rojo = Color(0xFFE02020);

typedef GuardarProveedorCallback = Future<void> Function(
  ProveedorPayload datos,
);

class MenuCartaProveedores extends StatefulWidget {
  final ProveedorApi? proveedor;
  final bool guardando;
  final VoidCallback onCerrar;
  final GuardarProveedorCallback onGuardarProveedor;

  const MenuCartaProveedores({
    super.key,
    this.proveedor,
    required this.guardando,
    required this.onCerrar,
    required this.onGuardarProveedor,
  });

  bool get esEdicion => proveedor != null;

  @override
  State<MenuCartaProveedores> createState() => _MenuCartaProveedoresState();
}

class _MenuCartaProveedoresState extends State<MenuCartaProveedores> {
  late final TextEditingController _nombreController;
  late final TextEditingController _contactoController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _direccionController;

  String? _error;

  @override
  void initState() {
    super.initState();

    final proveedor = widget.proveedor;

    _nombreController = TextEditingController(
      text: proveedor?.nombre ?? '',
    );

    _contactoController = TextEditingController(
      text: proveedor?.contacto ?? '',
    );

    _telefonoController = TextEditingController(
      text: proveedor?.telefono ?? '',
    );

    _direccionController = TextEditingController(
      text: proveedor?.direccion ?? '',
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _contactoController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();

    super.dispose();
  }

  Future<void> _guardar() async {
    if (widget.guardando) {
      return;
    }

    final nombre = _nombreController.text.trim();

    if (nombre.isEmpty) {
      setState(() {
        _error = 'Ingresa el nombre del proveedor';
      });

      return;
    }

    setState(() {
      _error = null;
    });

    final datos = ProveedorPayload(
      nombre: nombre,
      contacto: _limpiarTexto(
        _contactoController.text,
      ),
      telefono: _limpiarTexto(
        _telefonoController.text,
      ),
      direccion: _limpiarTexto(
        _direccionController.text,
      ),
    );

    await widget.onGuardarProveedor(datos);
  }

  void _limpiarError(String _) {
    if (_error == null) {
      return;
    }

    setState(() {
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      height: double.infinity,
      decoration: BoxDecoration(
        color: _blanco,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _bordeSuave,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.08,
            ),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _TituloPanelProveedor(
            esEdicion: widget.esEdicion,
            guardando: widget.guardando,
            onCerrar: widget.onCerrar,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                12,
                16,
                12,
                18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CampoProveedor(
                    etiqueta: 'Nombre del Proveedor',
                    hintText: 'Ej: Distribuidora Médica S.A.',
                    controller: _nombreController,
                    enabled: !widget.guardando,
                    onChanged: _limpiarError,
                  ),
                  const SizedBox(height: 18),
                  _CampoProveedor(
                    etiqueta: 'Persona de Contacto',
                    hintText: 'Ej: Juan Pérez',
                    controller: _contactoController,
                    enabled: !widget.guardando,
                  ),
                  const SizedBox(height: 18),
                  _CampoProveedor(
                    etiqueta: 'Teléfono',
                    hintText: 'Ej: +52 55 1234 5678',
                    controller: _telefonoController,
                    enabled: !widget.guardando,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 18),
                  _CampoProveedor(
                    etiqueta: 'Dirección',
                    hintText: 'Calle, número, colonia y ciudad...',
                    controller: _direccionController,
                    enabled: !widget.guardando,
                    minLines: 4,
                    maxLines: 4,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    _MensajeErrorProveedor(
                      mensaje: _error!,
                    ),
                  ],
                ],
              ),
            ),
          ),
          _AccionesProveedor(
            esEdicion: widget.esEdicion,
            guardando: widget.guardando,
            onGuardar: _guardar,
          ),
        ],
      ),
    );
  }
}

class _TituloPanelProveedor extends StatelessWidget {
  final bool esEdicion;
  final bool guardando;
  final VoidCallback onCerrar;

  const _TituloPanelProveedor({
    required this.esEdicion,
    required this.guardando,
    required this.onCerrar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: _blanco,
        border: Border(
          bottom: BorderSide(
            color: _bordeSuave,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_shipping_outlined,
            color: _verdeOscuro,
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              esEdicion ? 'Editar Proveedor' : 'Nuevo Proveedor',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _textoPrincipal,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            onPressed: guardando ? null : onCerrar,
            icon: const Icon(
              Icons.close,
              color: _textoPrincipal,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }
}

class _CampoProveedor extends StatelessWidget {
  final String etiqueta;
  final String hintText;
  final TextEditingController controller;
  final bool enabled;
  final int maxLines;
  final int minLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const _CampoProveedor({
    required this.etiqueta,
    required this.hintText,
    required this.controller,
    required this.enabled,
    this.maxLines = 1,
    this.minLines = 1,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _ContenedorCampoProveedor(
      etiqueta: etiqueta,
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        maxLines: maxLines,
        minLines: minLines,
        onChanged: onChanged,
        cursorColor: _verdeOscuro,
        style: const TextStyle(
          color: _textoPrincipal,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        decoration: _decoracionCampoProveedor(
          hintText: hintText,
          enabled: enabled,
        ),
      ),
    );
  }
}

class _ContenedorCampoProveedor extends StatelessWidget {
  final String etiqueta;
  final Widget child;

  const _ContenedorCampoProveedor({
    required this.etiqueta,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: const TextStyle(
            color: _textoPrincipal,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 38,
          ),
          child: child,
        ),
      ],
    );
  }
}

class _MensajeErrorProveedor extends StatelessWidget {
  final String mensaje;

  const _MensajeErrorProveedor({
    required this.mensaje,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEAEA),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFFFC9C9),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            color: _rojo,
            size: 16,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(
                color: _rojo,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccionesProveedor extends StatelessWidget {
  final bool esEdicion;
  final bool guardando;
  final VoidCallback onGuardar;

  const _AccionesProveedor({
    required this.esEdicion,
    required this.guardando,
    required this.onGuardar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.fromLTRB(
        10,
        10,
        10,
        10,
      ),
      decoration: const BoxDecoration(
        color: _blanco,
        border: Border(
          top: BorderSide(
            color: _bordeSuave,
          ),
        ),
      ),
      child: _BotonGuardarProveedor(
        esEdicion: esEdicion,
        guardando: guardando,
        onGuardar: onGuardar,
      ),
    );
  }
}

class _BotonGuardarProveedor extends StatelessWidget {
  final bool esEdicion;
  final bool guardando;
  final VoidCallback onGuardar;

  const _BotonGuardarProveedor({
    required this.esEdicion,
    required this.guardando,
    required this.onGuardar,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: ElevatedButton.icon(
        onPressed: guardando ? null : onGuardar,
        icon: guardando
            ? const SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _blanco,
                ),
              )
            : const Icon(
                Icons.save_outlined,
                color: _blanco,
                size: 14,
              ),
        label: Text(
          guardando
              ? 'Guardando...'
              : esEdicion
                  ? 'Actualizar Proveedor'
                  : 'Guardar Proveedor',
          style: const TextStyle(
            color: _blanco,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _verdeOscuro,
          disabledBackgroundColor: _verdeOscuro.withValues(
            alpha: 0.55,
          ),
          elevation: 4,
          shadowColor: _verdeOscuro.withValues(
            alpha: 0.25,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}

InputDecoration _decoracionCampoProveedor({
  required String hintText,
  required bool enabled,
}) {
  return InputDecoration(
    filled: true,
    fillColor: enabled ? _fondoCampo : const Color(0xFFE8E8E8),
    hintText: hintText,
    hintStyle: const TextStyle(
      color: _textoSecundario,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 11,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(
        color: _bordeCampo,
        width: 1,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(
        color: _bordeCampo,
        width: 1,
      ),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(
        color: Color(0xFFD4D6D2),
        width: 1,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(
        color: _verdeOscuro,
        width: 1.2,
      ),
    ),
  );
}

String? _limpiarTexto(String value) {
  final texto = value.trim();

  return texto.isEmpty ? null : texto;
}
