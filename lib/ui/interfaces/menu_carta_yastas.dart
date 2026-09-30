import 'package:flutter/material.dart';
import '../../utils/importe_input.dart';

const Color _blanco = Color(0xFFFFFFFF);
const Color _verdeOscuro = Color(0xFF397800);
const Color _textoPrincipal = Color(0xFF101828);
const Color _textoSecundario = Color(0xFF667085);
const Color _bordeSuave = Color(0xFFD9E6D3);
const Color _grisCampo = Color(0xFFF2F2F2);

class DatosMenuTarifaYastas {
  final String tipoServicio;
  final String nombreServicio;
  final double comisionCliente;
  final double comisionYastas;
  final double regaliaYastas;
  final double gananciaFarmacia;

  const DatosMenuTarifaYastas({
    required this.tipoServicio,
    required this.nombreServicio,
    required this.comisionCliente,
    required this.comisionYastas,
    required this.regaliaYastas,
    required this.gananciaFarmacia,
  });
}

class MenuCartaYastas extends StatefulWidget {
  final VoidCallback onCerrar;
  final ValueChanged<DatosMenuTarifaYastas> onGuardarTarifa;
  final bool guardando;

  const MenuCartaYastas({
    super.key,
    required this.onCerrar,
    required this.onGuardarTarifa,
    this.guardando = false,
  });

  @override
  State<MenuCartaYastas> createState() => _MenuCartaYastasState();
}

class _MenuCartaYastasState extends State<MenuCartaYastas> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _comisionClienteController =
      TextEditingController(
    text: '0.00',
  );
  final TextEditingController _comisionYastasController = TextEditingController(
    text: '0.00',
  );
  final TextEditingController _regaliaController = TextEditingController(
    text: '0.00',
  );
  final TextEditingController _gananciaController = TextEditingController(
    text: '0.00',
  );

  String _tipoServicio = 'RECARGA';
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _comisionClienteController,
      _comisionYastasController,
      _regaliaController
    ]) {
      controller.addListener(_actualizarGanancia);
    }
  }

  void _actualizarGanancia() {
    final centavos =
        ((_leerMonto(_comisionClienteController) ?? 0) * 100).round() -
            ((_leerMonto(_comisionYastasController) ?? 0) * 100).round() -
            ((_leerMonto(_regaliaController) ?? 0) * 100).round();
    _gananciaController.text =
        (centavos.clamp(0, double.infinity) / 100).toStringAsFixed(2);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _comisionClienteController.dispose();
    _comisionYastasController.dispose();
    _regaliaController.dispose();
    _gananciaController.dispose();
    super.dispose();
  }

  void _guardar() {
    final nombre = _nombreController.text.trim();
    final comisionCliente = _leerMonto(_comisionClienteController);
    final comisionYastas = _leerMonto(_comisionYastasController);
    final regalia = _leerMonto(_regaliaController);
    final ganancia = _leerMonto(_gananciaController);

    if (nombre.isEmpty) {
      setState(() {
        _error = 'El nombre del servicio es obligatorio';
      });
      return;
    }

    if ([comisionCliente, comisionYastas, regalia, ganancia]
        .any((value) => value == null || value < 0)) {
      setState(() {
        _error = 'Los importes deben ser mayores o iguales a cero';
      });
      return;
    }

    final reparto = comisionYastas! + regalia! + ganancia!;
    if (reparto > comisionCliente! + 0.005) {
      setState(() {
        _error = 'El reparto no puede superar la comision cobrada al cliente';
      });
      return;
    }

    setState(() {
      _error = null;
    });

    widget.onGuardarTarifa(
      DatosMenuTarifaYastas(
        tipoServicio: _tipoServicio,
        nombreServicio: nombre,
        comisionCliente: comisionCliente,
        comisionYastas: comisionYastas,
        regaliaYastas: regalia,
        gananciaFarmacia: ganancia,
      ),
    );
  }

  double? _leerMonto(TextEditingController controller) {
    return leerImporte(controller.text);
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
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _TituloPanelYastas(
            onCerrar: widget.onCerrar,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CampoDropdownYastas(
                    etiqueta: 'Tipo de servicio',
                    valor: _tipoServicio,
                    opciones: const [
                      DropdownMenuItem(
                        value: 'RECARGA',
                        child: Text('Recarga'),
                      ),
                      DropdownMenuItem(
                        value: 'DEPOSITO',
                        child: Text('Deposito'),
                      ),
                      DropdownMenuItem(
                        value: 'RETIRO',
                        child: Text('Retiro'),
                      ),
                      DropdownMenuItem(
                        value: 'PAGO_SERVICIO',
                        child: Text('Pago de servicio'),
                      ),
                      DropdownMenuItem(
                        value: 'CFE',
                        child: Text('CFE'),
                      ),
                      DropdownMenuItem(
                        value: 'TELMEX',
                        child: Text('Telmex'),
                      ),
                      DropdownMenuItem(
                        value: 'IZZI',
                        child: Text('Izzi'),
                      ),
                      DropdownMenuItem(
                        value: 'INTERNET',
                        child: Text('Internet'),
                      ),
                      DropdownMenuItem(
                        value: 'OTRO',
                        child: Text('Otro'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        _tipoServicio = value;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  _CampoTextoYastas(
                    etiqueta: 'Nombre del servicio',
                    controller: _nombreController,
                    hintText: 'Ej. Recarga Telcel',
                  ),
                  const SizedBox(height: 18),
                  _CampoDineroYastas(
                    etiqueta: 'Comisión cliente',
                    controller: _comisionClienteController,
                  ),
                  const SizedBox(height: 18),
                  _CampoDineroYastas(
                    etiqueta: 'Comisión Yastas',
                    controller: _comisionYastasController,
                  ),
                  const SizedBox(height: 18),
                  _CampoDineroYastas(
                    etiqueta: 'Regalía Yastas',
                    controller: _regaliaController,
                  ),
                  const SizedBox(height: 18),
                  const Divider(color: _bordeSuave),
                  const SizedBox(height: 10),
                  _CampoDineroYastas(
                    etiqueta: 'Ganancia farmacia',
                    controller: _gananciaController,
                    readOnly: true,
                  ),
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
          _AccionesYastas(
            guardando: widget.guardando,
            onGuardar: _guardar,
          ),
        ],
      ),
    );
  }
}

class _TituloPanelYastas extends StatelessWidget {
  final VoidCallback onCerrar;

  const _TituloPanelYastas({
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
            Icons.receipt_long_outlined,
            color: _verdeOscuro,
            size: 17,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Nueva tarifa',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }
}

class _CampoTextoYastas extends StatelessWidget {
  final String etiqueta;
  final TextEditingController controller;
  final String? hintText;

  const _CampoTextoYastas({
    required this.etiqueta,
    required this.controller,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return _ContenedorCampoYastas(
      etiqueta: etiqueta,
      child: TextField(
        controller: controller,
        cursorColor: _verdeOscuro,
        style: const TextStyle(
          color: _textoPrincipal,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        decoration: _decoracionCampoYastas(
          hintText: hintText,
        ),
      ),
    );
  }
}

class _CampoDineroYastas extends StatelessWidget {
  final String etiqueta;
  final TextEditingController controller;
  final bool readOnly;

  const _CampoDineroYastas({
    required this.etiqueta,
    required this.controller,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return _ContenedorCampoYastas(
      etiqueta: etiqueta,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        readOnly: readOnly,
        inputFormatters: const [ImporteInputFormatter()],
        cursorColor: _verdeOscuro,
        style: const TextStyle(
          color: _textoPrincipal,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
        decoration: _decoracionCampoYastas(
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 12, right: 8),
            child: Text(
              '\$',
              style: TextStyle(
                color: _verdeOscuro,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CampoDropdownYastas extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final List<DropdownMenuItem<String>> opciones;
  final ValueChanged<String?> onChanged;

  const _CampoDropdownYastas({
    required this.etiqueta,
    required this.valor,
    required this.opciones,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _ContenedorCampoYastas(
      etiqueta: etiqueta,
      child: DropdownButtonFormField<String>(
        initialValue: valor,
        isExpanded: true,
        icon: const Icon(
          Icons.keyboard_arrow_down,
          color: _textoSecundario,
          size: 18,
        ),
        decoration: _decoracionCampoYastas(),
        style: const TextStyle(
          color: _textoPrincipal,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        items: opciones,
        onChanged: onChanged,
      ),
    );
  }
}

class _ContenedorCampoYastas extends StatelessWidget {
  final String etiqueta;
  final Widget child;

  const _ContenedorCampoYastas({
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

class _AccionesYastas extends StatelessWidget {
  final bool guardando;
  final VoidCallback onGuardar;

  const _AccionesYastas({
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
      child: SizedBox(
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
                    color: Colors.white,
                  ),
                )
              : const Icon(
                  Icons.save_outlined,
                  color: Colors.white,
                  size: 14,
                ),
          label: Text(
            guardando ? 'Guardando...' : 'Guardar Tarifa',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _verdeOscuro,
            disabledBackgroundColor: _verdeOscuro.withOpacity(0.55),
            elevation: 4,
            shadowColor: _verdeOscuro.withOpacity(0.25),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _decoracionCampoYastas({
  String? hintText,
  Widget? prefixIcon,
  Color fillColor = _grisCampo,
}) {
  return InputDecoration(
    filled: true,
    fillColor: fillColor,
    hintText: hintText,
    hintStyle: const TextStyle(
      color: _textoSecundario,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    ),
    prefixIcon: prefixIcon,
    prefixIconConstraints: const BoxConstraints(
      minWidth: 32,
      minHeight: 0,
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 11,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(
        color: Color(0xFFE0E0E0),
        width: 1,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(
        color: Color(0xFFE0E0E0),
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
