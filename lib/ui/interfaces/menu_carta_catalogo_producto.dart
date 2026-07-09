import 'package:flutter/material.dart';

const Color _fondoPagina = Color(0xFFF8F6F5);
const Color _verdeOscuro = Color(0xFF397800);
const Color _verde = Color(0xFF64D20A);
const Color _textoPrincipal = Color(0xFF101828);
const Color _textoSecundario = Color(0xFF667085);
const Color _bordeSuave = Color(0xFFD9E6D3);
const Color _grisCampo = Color(0xFFF8F7F4);

class MenuCartaCatalogoProducto extends StatefulWidget {
  final VoidCallback onCerrar;
  final VoidCallback onGuardarMedicamento;

  const MenuCartaCatalogoProducto({
    super.key,
    required this.onCerrar,
    required this.onGuardarMedicamento,
  });

  @override
  State<MenuCartaCatalogoProducto> createState() =>
      _MenuCartaCatalogoProductoState();
}

class _MenuCartaCatalogoProductoState
    extends State<MenuCartaCatalogoProducto> {
  final TextEditingController _codigoController =
      TextEditingController(text: '750012345678');

  final TextEditingController _nombreController = TextEditingController();

  final TextEditingController _descripcionController = TextEditingController();

  final TextEditingController _fechaController = TextEditingController();

  final TextEditingController _principioActivoController =
      TextEditingController();

  String _tipoSeleccionado = 'Tableta';
  String _categoriaSeleccionada = 'Analgésicos';

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _fechaController.dispose();
    _principioActivoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CampoTextoCatalogo(
                    etiqueta: 'Código de barras',
                    controller: _codigoController,
                    suffixIcon: Icons.barcode_reader,
                  ),
                  const SizedBox(height: 14),
                  _CampoTextoCatalogo(
                    etiqueta: 'Nombre del medicamento',
                    controller: _nombreController,
                    hintText: 'Ej: Ibuprofeno 400mg',
                  ),
                  const SizedBox(height: 14),
                  _CampoTextoCatalogo(
                    etiqueta: 'Descripción',
                    controller: _descripcionController,
                    hintText: 'Indicaciones terapéuticas y detalles...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _CampoDropdownCatalogo(
                          etiqueta: 'Tipo',
                          valor: _tipoSeleccionado,
                          opciones: const [
                            'Tableta',
                            'Cápsula',
                            'Jarabe',
                            'Suspensión',
                            'Inyectable',
                            'Crema',
                            'Spray',
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
                          etiqueta: 'Categoría',
                          valor: _categoriaSeleccionada,
                          opciones: const [
                            'Analgésicos',
                            'Antibióticos',
                            'Diabetes',
                            'Suplementos',
                            'Gástrico',
                            'Dispositivo',
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _categoriaSeleccionada = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _CampoTextoCatalogo(
                          etiqueta: 'Fecha de caducidad',
                          controller: _fechaController,
                          hintText: 'dd/mm/aaaa',
                          suffixIcon: Icons.calendar_month_outlined,
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
                  const _AreaCargarFoto(),
                ],
              ),
            ),
          ),
          _AccionesNuevoMedicamento(
            onCancelar: widget.onCerrar,
            onGuardar: widget.onGuardarMedicamento,
          ),
        ],
      ),
    );
  }
}

class _EncabezadoNuevoMedicamento extends StatelessWidget {
  final VoidCallback onCerrar;

  const _EncabezadoNuevoMedicamento({
    required this.onCerrar,
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
          const Icon(
            Icons.medication_liquid_outlined,
            color: _verdeOscuro,
            size: 19,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Nuevo Medicamento',
              style: TextStyle(
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
        value: valor,
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
          child: CustomPaint(
            painter: _DashedBorderPainter(),
            child: const Center(
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
                    'Haz clic o arrastra la imagen del\nproducto aquí',
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

  const _AccionesNuevoMedicamento({
    required this.onCancelar,
    required this.onGuardar,
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
                label: const Text(
                  'Guardar\nMedicamento',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _verdeOscuro,
                    fontSize: 10,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _verde,
                  elevation: 4,
                  shadowColor: _verde.withOpacity(0.35),
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