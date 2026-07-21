import 'package:flutter/material.dart';

import '../../services/productos_api_service.dart';

const Color _verdeOscuro = Color(0xFF397800);
const Color _verde = Color(0xFF64D20A);
const Color _textoPrincipal = Color(0xFF101828);
const Color _textoSecundario = Color(0xFF667085);
const Color _bordeSuave = Color(0xFFD9E6D3);
const Color _grisCampo = Color(0xFFF8F7F4);

class MenuCartaCatalogoProducto extends StatefulWidget {
  final VoidCallback onCerrar;
  final ValueChanged<ProductoPayload> onGuardarProducto;

  const MenuCartaCatalogoProducto({
    super.key,
    required this.onCerrar,
    required this.onGuardarProducto,
  });

  @override
  State<MenuCartaCatalogoProducto> createState() =>
      _MenuCartaCatalogoProductoState();
}

class _MenuCartaCatalogoProductoState extends State<MenuCartaCatalogoProducto> {
  final TextEditingController _codigoController =
      TextEditingController(text: '750012345678');

  final TextEditingController _nombreController = TextEditingController();

  final TextEditingController _descripcionController = TextEditingController();

  final TextEditingController _fechaController = TextEditingController();

  final TextEditingController _principioActivoController =
      TextEditingController();

  final TextEditingController _dosisCantidadController =
      TextEditingController();

  String _claseSeleccionada = 'Producto';
  String _tipoSeleccionado = 'Producto';
  String _viaAdministracionSeleccionada = 'TABLETA';
  String _edadSeleccionada = 'GENERAL';
  String _dosisUnidadSeleccionada = 'mg';
  String? _error;
  String _categoriaSeleccionada = 'General';
  bool _manejaCaducidad = false;
  bool _requiereReceta = false;

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _fechaController.dispose();
    _principioActivoController.dispose();
    _dosisCantidadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esMedicamento = _claseSeleccionada == 'Medicamento';

    return Container(
      width: 285,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(
            color: _bordeSuave,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _EncabezadoNuevoMedicamento(
            onCerrar: widget.onCerrar,
            esMedicamento: esMedicamento,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CampoTextoCatalogo(
                    etiqueta: 'Codigo de barras',
                    controller: _codigoController,
                    suffixIcon: Icons.barcode_reader,
                  ),
                  const SizedBox(height: 14),
                  _CampoDropdownCatalogo(
                    etiqueta: 'Tipo de registro',
                    valor: _claseSeleccionada,
                    opciones: const ['Producto', 'Medicamento'],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _claseSeleccionada = value;
                        if (value == 'Medicamento') {
                          _tipoSeleccionado = 'Tableta';
                          _viaAdministracionSeleccionada = 'TABLETA';
                          _edadSeleccionada = 'GENERAL';
                          _dosisUnidadSeleccionada = 'mg';
                          _categoriaSeleccionada = 'Analgesicos';
                          _manejaCaducidad = true;
                          _requiereReceta = false;
                        } else {
                          _tipoSeleccionado = 'Producto';
                          _categoriaSeleccionada = 'General';
                          _manejaCaducidad = false;
                        }
                        _error = null;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  _CampoTextoCatalogo(
                    etiqueta:
                        esMedicamento ? 'Nombre del medicamento' : 'Nombre',
                    controller: _nombreController,
                    hintText: esMedicamento
                        ? 'Ej: Ibuprofeno 400mg'
                        : 'Ej: Shampoo, alcohol, jeringa',
                  ),
                  const SizedBox(height: 14),
                  _CampoTextoCatalogo(
                    etiqueta: 'Descripcion',
                    controller: _descripcionController,
                    hintText: 'Indicaciones terapeuticas y detalles...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _CampoDropdownCatalogo(
                          etiqueta: esMedicamento ? 'Presentacion' : 'Tipo',
                          valor: _tipoSeleccionado,
                          opciones: esMedicamento
                              ? const [
                                  'Tableta',
                                  'Capsula',
                                  'Pastilla',
                                  'Jarabe',
                                  'Suspension',
                                  'Gotas',
                                  'Inyectable',
                                  'Crema',
                                  'Pomada',
                                  'Spray',
                                  'Solucion',
                                  'Otro',
                                ]
                              : const [
                                  'Producto',
                                  'Higiene',
                                  'Curacion',
                                  'Bebida',
                                  'Dispositivo',
                                  'Otro',
                                ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _tipoSeleccionado = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CampoDropdownCatalogo(
                          etiqueta:
                              esMedicamento ? 'Via de Admin' : 'Categoria',
                          valor: esMedicamento
                              ? _viaAdministracionSeleccionada
                              : _categoriaSeleccionada,
                          opciones: esMedicamento
                              ? const [
                                  'CAPSULA',
                                  'TABLETA',
                                  'PASTILLA',
                                  'SUSPENSION',
                                  'GOTAS',
                                  'INYECCION',
                                  'JARABE',
                                  'CREMA',
                                  'POMADA',
                                  'AEROSOL',
                                  'SOLUCION',
                                  'OTRO',
                                ]
                              : const [
                                  'General',
                                  'Higiene',
                                  'Curacion',
                                  'Bebidas',
                                  'Dispositivo',
                                  'Otro',
                                ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              if (esMedicamento) {
                                _viaAdministracionSeleccionada = value;
                              } else {
                                _categoriaSeleccionada = value;
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _OpcionCaducidadCatalogo(
                    value: _manejaCaducidad,
                    onChanged: (value) {
                      setState(() {
                        _manejaCaducidad = value;
                      });
                    },
                  ),
                  if (esMedicamento) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _CampoFechaCatalogo(
                            etiqueta: 'Fecha de caducidad',
                            controller: _fechaController,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _CampoTextoCatalogo(
                            etiqueta: 'Principio Activo',
                            controller: _principioActivoController,
                            hintText: 'Ej: Naproxeno',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _CampoDropdownCatalogo(
                      etiqueta: 'Edad',
                      valor: _edadSeleccionada,
                      opciones: const [
                        'PEDIATRICO',
                        'INFANTIL',
                        'ADULTO',
                        'GENERAL',
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _edadSeleccionada = value;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    _OpcionRecetaCatalogo(
                      value: _requiereReceta,
                      onChanged: (value) {
                        setState(() {
                          _requiereReceta = value;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _CampoTextoCatalogo(
                            etiqueta: 'Cantidad',
                            controller: _dosisCantidadController,
                            hintText: 'Ej: 500',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _CampoDropdownCatalogo(
                            etiqueta: 'Unidad',
                            valor: _dosisUnidadSeleccionada,
                            opciones: const [
                              'mg',
                              'g',
                              'mcg',
                              'ml',
                              'l',
                              'UI',
                              '%',
                              'gotas',
                              'tabletas',
                              'capsulas',
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _dosisUnidadSeleccionada = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  const _AreaCargarFoto(),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: Color(0xFFE02020),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          _AccionesNuevoMedicamento(
            onCancelar: widget.onCerrar,
            onGuardar: _guardarProducto,
            esMedicamento: esMedicamento,
          ),
        ],
      ),
    );
  }

  void _guardarProducto() {
    final esMedicamento = _claseSeleccionada == 'Medicamento';
    final nombre = _nombreController.text.trim();
    final dosis = _dosisTexto();
    if (nombre.isEmpty) {
      setState(() {
        _error = esMedicamento
            ? 'Ingresa el nombre del medicamento'
            : 'Ingresa el nombre del producto';
      });
      return;
    }

    widget.onGuardarProducto(
      ProductoPayload(
        codigoBarras: _limpiar(_codigoController.text),
        nombre: nombre,
        descripcion: _limpiar(_descripcionController.text),
        tipo: esMedicamento ? 'MEDICAMENTO' : 'PRODUCTO',
        categoria: esMedicamento
            ? null
            : _categoriaNormalizada(_categoriaSeleccionada),
        manejaCaducidad: _manejaCaducidad,
        infoMedicamento: esMedicamento
            ? {
                'presentacion': _presentacionNormalizada(_tipoSeleccionado),
                'viaAdministracion': _viaAdministracionSeleccionada,
                'edad': _edadSeleccionada,
                'requiereReceta': _requiereReceta,
                'sustanciaActiva': _limpiar(_principioActivoController.text),
                'dosis': dosis,
              }
            : null,
      ),
    );
  }

  String? _dosisTexto() {
    final cantidad = _dosisCantidadController.text.trim();
    if (cantidad.isEmpty) {
      return null;
    }
    return '$cantidad $_dosisUnidadSeleccionada';
  }
}

class _EncabezadoNuevoMedicamento extends StatelessWidget {
  final VoidCallback onCerrar;
  final bool esMedicamento;

  const _EncabezadoNuevoMedicamento({
    required this.onCerrar,
    required this.esMedicamento,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: _bordeSuave,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            esMedicamento
                ? Icons.medication_liquid_outlined
                : Icons.inventory_2_outlined,
            color: _verdeOscuro,
            size: 19,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              esMedicamento ? 'Nuevo Medicamento' : 'Nuevo Producto',
              style: const TextStyle(
                color: _textoPrincipal,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            onPressed: onCerrar,
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
          ),
        ],
      ),
    );
  }
}

class _CampoTextoCatalogo extends StatelessWidget {
  final String etiqueta;
  final TextEditingController controller;
  final String? hintText;
  final IconData? suffixIcon;
  final int maxLines;

  const _CampoTextoCatalogo({
    required this.etiqueta,
    required this.controller,
    this.hintText,
    this.suffixIcon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return _ContenedorCampoCatalogo(
      etiqueta: etiqueta,
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        cursorColor: _verdeOscuro,
        style: const TextStyle(
          color: _textoPrincipal,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        decoration: _decoracionCampo(
          hintText: hintText,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}

class _OpcionCaducidadCatalogo extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _OpcionCaducidadCatalogo({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _grisCampo,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _bordeSuave),
        ),
        child: Row(
          children: [
            Checkbox(
              value: value,
              activeColor: _verdeOscuro,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (checked) => onChanged(checked ?? false),
            ),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                'Maneja caducidad',
                style: TextStyle(
                  color: _textoPrincipal,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpcionRecetaCatalogo extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _OpcionRecetaCatalogo({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _grisCampo,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _bordeSuave),
        ),
        child: Row(
          children: [
            Checkbox(
              value: value,
              activeColor: _verdeOscuro,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (checked) => onChanged(checked ?? false),
            ),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                'Requiere receta',
                style: TextStyle(
                  color: _textoPrincipal,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampoFechaCatalogo extends StatelessWidget {
  final String etiqueta;
  final TextEditingController controller;

  const _CampoFechaCatalogo({
    required this.etiqueta,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return _ContenedorCampoCatalogo(
      etiqueta: etiqueta,
      child: TextField(
        controller: controller,
        readOnly: true,
        onTap: () => _seleccionarFecha(context),
        cursorColor: _verdeOscuro,
        style: const TextStyle(
          color: _textoPrincipal,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        decoration: _decoracionCampo(
          hintText: 'Seleccionar fecha',
          suffixIcon: Icons.calendar_month_outlined,
        ),
      ),
    );
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final inicial = _fechaDesdeTexto(controller.text) ??
        DateTime.now().add(const Duration(days: 365));
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Selecciona caducidad',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (seleccionada == null) return;
    controller.text = _formatoFechaVisible(seleccionada);
  }
}

class _CampoDropdownCatalogo extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final List<String> opciones;
  final ValueChanged<String?> onChanged;

  const _CampoDropdownCatalogo({
    required this.etiqueta,
    required this.valor,
    required this.opciones,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _ContenedorCampoCatalogo(
      etiqueta: etiqueta,
      child: DropdownButtonFormField<String>(
        initialValue: opciones.contains(valor) ? valor : opciones.first,
        isExpanded: true,
        icon: const Icon(
          Icons.keyboard_arrow_down,
          color: _textoPrincipal,
          size: 17,
        ),
        style: const TextStyle(
          color: _textoPrincipal,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        decoration: _decoracionCampo(),
        items: opciones.map((opcion) {
          return DropdownMenuItem<String>(
            value: opcion,
            child: Text(
              opcion,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _ContenedorCampoCatalogo extends StatelessWidget {
  final String etiqueta;
  final Widget child;

  const _ContenedorCampoCatalogo({
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
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _AreaCargarFoto extends StatelessWidget {
  const _AreaCargarFoto();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cargar foto',
          style: TextStyle(
            color: _textoPrincipal,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 142,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFC8D6C0),
              width: 1,
              style: BorderStyle.solid,
            ),
          ),
          child: const CustomPaint(
            painter: _DashedBorderPainter(),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    color: _verdeOscuro,
                    size: 28,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Haz clic o arrastra la imagen del\nproducto aqui',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _textoPrincipal,
                      fontSize: 11,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'JPG, PNG HASTA 5MB',
                    style: TextStyle(
                      color: _textoSecundario,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const double dashWidth = 6;
    const double dashSpace = 5;

    final paint = Paint()
      ..color = const Color(0xFFC8D6C0)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(8),
    );

    final path = Path()..addRRect(rect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final nextDistance = distance + dashWidth;
        final extractPath = metric.extractPath(distance, nextDistance);
        canvas.drawPath(extractPath, paint);
        distance = nextDistance + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AccionesNuevoMedicamento extends StatelessWidget {
  final VoidCallback onCancelar;
  final VoidCallback onGuardar;
  final bool esMedicamento;

  const _AccionesNuevoMedicamento({
    required this.onCancelar,
    required this.onGuardar,
    required this.esMedicamento,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: _bordeSuave,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 42,
              child: OutlinedButton(
                onPressed: onCancelar,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: Color(0xFFC8D6C0),
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    color: _textoPrincipal,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 42,
              child: ElevatedButton.icon(
                onPressed: onGuardar,
                icon: const Icon(
                  Icons.save_outlined,
                  color: _verdeOscuro,
                  size: 14,
                ),
                label: Text(
                  esMedicamento ? 'Guardar\nMedicamento' : 'Guardar\nProducto',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _verdeOscuro,
                    fontSize: 10,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _verde,
                  elevation: 4,
                  shadowColor: _verde.withValues(alpha: 0.35),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String? _limpiar(String value) {
  final text = value.trim();
  return text.isEmpty ? null : text;
}

String _presentacionNormalizada(String value) {
  if (value.toLowerCase().contains('psula')) return 'Capsula';
  if (value.startsWith('Suspensi')) return 'Suspension';
  return value;
}

String _categoriaNormalizada(String value) {
  if (value.startsWith('Analg')) return 'Analgesicos';
  if (value.startsWith('Antibi')) return 'Antibioticos';
  if (value.startsWith('G')) return 'Gastrico';
  return value;
}

DateTime? _fechaDesdeTexto(String value) {
  final parts = value.trim().split('/');
  if (parts.length != 3) return null;

  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) return null;

  return DateTime(year, month, day);
}

String _formatoFechaVisible(DateTime fecha) {
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  return '$dia/$mes/${fecha.year}';
}

InputDecoration _decoracionCampo({
  String? hintText,
  IconData? suffixIcon,
}) {
  return InputDecoration(
    filled: true,
    fillColor: _grisCampo,
    hintText: hintText,
    hintStyle: const TextStyle(
      color: _textoSecundario,
      fontSize: 11,
      fontWeight: FontWeight.w500,
    ),
    suffixIcon: suffixIcon == null
        ? null
        : Icon(
            suffixIcon,
            color: _verdeOscuro,
            size: 17,
          ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 10,
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
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(
        color: _verdeOscuro,
        width: 1.3,
      ),
    ),
  );
}
