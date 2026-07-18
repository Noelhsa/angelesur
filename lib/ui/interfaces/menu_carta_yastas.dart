import 'package:flutter/material.dart';

const Color _fondoPanel = Color(0xFFF8F8F8);
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
    return double.tryParse(controller.text.trim().replaceAll(',', '.'));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: double.infinity,
      decoration: BoxDecoration(
        color: _fondoPanel,
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TituloPanelYastas(
                    onCerrar: widget.onCerrar,
                  ),
                  const SizedBox(height: 28),
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
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: widget.guardando ? null : _guardar,
                      icon: widget.guardando
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
                        widget.guardando ? 'Guardando...' : 'Guardar Tarifa',
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
    return Row(
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
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        IconButton(
          onPressed: onCerrar,
          icon: const Icon(
            Icons.close,
            color: _textoSecundario,
            size: 18,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 28,
            minHeight: 28,
          ),
          tooltip: 'Cerrar',
        ),
      ],
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

  const _CampoDineroYastas({
    required this.etiqueta,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return _ContenedorCampoYastas(
      etiqueta: etiqueta,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
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
