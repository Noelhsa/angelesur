import 'package:flutter/material.dart';

const Color _fondoPagina = Color(0xFFF8F6F5);
const Color _verdeOscuro = Color(0xFF397800);
const Color _azul = Color(0xFF0B63CE);
const Color _textoPrincipal = Color(0xFF101828);
const Color _textoSecundario = Color(0xFF667085);
const Color _bordeSuave = Color(0xFFD9E6D3);
const Color _grisCampo = Color(0xFFF6F4F1);
const Color _naranja = Color(0xFFFF8A00);

class MenuCartaDevolucionCliente extends StatefulWidget {
  final VoidCallback onCerrar;
  final VoidCallback onGuardarDevolucion;

  const MenuCartaDevolucionCliente({
    super.key,
    required this.onCerrar,
    required this.onGuardarDevolucion,
  });

  @override
  State<MenuCartaDevolucionCliente> createState() =>
      _MenuCartaDevolucionClienteState();
}

class _MenuCartaDevolucionClienteState
    extends State<MenuCartaDevolucionCliente> {
  final TextEditingController _folioController = TextEditingController(
    text: 'DEV-2023-0892',
  );
  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  final TextEditingController _observacionesController =
      TextEditingController();
  final TextEditingController _fechaRegistroController = TextEditingController(
    text: '24 de Mayo, 2024 · 14:30',
  );

  String? _motivoSeleccionado;
  String _metodoSeleccionado = 'Efectivo';
  String _estatusSeleccionado = 'Pendiente';

  @override
  void dispose() {
    _folioController.dispose();
    _fechaController.dispose();
    _totalController.dispose();
    _observacionesController.dispose();
    _fechaRegistroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 430,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: _fondoPagina,
        border: Border(
          left: BorderSide(
            color: _bordeSuave,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _EncabezadoDevolucionCliente(
            onCerrar: widget.onCerrar,
            onGuardar: widget.onGuardarDevolucion,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _bordeSuave),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _FilaCampo(
                      etiqueta: 'Folio de Referencia',
                      child: _CampoTexto(
                        controller: _folioController,
                        hintText: 'DEV-2023-0892',
                      ),
                    ),
                    const _SeparadorFormulario(),
                    _FilaCampo(
                      etiqueta: 'Fecha de Devolución',
                      child: _CampoTexto(
                        controller: _fechaController,
                        hintText: 'dd/mm/aaaa',
                        suffixIcon: Icons.calendar_today_outlined,
                      ),
                    ),
                    const _SeparadorFormulario(),
                    _FilaCampo(
                      etiqueta: 'Motivo',
                      child: _CampoDropdown(
                        valor: _motivoSeleccionado,
                        hintText: 'Seleccione un motivo...',
                        opciones: const [
                          'Caducidad próxima',
                          'Producto dañado',
                          'Error en despacho',
                          'Cliente cambió de opinión',
                          'Otro',
                        ],
                        onChanged: (value) {
                          setState(() {
                            _motivoSeleccionado = value;
                          });
                        },
                      ),
                    ),
                    const _SeparadorFormulario(),
                    _FilaCampo(
                      etiqueta: 'Total (\$)',
                      child: _CampoTexto(
                        controller: _totalController,
                        hintText: '0.00',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const _SeparadorFormulario(),
                    _FilaCampo(
                      etiqueta: 'Método de Devolución',
                      child: _CampoDropdown(
                        valor: _metodoSeleccionado,
                        opciones: const [
                          'Efectivo',
                          'Tarjeta',
                          'Transferencia',
                          'Monedero',
                          'Crédito en tienda',
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setState(() {
                            _metodoSeleccionado = value;
                          });
                        },
                      ),
                    ),
                    const _SeparadorFormulario(),
                    _FilaCampo(
                      etiqueta: 'Estatus Inicial',
                      child: _SelectorEstatus(
                        estatusSeleccionado: _estatusSeleccionado,
                        onChanged: (estatus) {
                          setState(() {
                            _estatusSeleccionado = estatus;
                          });
                        },
                      ),
                    ),
                    const _SeparadorFormulario(),
                    _FilaCampo(
                      etiqueta: 'Observaciones',
                      alineacionSuperior: true,
                      child: _CampoTexto(
                        controller: _observacionesController,
                        hintText:
                            'Detalles adicionales sobre el estado del producto o el cliente...',
                        maxLines: 4,
                      ),
                    ),
                    const _SeparadorFormulario(),
                    _FilaCampo(
                      etiqueta: 'Fecha de Registro',
                      child: _CampoTexto(
                        controller: _fechaRegistroController,
                        enabled: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EncabezadoDevolucionCliente extends StatelessWidget {
  final VoidCallback onCerrar;
  final VoidCallback onGuardar;

  const _EncabezadoDevolucionCliente({
    required this.onCerrar,
    required this.onGuardar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: _fondoPagina,
        border: Border(
          bottom: BorderSide(
            color: _bordeSuave,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onCerrar,
            icon: const Icon(
              Icons.arrow_back,
              color: _textoPrincipal,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 30,
              minHeight: 30,
            ),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'Añadir Devolución de Cliente',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _textoPrincipal,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(
            width: 86,
            height: 34,
            child: OutlinedButton(
              onPressed: onCerrar,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: _bordeSuave),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: _textoPrincipal,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 128,
            height: 34,
            child: ElevatedButton.icon(
              onPressed: onGuardar,
              icon: const Icon(
                Icons.save_outlined,
                color: Colors.white,
                size: 14,
              ),
              label: const Text(
                'Guardar Devolución',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _verdeOscuro,
                elevation: 4,
                shadowColor: _verdeOscuro.withOpacity(0.25),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onCerrar,
            icon: const Icon(
              Icons.close,
              color: _textoPrincipal,
              size: 18,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 28,
              minHeight: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaCampo extends StatelessWidget {
  final String etiqueta;
  final Widget child;
  final bool alineacionSuperior;

  const _FilaCampo({
    required this.etiqueta,
    required this.child,
    this.alineacionSuperior = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          alineacionSuperior ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 130,
          child: Padding(
            padding: EdgeInsets.only(top: alineacionSuperior ? 10 : 0),
            child: Text(
              etiqueta,
              style: const TextStyle(
                color: Color(0xFF6A736C),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: child),
      ],
    );
  }
}

class _SeparadorFormulario extends StatelessWidget {
  const _SeparadorFormulario();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 14),
      color: const Color(0xFFE6EADC),
    );
  }
}

class _CampoTexto extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final IconData? suffixIcon;
  final bool enabled;
  final int maxLines;
  final TextInputType? keyboardType;

  const _CampoTexto({
    required this.controller,
    this.hintText,
    this.suffixIcon,
    this.enabled = true,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      cursorColor: _verdeOscuro,
      style: TextStyle(
        color: enabled ? _textoPrincipal : _textoSecundario,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      decoration: _decoracionCampo(
        hintText: hintText,
        suffixIcon: suffixIcon,
        enabled: enabled,
      ),
    );
  }
}

class _CampoDropdown extends StatelessWidget {
  final String? valor;
  final String? hintText;
  final List<String> opciones;
  final ValueChanged<String?> onChanged;

  const _CampoDropdown({
    required this.valor,
    this.hintText,
    required this.opciones,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: valor,
      isExpanded: true,
      icon: const Icon(
        Icons.keyboard_arrow_down,
        color: _textoSecundario,
        size: 18,
      ),
      hint: hintText == null
          ? null
          : Text(
              hintText!,
              style: const TextStyle(
                color: _textoSecundario,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
      style: const TextStyle(
        color: _textoPrincipal,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      decoration: _decoracionCampo(),
      items: opciones.map((opcion) {
        return DropdownMenuItem<String>(
          value: opcion,
          child: Text(opcion),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

class _SelectorEstatus extends StatelessWidget {
  final String estatusSeleccionado;
  final ValueChanged<String> onChanged;

  const _SelectorEstatus({
    required this.estatusSeleccionado,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _OpcionEstatus(
          texto: 'Pendiente',
          activo: estatusSeleccionado == 'Pendiente',
          color: _naranja,
          fondo: const Color(0xFFFFF0DE),
          onTap: () => onChanged('Pendiente'),
        ),
        const SizedBox(width: 16),
        _OpcionEstatus(
          texto: 'Procesado',
          activo: estatusSeleccionado == 'Procesado',
          color: _azul,
          fondo: const Color(0xFFE8F1FF),
          onTap: () => onChanged('Procesado'),
        ),
      ],
    );
  }
}

class _OpcionEstatus extends StatelessWidget {
  final String texto;
  final bool activo;
  final Color color;
  final Color fondo;
  final VoidCallback onTap;

  const _OpcionEstatus({
    required this.texto,
    required this.activo,
    required this.color,
    required this.fondo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: activo ? _verdeOscuro : const Color(0xFFC7CDD3),
                width: 2,
              ),
            ),
            child: activo
                ? Center(
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: _verdeOscuro,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: fondo,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              texto,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _decoracionCampo({
  String? hintText,
  IconData? suffixIcon,
  bool enabled = true,
}) {
  return InputDecoration(
    filled: true,
    fillColor: enabled ? _grisCampo : const Color(0xFFEDEDED),
    hintText: hintText,
    hintStyle: const TextStyle(
      color: _textoSecundario,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
    suffixIcon: suffixIcon == null
        ? null
        : Icon(
            suffixIcon,
            color: _textoSecundario,
            size: 17,
          ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 10,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(
        color: _bordeSuave,
        width: 1,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(
        color: _bordeSuave,
        width: 1,
      ),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(
        color: _bordeSuave,
        width: 1,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(
        color: _verdeOscuro,
        width: 1.3,
      ),
    ),
  );
}