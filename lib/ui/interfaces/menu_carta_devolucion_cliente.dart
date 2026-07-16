import 'package:flutter/material.dart';

import '../../services/devoluciones_api_service.dart';
import '../../services/ventas_api_service.dart';
import '../../utils/config_moneda.dart';

const Color _fondoPanel = Color(0xFFF8F8F8);
const Color _verdeOscuro = Color(0xFF397800);
const Color _textoPrincipal = Color(0xFF101828);
const Color _textoSecundario = Color(0xFF667085);
const Color _bordeSuave = Color(0xFFD9E6D3);
const Color _grisCampo = Color(0xFFF2F2F2);
const Color _rojo = Color(0xFFE02020);

class MenuCartaDevolucionCliente extends StatefulWidget {
  final int idUsuario;
  final VentasApiService ventasApiService;
  final bool procesando;
  final VoidCallback onCerrar;
  final ValueChanged<RegistrarDevolucionClientePayload> onGuardarDevolucion;

  const MenuCartaDevolucionCliente({
    super.key,
    required this.idUsuario,
    required this.ventasApiService,
    required this.onCerrar,
    required this.onGuardarDevolucion,
    this.procesando = false,
  });

  @override
  State<MenuCartaDevolucionCliente> createState() =>
      _MenuCartaDevolucionClienteState();
}

class _MenuCartaDevolucionClienteState
    extends State<MenuCartaDevolucionCliente> {
  final TextEditingController _cantidadController =
      TextEditingController(text: '1');
  final TextEditingController _observacionesController =
      TextEditingController();

  bool _cargando = true;
  bool _cargandoDetalle = false;
  bool _regresaAInventario = true;

  String? _error;
  String _motivo = 'OTRO';
  String _metodo = 'EFECTIVO';

  List<VentaResumen> _ventas = [];
  VentaDetalleCompleta? _ventaDetalle;

  int? _idVenta;
  int? _idVentaDetalle;

  @override
  void initState() {
    super.initState();
    _cargarVentas();
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _cargarVentas() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final ventas = await widget.ventasApiService.listarVentas(
        estatus: 'REGISTRADA',
        limite: 300,
      );

      if (!mounted) return;

      setState(() {
        _ventas = ventas;
        _cargando = false;
        if (ventas.isEmpty) {
          _error = 'No se pudieron cargar ventas registradas';
        }
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'No se pudieron cargar ventas registradas';
        _cargando = false;
      });
    }
  }

  Future<void> _seleccionarVenta(int? idVenta) async {
    if (idVenta == null) return;

    setState(() {
      _idVenta = idVenta;
      _idVentaDetalle = null;
      _ventaDetalle = null;
      _cargandoDetalle = true;
      _error = null;
    });

    try {
      final detalle = await widget.ventasApiService.obtenerVenta(idVenta);

      if (!mounted) return;

      setState(() {
        _ventaDetalle = detalle;
        _idVentaDetalle = detalle.detalles.isNotEmpty
            ? detalle.detalles.first.idVentaDetalle
            : null;
        _cargandoDetalle = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'No se pudo cargar el detalle de la venta';
        _cargandoDetalle = false;
      });
    }
  }

  VentaProductoDetalle? _detalleSeleccionado() {
    final venta = _ventaDetalle;
    final idDetalle = _idVentaDetalle;

    if (venta == null || idDetalle == null) return null;

    for (final detalle in venta.detalles) {
      if (detalle.idVentaDetalle == idDetalle) {
        return detalle;
      }
    }

    return null;
  }

  void _guardar() {
    final venta = _ventaDetalle;
    final detalle = _detalleSeleccionado();
    final cantidad = int.tryParse(_cantidadController.text.trim()) ?? 0;

    if (venta == null || detalle == null) {
      setState(() {
        _error = 'Selecciona una venta y un producto';
      });
      return;
    }

    if (cantidad <= 0 || cantidad > detalle.cantidad) {
      setState(() {
        _error = 'La cantidad debe estar entre 1 y ${detalle.cantidad}';
      });
      return;
    }

    setState(() {
      _error = null;
    });

    widget.onGuardarDevolucion(
      RegistrarDevolucionClientePayload(
        idUsuario: widget.idUsuario,
        idVenta: venta.idVenta,
        metodoDevolucion: _metodo,
        motivo: _motivo,
        observaciones: _textoONulo(_observacionesController.text),
        detalles: [
          DevolucionClienteDetallePayload(
            idVentaDetalle: detalle.idVentaDetalle,
            cantidad: cantidad,
            regresaAInventario: _regresaAInventario,
            motivoDetalle: _motivo,
            observaciones: _textoONulo(_observacionesController.text),
          ),
        ],
      ),
    );
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
              padding: const EdgeInsets.fromLTRB(12, 18, 12, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _EncabezadoPanel(
                    onCerrar: widget.onCerrar,
                  ),
                  const SizedBox(height: 28),
                  if (_cargando)
                    const SizedBox(
                      height: 180,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else ...[
                    _CampoDropdownInt(
                      etiqueta: 'Venta origen',
                      valor: _idVenta,
                      hintText: 'Seleccione transacción...',
                      opciones: [
                        for (final venta in _ventas)
                          DropdownMenuItem<int>(
                            value: venta.idVenta,
                            child: Text(
                              '${venta.folio} - ${ConfigMoneda.formato(venta.total)}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: _seleccionarVenta,
                    ),
                    if (_cargandoDetalle) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                    ],
                    if (!_cargandoDetalle && _ventaDetalle != null) ...[
                      const SizedBox(height: 18),
                      _CampoDropdownInt(
                        etiqueta: 'Producto devuelto',
                        valor: _idVentaDetalle,
                        hintText: 'Seleccione producto...',
                        opciones: [
                          for (final detalle in _ventaDetalle!.detalles)
                            DropdownMenuItem<int>(
                              value: detalle.idVentaDetalle,
                              child: Text(
                                '${detalle.producto} - cant. ${detalle.cantidad}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _idVentaDetalle = value;
                          });
                        },
                      ),
                    ],
                    const SizedBox(height: 18),
                    _CampoTexto(
                      etiqueta: 'Cantidad',
                      controller: _cantidadController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 18),
                    _CampoDropdownString(
                      etiqueta: 'Método',
                      valor: _metodo,
                      opciones: const [
                        DropdownMenuItem(
                          value: 'EFECTIVO',
                          child: Text('Efectivo'),
                        ),
                        DropdownMenuItem(
                          value: 'ELECTRONICO',
                          child: Text('Electrónico'),
                        ),
                        DropdownMenuItem(
                          value: 'CAMBIO_PRODUCTO',
                          child: Text('Cambio'),
                        ),
                        DropdownMenuItem(
                          value: 'SIN_DEVOLUCION_DINERO',
                          child: Text('Sin dinero'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _metodo = value;
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    _CampoDropdownString(
                      etiqueta: 'Motivo',
                      valor: _motivo,
                      opciones: const [
                        DropdownMenuItem(
                          value: 'PRODUCTO_EQUIVOCADO',
                          child: Text('Producto equivocado'),
                        ),
                        DropdownMenuItem(
                          value: 'PRODUCTO_DANADO',
                          child: Text('Producto dañado'),
                        ),
                        DropdownMenuItem(
                          value: 'CADUCADO',
                          child: Text('Caducado'),
                        ),
                        DropdownMenuItem(
                          value: 'ERROR_VENTA',
                          child: Text('Error de venta'),
                        ),
                        DropdownMenuItem(
                          value: 'CLIENTE_SE_ARREPINTIO',
                          child: Text('Cliente se arrepintió'),
                        ),
                        DropdownMenuItem(
                          value: 'OTRO',
                          child: Text('Otro'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _motivo = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    _CheckRegresaInventario(
                      value: _regresaAInventario,
                      onChanged: (value) {
                        setState(() {
                          _regresaAInventario = value ?? true;
                        });
                      },
                    ),
                    const SizedBox(height: 22),
                    _CampoTexto(
                      etiqueta: 'Observaciones',
                      controller: _observacionesController,
                      hintText: 'Detalle la razón del retorno aquí...',
                      maxLines: 4,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _rojo,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 90),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton(
                        onPressed: widget.procesando ? null : _guardar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _verdeOscuro,
                          disabledBackgroundColor:
                              _verdeOscuro.withOpacity(0.55),
                          elevation: 4,
                          shadowColor: _verdeOscuro.withOpacity(0.25),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          widget.procesando ? 'Guardando...' : 'Guardar',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EncabezadoPanel extends StatelessWidget {
  final VoidCallback onCerrar;

  const _EncabezadoPanel({
    required this.onCerrar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.keyboard_return,
          color: _verdeOscuro,
          size: 17,
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Devolución de cliente',
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
        ),
      ],
    );
  }
}

class _CampoTexto extends StatelessWidget {
  final String etiqueta;
  final TextEditingController controller;
  final String? hintText;
  final int maxLines;
  final TextInputType? keyboardType;

  const _CampoTexto({
    required this.etiqueta,
    required this.controller,
    this.hintText,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return _ContenedorCampo(
      etiqueta: etiqueta,
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        cursorColor: _verdeOscuro,
        style: const TextStyle(
          color: _textoPrincipal,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        decoration: _decoracionCampo(
          hintText: hintText,
        ),
      ),
    );
  }
}

class _CampoDropdownInt extends StatelessWidget {
  final String etiqueta;
  final int? valor;
  final String hintText;
  final List<DropdownMenuItem<int>> opciones;
  final ValueChanged<int?> onChanged;

  const _CampoDropdownInt({
    required this.etiqueta,
    required this.valor,
    required this.hintText,
    required this.opciones,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _ContenedorCampo(
      etiqueta: etiqueta,
      child: DropdownButtonFormField<int>(
        initialValue: valor,
        isExpanded: true,
        icon: const Icon(
          Icons.keyboard_arrow_down,
          color: _textoSecundario,
          size: 18,
        ),
        hint: Text(
          hintText,
          style: const TextStyle(
            color: _textoSecundario,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        decoration: _decoracionCampo(),
        style: const TextStyle(
          color: _textoPrincipal,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        items: opciones,
        onChanged: onChanged,
      ),
    );
  }
}

class _CampoDropdownString extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final List<DropdownMenuItem<String>> opciones;
  final ValueChanged<String?> onChanged;

  const _CampoDropdownString({
    required this.etiqueta,
    required this.valor,
    required this.opciones,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _ContenedorCampo(
      etiqueta: etiqueta,
      child: DropdownButtonFormField<String>(
        initialValue: valor,
        isExpanded: true,
        icon: const Icon(
          Icons.keyboard_arrow_down,
          color: _textoSecundario,
          size: 18,
        ),
        decoration: _decoracionCampo(),
        style: const TextStyle(
          color: _textoPrincipal,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        items: opciones,
        onChanged: onChanged,
      ),
    );
  }
}

class _CheckRegresaInventario extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _CheckRegresaInventario({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: _verdeOscuro,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'Regresa a inventario',
          style: TextStyle(
            color: _textoPrincipal,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ContenedorCampo extends StatelessWidget {
  final String etiqueta;
  final Widget child;

  const _ContenedorCampo({
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
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

InputDecoration _decoracionCampo({
  String? hintText,
}) {
  return InputDecoration(
    filled: true,
    fillColor: _grisCampo,
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

String? _textoONulo(String value) {
  final text = value.trim();
  return text.isEmpty ? null : text;
}