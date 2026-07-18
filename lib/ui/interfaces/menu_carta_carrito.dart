import 'package:flutter/material.dart';

import '../../models/medicamento.dart';
import '../../utils/config_moneda.dart';

const Color _blanco = Color(0xFFFFFFFF);
const Color _verde = Color(0xFF58D000);
const Color _verdeOscuro = Color(0xFF2F6E00);
const Color _texto = Color(0xFF101010);
const Color _textoSuave = Color(0xFF707A83);
const Color _grisLinea = Color(0xFFE0E0E0);
const Color _rojo = Color(0xFFE21F1F);

const Color _fondoMontoPago = Color(0xFFF1F8E8);
const Color _fondoBotonRapido = Color(0xFFE9EAEC);
const Color _fondoCambio = Color(0xFFF0F1F2);
const Color _bordeDialogo = Color(0xFFD8DDD3);
const Color _bordeCampoPago = Color(0xFFBBC6B3);
const Color _fondoAccionesPago = Color(0xFFF6F7F5);

class DatosPagoVenta {
  final String medio;
  final double? montoRecibido;
  final String? referencia;

  const DatosPagoVenta({
    required this.medio,
    required this.montoRecibido,
    required this.referencia,
  });
}

Future<DatosPagoVenta?> mostrarDialogoPagoVenta({
  required BuildContext context,
  required double total,
}) {
  return showDialog<DatosPagoVenta>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _DialogoPagoVenta(
      total: total,
    ),
  );
}

class _DialogoPagoVenta extends StatefulWidget {
  final double total;

  const _DialogoPagoVenta({
    required this.total,
  });

  @override
  State<_DialogoPagoVenta> createState() => _DialogoPagoVentaState();
}

class _DialogoPagoVentaState extends State<_DialogoPagoVenta> {
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();

  String _medio = 'EFECTIVO';
  String? _error;
  bool _imprimirTicket = true;

  bool get _esEfectivo => _medio == 'EFECTIVO';

  double? get _montoRecibido {
    final texto = _montoController.text
        .trim()
        .replaceAll(',', '')
        .replaceAll('\$', '');

    return double.tryParse(texto);
  }

  double get _cambio {
    final recibido = _montoRecibido ?? 0;
    final cambio = recibido - widget.total;

    return cambio > 0 ? cambio : 0;
  }

  @override
  void initState() {
    super.initState();

    _montoController.text = '0.00';
  }

  @override
  void dispose() {
    _montoController.dispose();
    _referenciaController.dispose();
    super.dispose();
  }

  void _cambiarMedioPago(String? value) {
    if (value == null) {
      return;
    }

    setState(() {
      _medio = value;
      _error = null;

      if (_esEfectivo && _montoController.text.trim().isEmpty) {
        _montoController.text = widget.total.toStringAsFixed(2);
      }
    });
  }

  void _seleccionarMontoRapido(double monto) {
    setState(() {
      _montoController.text = monto.toStringAsFixed(2);

      _montoController.selection = TextSelection.collapsed(
        offset: _montoController.text.length,
      );

      _error = null;
    });
  }

  void _confirmar() {
    final montoRecibido = _montoRecibido;

    if (_esEfectivo &&
        (montoRecibido == null || montoRecibido < widget.total)) {
      setState(() {
        _error = 'El efectivo recibido debe cubrir el total';
      });
      return;
    }

    Navigator.of(context).pop(
      DatosPagoVenta(
        medio: _medio,
        montoRecibido: _esEfectivo ? montoRecibido : null,
        referencia: _limpiarReferencia(_referenciaController.text),
      ),
    );
  }

  String? _limpiarReferencia(String value) {
    final referencia = value.trim();

    return referencia.isEmpty ? null : referencia;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _blanco,
      insetPadding: const EdgeInsets.all(24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(
          color: _bordeDialogo,
          width: 1,
        ),
      ),
      child: SizedBox(
        width: 410,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _EncabezadoDialogoPago(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TarjetaMontoTotal(
                      total: widget.total,
                    ),
                    const SizedBox(height: 26),
                    const _EtiquetaCampoPago(
                      texto: 'Método de pago',
                    ),
                    const SizedBox(height: 6),
                    _SelectorMetodoPago(
                      medio: _medio,
                      onChanged: _cambiarMedioPago,
                    ),
                    const SizedBox(height: 18),
                    if (_esEfectivo) ...[
                      const _EtiquetaCampoPago(
                        texto: 'Acceso rápido (Efectivo)',
                      ),
                      const SizedBox(height: 10),
                      _AccesosRapidosPago(
                        onSeleccionar: _seleccionarMontoRapido,
                      ),
                      const SizedBox(height: 18),
                      const _EtiquetaCampoPago(
                        texto: 'Cantidad recibida',
                      ),
                      const SizedBox(height: 6),
                      _CampoCantidadRecibida(
                        controller: _montoController,
                        onChanged: (_) {
                          setState(() {
                            _error = null;
                          });
                        },
                      ),
                      const SizedBox(height: 26),
                      _TarjetaCambio(
                        cambio: _cambio,
                      ),
                    ] else ...[
                      const _EtiquetaCampoPago(
                        texto: 'Referencia',
                      ),
                      const SizedBox(height: 6),
                      _CampoReferenciaPago(
                        controller: _referenciaController,
                        onChanged: (_) {
                          setState(() {
                            _error = null;
                          });
                        },
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      _MensajeErrorPago(
                        mensaje: _error!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            _OpcionImprimirTicket(
              activo: _imprimirTicket,
              onChanged: (value) {
                setState(() {
                  _imprimirTicket = value;
                });
              },
            ),
            _AccionesDialogoPago(
              onCancelar: () => Navigator.of(context).pop(),
              onConfirmar: _confirmar,
            ),
          ],
        ),
      ),
    );
  }
}

class _EncabezadoDialogoPago extends StatelessWidget {
  const _EncabezadoDialogoPago();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: _blanco,
        border: Border(
          bottom: BorderSide(
            color: _grisLinea,
            width: 1,
          ),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.payments_outlined,
            color: _verdeOscuro,
            size: 18,
          ),
          SizedBox(width: 8),
          Text(
            'Registrar pago',
            style: TextStyle(
              color: _texto,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaMontoTotal extends StatelessWidget {
  final double total;

  const _TarjetaMontoTotal({
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 82,
      decoration: BoxDecoration(
        color: _fondoMontoPago,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFDCECCF),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Monto Total',
            style: TextStyle(
              color: _verdeOscuro,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            ConfigMoneda.formato(total),
            style: const TextStyle(
              color: _verdeOscuro,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EtiquetaCampoPago extends StatelessWidget {
  final String texto;

  const _EtiquetaCampoPago({
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        color: _textoSuave,
        fontSize: 9,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _SelectorMetodoPago extends StatelessWidget {
  final String medio;
  final ValueChanged<String?> onChanged;

  const _SelectorMetodoPago({
    required this.medio,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: medio,
      isExpanded: true,
      icon: const Icon(
        Icons.keyboard_arrow_down,
        color: _textoSuave,
        size: 19,
      ),
      style: const TextStyle(
        color: _texto,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: _blanco,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(
            color: _bordeCampoPago,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(
            color: _verdeOscuro,
            width: 1.4,
          ),
        ),
        isDense: true,
      ),
      items: const [
        DropdownMenuItem(
          value: 'EFECTIVO',
          child: Text('Efectivo'),
        ),
        DropdownMenuItem(
          value: 'TARJETA',
          child: Text('Tarjeta'),
        ),
        DropdownMenuItem(
          value: 'TRANSFERENCIA',
          child: Text('Transferencia'),
        ),
        DropdownMenuItem(
          value: 'ELECTRONICO',
          child: Text('Electrónico'),
        ),
        DropdownMenuItem(
          value: 'OTRO',
          child: Text('Otro'),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _AccesosRapidosPago extends StatelessWidget {
  final ValueChanged<double> onSeleccionar;

  const _AccesosRapidosPago({
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    const montos = <double>[
      20,
      50,
      100,
      200,
      500,
      1000,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const separacion = 8.0;

        final anchoBoton =
            (constraints.maxWidth - (separacion * 2)) / 3;

        return Wrap(
          spacing: separacion,
          runSpacing: separacion,
          children: [
            for (final monto in montos)
              SizedBox(
                width: anchoBoton,
                child: _BotonMontoRapido(
                  monto: monto,
                  onTap: () => onSeleccionar(monto),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BotonMontoRapido extends StatelessWidget {
  final double monto;
  final VoidCallback onTap;

  const _BotonMontoRapido({
    required this.monto,
    required this.onTap,
  });

  String get _texto {
    if (monto == 1000) {
      return '\$ 1,000';
    }

    return '\$ ${monto.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: Material(
        color: _fondoBotonRapido,
        borderRadius: BorderRadius.circular(5),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(5),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                _texto,
                style: const TextStyle(
                  color: Color(0xFF525B63),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CampoCantidadRecibida extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _CampoCantidadRecibida({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      style: const TextStyle(
        color: _verdeOscuro,
        fontSize: 17,
        fontWeight: FontWeight.w900,
      ),
      decoration: InputDecoration(
        prefixText: '\$  ',
        prefixStyle: const TextStyle(
          color: _texto,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        filled: true,
        fillColor: _blanco,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(
            color: _bordeCampoPago,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(
            color: _verdeOscuro,
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(
            color: _rojo,
          ),
        ),
        isDense: true,
      ),
    );
  }
}

class _CampoReferenciaPago extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _CampoReferenciaPago({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(
        color: _texto,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: 'Número de autorización, folio o referencia',
        hintStyle: const TextStyle(
          color: Color(0xFF9AA19B),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: _blanco,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(
            color: _bordeCampoPago,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(
            color: _verdeOscuro,
            width: 1.4,
          ),
        ),
        isDense: true,
      ),
    );
  }
}

class _TarjetaCambio extends StatelessWidget {
  final double cambio;

  const _TarjetaCambio({
    required this.cambio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _fondoCambio,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFE0E2E3),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Cambio a entregar:',
              style: TextStyle(
                color: _textoSuave,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            ConfigMoneda.formato(cambio),
            style: const TextStyle(
              color: _verdeOscuro,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MensajeErrorPago extends StatelessWidget {
  final String mensaje;

  const _MensajeErrorPago({
    required this.mensaje,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _OpcionImprimirTicket extends StatelessWidget {
  final bool activo;
  final ValueChanged<bool> onChanged;

  const _OpcionImprimirTicket({
    required this.activo,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: const BoxDecoration(
        color: _blanco,
        border: Border(
          top: BorderSide(
            color: _grisLinea,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.print_outlined,
            color: _verdeOscuro,
            size: 17,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '¿Imprimir ticket?',
              style: TextStyle(
                color: _texto,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.78,
            child: Switch(
              value: activo,
              onChanged: onChanged,
              activeThumbColor: _blanco,
              activeTrackColor: _verdeOscuro,
              inactiveThumbColor: _blanco,
              inactiveTrackColor: const Color(0xFFBFC4BD),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccionesDialogoPago extends StatelessWidget {
  final VoidCallback onCancelar;
  final VoidCallback onConfirmar;

  const _AccionesDialogoPago({
    required this.onCancelar,
    required this.onConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
      decoration: const BoxDecoration(
        color: _fondoAccionesPago,
        border: Border(
          top: BorderSide(
            color: _grisLinea,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 40,
              child: OutlinedButton(
                onPressed: onCancelar,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _texto,
                  side: const BorderSide(
                    color: Color(0xFF9EA79A),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: const Text(
                  'Cancelar venta',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                onPressed: onConfirmar,
                icon: const Icon(
                  Icons.check_circle_outline,
                  color: _blanco,
                  size: 17,
                ),
                label: const Text(
                  'Confirmar venta',
                  style: TextStyle(
                    color: _blanco,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  elevation: 4,
                  shadowColor: _verdeOscuro.withOpacity(0.30),
                  backgroundColor: _verdeOscuro,
                  foregroundColor: _blanco,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
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

class MenuCartaCarrito extends StatelessWidget {
  final List<Medicamento> medicamentos;
  final Map<int, int> cantidades;
  final double subtotal;
  final double descuento;
  final double total;
  final ValueChanged<int> onIncrementar;
  final ValueChanged<int> onDisminuir;
  final ValueChanged<int> onEliminar;
  final VoidCallback onPagar;
  final bool procesandoPago;

  const MenuCartaCarrito({
    super.key,
    required this.medicamentos,
    required this.cantidades,
    required this.subtotal,
    required this.descuento,
    required this.total,
    required this.onIncrementar,
    required this.onDisminuir,
    required this.onEliminar,
    required this.onPagar,
    this.procesandoPago = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 234,
      margin: const EdgeInsets.only(
        top: 20,
        right: 20,
        bottom: 20,
      ),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _blanco,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 51,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: _grisLinea,
                  width: 1,
                ),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.shopping_basket_outlined,
                  size: 16,
                  color: _verdeOscuro,
                ),
                SizedBox(width: 8),
                Text(
                  'Carrito',
                  style: TextStyle(
                    color: _texto,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: medicamentos.isEmpty
                ? const Center(
                    child: Text(
                      'Carrito vacío',
                      style: TextStyle(
                        color: _textoSuave,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(15, 13, 15, 10),
                    itemCount: medicamentos.length,
                    itemBuilder: (context, index) {
                      final medicamento = medicamentos[index];
                      final cantidad = cantidades[medicamento.id] ?? 0;

                      return _ItemCarrito(
                        medicamento: medicamento,
                        cantidad: cantidad,
                        onIncrementar: () {
                          onIncrementar(medicamento.id);
                        },
                        onDisminuir: () {
                          onDisminuir(medicamento.id);
                        },
                        onEliminar: () {
                          onEliminar(medicamento.id);
                        },
                      );
                    },
                  ),
          ),
          _ResumenCarrito(
            subtotal: subtotal,
            descuento: descuento,
            total: total,
            onPagar: onPagar,
            procesandoPago: procesandoPago,
          ),
        ],
      ),
    );
  }
}

class _ItemCarrito extends StatelessWidget {
  final Medicamento medicamento;
  final int cantidad;
  final VoidCallback onIncrementar;
  final VoidCallback onDisminuir;
  final VoidCallback onEliminar;

  const _ItemCarrito({
    required this.medicamento,
    required this.cantidad,
    required this.onIncrementar,
    required this.onDisminuir,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final importe = medicamento.precio * cantidad;

    return Container(
      height: 57,
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ImagenCarrito(
            medicamentoId: medicamento.id,
            imagenAsset: medicamento.imagenAsset,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicamento.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _texto,
                      fontSize: 7.4,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${ConfigMoneda.formato(medicamento.precio)} c/u',
                    style: const TextStyle(
                      color: Color(0xFF8D8D8D),
                      fontSize: 6.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _ControlCantidad(
                    cantidad: cantidad,
                    onIncrementar: onIncrementar,
                    onDisminuir: onDisminuir,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 46,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                ConfigMoneda.formato(importe),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: _texto,
                  fontSize: 7.8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(top: 22),
            child: InkWell(
              onTap: onEliminar,
              child: const Icon(
                Icons.delete_outline,
                size: 13,
                color: _rojo,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlCantidad extends StatelessWidget {
  final int cantidad;
  final VoidCallback onIncrementar;
  final VoidCallback onDisminuir;

  const _ControlCantidad({
    required this.cantidad,
    required this.onIncrementar,
    required this.onDisminuir,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 19,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          _BotonCantidad(
            texto: '-',
            onTap: onDisminuir,
          ),
          Expanded(
            child: Center(
              child: Text(
                '$cantidad',
                style: const TextStyle(
                  color: _texto,
                  fontSize: 7.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          _BotonCantidad(
            texto: '+',
            onTap: onIncrementar,
          ),
        ],
      ),
    );
  }
}

class _BotonCantidad extends StatelessWidget {
  final String texto;
  final VoidCallback onTap;

  const _BotonCantidad({
    required this.texto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 19,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Text(
            texto,
            style: const TextStyle(
              color: _texto,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResumenCarrito extends StatelessWidget {
  final double subtotal;
  final double descuento;
  final double total;
  final VoidCallback onPagar;
  final bool procesandoPago;

  const _ResumenCarrito({
    required this.subtotal,
    required this.descuento,
    required this.total,
    required this.onPagar,
    required this.procesandoPago,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 178,
      padding: const EdgeInsets.fromLTRB(15, 18, 15, 20),
      decoration: const BoxDecoration(
        color: _blanco,
        border: Border(
          top: BorderSide(
            color: _grisLinea,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _FilaResumen(
            texto: 'Subtotal',
            valor: ConfigMoneda.formato(subtotal),
            color: _texto,
          ),
          const SizedBox(height: 11),
          _FilaResumen(
            texto: 'Descuento (Cupón: SALUD10)',
            valor: '-${ConfigMoneda.formato(descuento)}',
            color: _rojo,
          ),
          const SizedBox(height: 9),
          Container(
            height: 1,
            color: _grisLinea,
          ),
          const SizedBox(height: 9),
          _FilaResumen(
            texto: 'Total',
            valor: ConfigMoneda.formato(total),
            color: _verdeOscuro,
            grande: true,
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton.icon(
              onPressed: total <= 0 || procesandoPago
                  ? null
                  : onPagar,
              icon: const Icon(
                Icons.payments_outlined,
                size: 15,
                color: _verdeOscuro,
              ),
              label: Text(
                procesandoPago ? 'Procesando...' : 'Pagar',
                style: const TextStyle(
                  color: _verdeOscuro,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: ElevatedButton.styleFrom(
                elevation: 8,
                shadowColor: _verde.withOpacity(.35),
                backgroundColor: _verde,
                disabledBackgroundColor: const Color(0xFFBEBEBE),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaResumen extends StatelessWidget {
  final String texto;
  final String valor;
  final Color color;
  final bool grande;

  const _FilaResumen({
    required this.texto,
    required this.valor,
    required this.color,
    this.grande = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            texto,
            style: TextStyle(
              color: color,
              fontSize: grande ? 14 : 8,
              fontWeight: grande
                  ? FontWeight.w900
                  : FontWeight.w600,
            ),
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            color: color,
            fontSize: grande ? 14 : 8,
            fontWeight: grande
                ? FontWeight.w900
                : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ImagenCarrito extends StatelessWidget {
  final int medicamentoId;
  final String? imagenAsset;

  const _ImagenCarrito({
    required this.medicamentoId,
    required this.imagenAsset,
  });

  @override
  Widget build(BuildContext context) {
    const double size = 39;

    if (imagenAsset != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Image.asset(
          imagenAsset!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _colorImagenBase(medicamentoId),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Center(
        child: _IlustracionCarrito(
          medicamentoId: medicamentoId,
        ),
      ),
    );
  }

  Color _colorImagenBase(int id) {
    switch (id) {
      case 1:
        return const Color(0xFFF3F5F5);

      case 2:
        return const Color(0xFFEFEFEA);

      case 3:
        return const Color(0xFFF4F4F0);

      case 4:
        return const Color(0xFF0B4B43);

      case 5:
        return const Color(0xFFB9D9D4);

      default:
        return const Color(0xFFF3F5F5);
    }
  }
}

class _IlustracionCarrito extends StatelessWidget {
  final int medicamentoId;

  const _IlustracionCarrito({
    required this.medicamentoId,
  });

  @override
  Widget build(BuildContext context) {
    switch (medicamentoId) {
      case 1:
        return Transform.scale(
          scale: .42,
          child: _CajaCarrito(
            texto: 'Paracetamol',
            colorPrincipal: const Color(0xFF55BFD2),
            colorSecundario: const Color(0xFFE9F6FA),
          ),
        );

      case 2:
        return Transform.scale(
          scale: .42,
          child: const _FrascoCarrito(),
        );

      case 3:
        return Transform.scale(
          scale: .42,
          child: _CajaCarrito(
            texto: 'Ibuprofeno',
            colorPrincipal: const Color(0xFFFF8500),
            colorSecundario: const Color(0xFFFFF0DE),
          ),
        );

      case 4:
        return Transform.scale(
          scale: .42,
          child: _CajaCarrito(
            texto: 'Ome',
            colorPrincipal: const Color(0xFF0F8B70),
            colorSecundario: const Color(0xFFE7FFF8),
          ),
        );

      case 5:
        return Transform.rotate(
          angle: -0.2,
          child: const Icon(
            Icons.thermostat,
            size: 25,
            color: Color(0xFF4E7B78),
          ),
        );

      default:
        return const Icon(
          Icons.medication_outlined,
          size: 21,
          color: Color(0xFF6A7B84),
        );
    }
  }
}

class _CajaCarrito extends StatelessWidget {
  final String texto;
  final Color colorPrincipal;
  final Color colorSecundario;

  const _CajaCarrito({
    required this.texto,
    required this.colorPrincipal,
    required this.colorSecundario,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 46,
      decoration: BoxDecoration(
        color: _blanco,
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 6,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 14,
              color: colorSecundario,
            ),
          ),
          Positioned(
            left: 7,
            top: 13,
            child: Text(
              texto,
              style: TextStyle(
                color: colorPrincipal,
                fontSize: 7,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 7,
            child: Container(
              height: 4,
              color: colorPrincipal,
            ),
          ),
        ],
      ),
    );
  }
}

class _FrascoCarrito extends StatelessWidget {
  const _FrascoCarrito();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFFD9D9D9),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(2),
            ),
          ),
        ),
        Container(
          width: 34,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF965D28),
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.14),
                blurRadius: 6,
                offset: const Offset(2, 3),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 28,
              height: 15,
              color: _blanco,
            ),
          ),
        ),
      ],
    );
  }
}