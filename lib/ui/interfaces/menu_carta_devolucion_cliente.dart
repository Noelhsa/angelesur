import 'package:flutter/material.dart';

import '../../services/devoluciones_api_service.dart';
import '../../services/ventas_api_service.dart';
import '../../utils/config_moneda.dart';

const Color _blanco = Color(0xFFFFFFFF);
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
  final TextEditingController _busquedaController = TextEditingController();
  final TextEditingController _fechaDesdeController = TextEditingController();
  final TextEditingController _fechaHastaController = TextEditingController();
  final TextEditingController _totalMinController = TextEditingController();
  final TextEditingController _totalMaxController = TextEditingController();

  bool _cargando = true;
  bool _cargandoDetalle = false;
  int _solicitudLista = 0;
  int _solicitudDetalle = 0;
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
    _busquedaController.dispose();
    _fechaDesdeController.dispose();
    _fechaHastaController.dispose();
    _totalMinController.dispose();
    _totalMaxController.dispose();
    super.dispose();
  }

  Future<void> _cargarVentas() async {
    final solicitud = ++_solicitudLista;
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final ventas = await widget.ventasApiService.listarVentas(
        busqueda: _textoONulo(_busquedaController.text),
        estatus: 'PAGADA',
        fechaDesde: _textoONulo(_fechaDesdeController.text),
        fechaHasta: _textoONulo(_fechaHastaController.text),
        totalMin: _decimalONulo(_totalMinController.text),
        totalMax: _decimalONulo(_totalMaxController.text),
        limite: 50,
      );

      if (!mounted || solicitud != _solicitudLista) return;

      setState(() {
        _ventas = ventas;
        _cargando = false;
        if (_idVenta != null &&
            !ventas.any((venta) => venta.idVenta == _idVenta)) {
          _idVenta = null;
          _idVentaDetalle = null;
          _ventaDetalle = null;
          ++_solicitudDetalle;
          _cargandoDetalle = false;
        }
        if (ventas.isEmpty) {
          _error = 'No se pudieron cargar ventas registradas';
        }
      });
    } catch (_) {
      if (!mounted || solicitud != _solicitudLista) return;

      setState(() {
        _error = 'No se pudieron cargar ventas registradas';
        _cargando = false;
      });
    }
  }

  Future<void> _seleccionarFecha(TextEditingController controller) async {
    final ahora = DateTime.now();
    final inicial = DateTime.tryParse(controller.text) ?? ahora;
    final fecha = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2020),
      lastDate: DateTime(ahora.year + 2),
    );

    if (fecha == null || !mounted) return;

    controller.text = _formatoFechaApi(fecha);
    _cargarVentas();
  }

  void _limpiarFiltros() {
    _busquedaController.clear();
    _fechaDesdeController.clear();
    _fechaHastaController.clear();
    _totalMinController.clear();
    _totalMaxController.clear();
    _cargarVentas();
  }

  Future<void> _seleccionarVenta(int? idVenta) async {
    if (idVenta == null) return;
    final solicitud = ++_solicitudDetalle;

    setState(() {
      _idVenta = idVenta;
      _idVentaDetalle = null;
      _ventaDetalle = null;
      _cargandoDetalle = true;
      _error = null;
    });

    try {
      final detalle = await widget.ventasApiService.obtenerVenta(idVenta);

      if (!mounted || solicitud != _solicitudDetalle || _idVenta != idVenta) {
        return;
      }

      setState(() {
        _ventaDetalle = detalle;
        _idVentaDetalle = detalle.detalles.isNotEmpty
            ? detalle.detalles.first.idVentaDetalle
            : null;
        _cargandoDetalle = false;
      });
    } catch (_) {
      if (!mounted || solicitud != _solicitudDetalle || _idVenta != idVenta) {
        return;
      }

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
    if (_cargando || _cargandoDetalle || widget.procesando) return;
    final venta = _ventaDetalle;
    final detalle = _detalleSeleccionado();
    final cantidad = int.tryParse(_cantidadController.text.trim()) ?? 0;

    if (venta == null || detalle == null || venta.idVenta != _idVenta) {
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
          _EncabezadoPanel(
            onCerrar: widget.onCerrar,
          ),
          Expanded(
            child: _cargando
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CampoTexto(
                          etiqueta: 'Buscar venta',
                          controller: _busquedaController,
                          hintText: 'Folio, producto, lote, usuario...',
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _cargarVentas(),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _CampoFecha(
                                etiqueta: 'Desde',
                                controller: _fechaDesdeController,
                                onTap: () =>
                                    _seleccionarFecha(_fechaDesdeController),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _CampoFecha(
                                etiqueta: 'Hasta',
                                controller: _fechaHastaController,
                                onTap: () =>
                                    _seleccionarFecha(_fechaHastaController),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _CampoTexto(
                                etiqueta: 'Min',
                                controller: _totalMinController,
                                keyboardType: TextInputType.number,
                                onSubmitted: (_) => _cargarVentas(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _CampoTexto(
                                etiqueta: 'Max',
                                controller: _totalMaxController,
                                keyboardType: TextInputType.number,
                                onSubmitted: (_) => _cargarVentas(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _cargarVentas,
                                icon: const Icon(Icons.search, size: 15),
                                label: const Text('Buscar'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _limpiarFiltros,
                              icon: const Icon(Icons.clear, size: 18),
                              tooltip: 'Limpiar filtros',
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _CampoDropdownInt(
                          etiqueta: 'Venta origen',
                          valor:
                              _ventas.any((venta) => venta.idVenta == _idVenta)
                                  ? _idVenta
                                  : null,
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
                      ],
                    ),
                  ),
          ),
          _AccionesDevolucionCliente(
            procesando: widget.procesando,
            onGuardar: _guardar,
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

class _AccionesDevolucionCliente extends StatelessWidget {
  final bool procesando;
  final VoidCallback onGuardar;

  const _AccionesDevolucionCliente({
    required this.procesando,
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
          onPressed: procesando ? null : onGuardar,
          icon: procesando
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
            procesando ? 'Guardando...' : 'Guardar',
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

class _CampoTexto extends StatelessWidget {
  final String etiqueta;
  final TextEditingController controller;
  final String? hintText;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const _CampoTexto({
    required this.etiqueta,
    required this.controller,
    this.hintText,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return _ContenedorCampo(
      etiqueta: etiqueta,
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
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

class _CampoFecha extends StatelessWidget {
  final String etiqueta;
  final TextEditingController controller;
  final VoidCallback onTap;

  const _CampoFecha({
    required this.etiqueta,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _ContenedorCampo(
      etiqueta: etiqueta,
      child: TextField(
        controller: controller,
        readOnly: true,
        onTap: onTap,
        cursorColor: _verdeOscuro,
        style: const TextStyle(
          color: _textoPrincipal,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        decoration: _decoracionCampo(
          hintText: 'YYYY-MM-DD',
        ).copyWith(
          suffixIcon: const Icon(
            Icons.calendar_today_outlined,
            size: 15,
            color: _textoSecundario,
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 30,
            minHeight: 30,
          ),
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

double? _decimalONulo(String value) {
  final text = value.trim().replaceAll(',', '.');
  if (text.isEmpty) return null;
  return double.tryParse(text);
}

String _formatoFechaApi(DateTime fecha) {
  final mes = fecha.month.toString().padLeft(2, '0');
  final dia = fecha.day.toString().padLeft(2, '0');
  return '${fecha.year}-$mes-$dia';
}
