import 'package:flutter/material.dart';

import '../../services/compras_api_service.dart';
import '../../services/devoluciones_api_service.dart';

const Color _blanco = Color(0xFFFFFFFF);
const Color _verdeOscuro = Color(0xFF397800);
const Color _textoPrincipal = Color(0xFF101828);
const Color _textoSecundario = Color(0xFF667085);
const Color _bordeSuave = Color(0xFFD9E6D3);
const Color _grisCampo = Color(0xFFF2F2F2);
const Color _rojo = Color(0xFFE02020);

class MenuCartaDevolucionProveedor extends StatefulWidget {
  final int idUsuario;
  final ComprasApiService comprasApiService;
  final bool procesando;
  final VoidCallback onCerrar;
  final ValueChanged<RegistrarDevolucionProveedorPayload> onGuardarDevolucion;

  const MenuCartaDevolucionProveedor({
    super.key,
    required this.idUsuario,
    required this.comprasApiService,
    required this.onCerrar,
    required this.onGuardarDevolucion,
    this.procesando = false,
  });

  @override
  State<MenuCartaDevolucionProveedor> createState() =>
      _MenuCartaDevolucionProveedorState();
}

class _MenuCartaDevolucionProveedorState
    extends State<MenuCartaDevolucionProveedor> {
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
  int _pagina = 1;
  int _totalPaginas = 1;
  int _total = 0;

  String? _error;
  String _motivo = 'OTRO';
  String _compensacion = 'SIN_COMPENSACION';

  List<CompraResumen> _compras = [];
  CompraDetalle? _compraDetalle;

  int? _idCompra;
  int? _idCompraDetalle;

  @override
  void initState() {
    super.initState();
    _cargarCompras();
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

  Future<void> _cargarCompras({int pagina = 1}) async {
    final solicitud = ++_solicitudLista;
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final resultado = await widget.comprasApiService.listarComprasPaginadas(
        busqueda: _textoONulo(_busquedaController.text),
        estatus: 'REGISTRADA',
        fechaDesde: _textoONulo(_fechaDesdeController.text),
        fechaHasta: _textoONulo(_fechaHastaController.text),
        totalMin: _decimalONulo(_totalMinController.text),
        totalMax: _decimalONulo(_totalMaxController.text),
        pagina: pagina,
        limite: 25,
      );

      final compras = resultado.items;

      if (!mounted || solicitud != _solicitudLista) return;

      setState(() {
        _compras = compras;
        _pagina = resultado.pagina;
        _totalPaginas = resultado.totalPaginas;
        _total = resultado.total;
        _cargando = false;

        if (_idCompra != null &&
            !compras.any((compra) => compra.idCompra == _idCompra)) {
          _idCompra = null;
          _idCompraDetalle = null;
          _compraDetalle = null;
          ++_solicitudDetalle;
          _cargandoDetalle = false;
        }

        if (compras.isEmpty) {
          _error = 'No se pudieron cargar compras registradas';
        }
      });
    } catch (_) {
      if (!mounted || solicitud != _solicitudLista) return;

      setState(() {
        _error = 'No se pudieron cargar compras registradas';
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
    _cargarCompras(pagina: 1);
  }

  void _limpiarFiltros() {
    _busquedaController.clear();
    _fechaDesdeController.clear();
    _fechaHastaController.clear();
    _totalMinController.clear();
    _totalMaxController.clear();
    _cargarCompras(pagina: 1);
  }

  Future<void> _seleccionarCompra(int? idCompra) async {
    if (idCompra == null) return;
    final solicitud = ++_solicitudDetalle;

    setState(() {
      _idCompra = idCompra;
      _idCompraDetalle = null;
      _compraDetalle = null;
      _cargandoDetalle = true;
      _error = null;
    });

    try {
      final detalle = await widget.comprasApiService.obtenerCompra(idCompra);

      if (!mounted || solicitud != _solicitudDetalle || _idCompra != idCompra) {
        return;
      }

      setState(() {
        _compraDetalle = detalle;
        _idCompraDetalle = detalle.detalles.isNotEmpty
            ? detalle.detalles.first.idCompraDetalle
            : null;
        _cargandoDetalle = false;
      });
    } catch (_) {
      if (!mounted || solicitud != _solicitudDetalle || _idCompra != idCompra) {
        return;
      }

      setState(() {
        _error = 'No se pudo cargar el detalle de la compra';
        _cargandoDetalle = false;
      });
    }
  }

  dynamic _detalleSeleccionado() {
    final compra = _compraDetalle;
    final idDetalle = _idCompraDetalle;

    if (compra == null || idDetalle == null) return null;

    for (final detalle in compra.detalles) {
      if (detalle.idCompraDetalle == idDetalle) {
        return detalle;
      }
    }

    return null;
  }

  void _guardar() {
    if (_cargando || _cargandoDetalle || widget.procesando) return;
    final compra = _compraDetalle;
    final detalle = _detalleSeleccionado();
    final cantidad = int.tryParse(_cantidadController.text.trim()) ?? 0;

    if (compra == null || detalle == null || compra.idCompra != _idCompra) {
      setState(() {
        _error = 'Selecciona una compra y un producto';
      });
      return;
    }

    if (detalle.idInventario == null) {
      setState(() {
        _error = 'El renglón seleccionado no tiene inventario ligado';
      });
      return;
    }

    if (cantidad <= 0 || cantidad > detalle.cantidad) {
      setState(() {
        _error = 'La cantidad debe estar entre 1 y ${detalle.cantidad}';
      });
      return;
    }

    List<ReposicionProveedorDetallePayload>? reposicionDetalles;

    if (_compensacion == 'REPOSICION_PRODUCTO') {
      reposicionDetalles = [
        ReposicionProveedorDetallePayload(
          idProducto: detalle.idProducto,
          cantidad: cantidad,
          costoUnitario: detalle.costoUnitario,
          precioVenta: detalle.precioVentaSugerido,
          codigoLote: 'REP-${detalle.codigoLote}',
          fechaCaducidad: _textoONulo(
            _formatoFechaApi(detalle.fechaCaducidad),
          ),
        ),
      ];
    }

    setState(() {
      _error = null;
    });

    widget.onGuardarDevolucion(
      RegistrarDevolucionProveedorPayload(
        idUsuario: widget.idUsuario,
        idCompra: compra.idCompra,
        idProveedor: compra.idProveedor,
        tipoCompensacion: _compensacion,
        motivo: _motivo,
        observaciones: _textoONulo(_observacionesController.text),
        detalles: [
          DevolucionProveedorDetallePayload(
            idCompraDetalle: detalle.idCompraDetalle,
            idInventario: detalle.idInventario,
            cantidad: cantidad,
            motivoDetalle: _motivo,
            observaciones: _textoONulo(_observacionesController.text),
          ),
        ],
        reposicionDetalles: reposicionDetalles,
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
                          etiqueta: 'Buscar compra',
                          controller: _busquedaController,
                          hintText: 'Folio, proveedor, producto, lote...',
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _cargarCompras(pagina: 1),
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
                                onSubmitted: (_) => _cargarCompras(pagina: 1),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _CampoTexto(
                                etiqueta: 'Max',
                                controller: _totalMaxController,
                                keyboardType: TextInputType.number,
                                onSubmitted: (_) => _cargarCompras(pagina: 1),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _cargarCompras(pagina: 1),
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
                        const SizedBox(height: 8),
                        _PaginadorOrigen(
                          pagina: _pagina,
                          totalPaginas: _totalPaginas,
                          total: _total,
                          onAnterior: _pagina > 1
                              ? () => _cargarCompras(pagina: _pagina - 1)
                              : null,
                          onSiguiente: _pagina < _totalPaginas
                              ? () => _cargarCompras(pagina: _pagina + 1)
                              : null,
                        ),
                        const SizedBox(height: 18),
                        _CampoDropdownInt(
                          etiqueta: 'Compra origen',
                          valor: _compras
                                  .any((compra) => compra.idCompra == _idCompra)
                              ? _idCompra
                              : null,
                          hintText: 'Seleccione compra...',
                          opciones: [
                            for (final compra in _compras)
                              DropdownMenuItem<int>(
                                value: compra.idCompra,
                                child: Text(
                                  'CMP-${compra.idCompra} - ${compra.proveedor}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: _seleccionarCompra,
                        ),
                        if (_cargandoDetalle) ...[
                          const SizedBox(height: 12),
                          const LinearProgressIndicator(),
                        ],
                        if (!_cargandoDetalle && _compraDetalle != null) ...[
                          const SizedBox(height: 18),
                          _CampoDropdownInt(
                            etiqueta: 'Producto devuelto',
                            valor: _idCompraDetalle,
                            hintText: 'Seleccione producto...',
                            opciones: [
                              for (final detalle in _compraDetalle!.detalles)
                                DropdownMenuItem<int>(
                                  value: detalle.idCompraDetalle,
                                  child: Text(
                                    '${detalle.producto} - cant. ${detalle.cantidad}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _idCompraDetalle = value;
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
                          etiqueta: 'Compensación',
                          valor: _compensacion,
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
                              value: 'NOTA_CREDITO',
                              child: Text('Nota crédito'),
                            ),
                            DropdownMenuItem(
                              value: 'REPOSICION_PRODUCTO',
                              child: Text('Reposición'),
                            ),
                            DropdownMenuItem(
                              value: 'SIN_COMPENSACION',
                              child: Text('Sin compensación'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;

                            setState(() {
                              _compensacion = value;
                            });
                          },
                        ),
                        const SizedBox(height: 18),
                        _CampoDropdownString(
                          etiqueta: 'Motivo',
                          valor: _motivo,
                          opciones: const [
                            DropdownMenuItem(
                              value: 'PRODUCTO_DANADO',
                              child: Text('Producto dañado'),
                            ),
                            DropdownMenuItem(
                              value: 'CADUCADO',
                              child: Text('Caducado'),
                            ),
                            DropdownMenuItem(
                              value: 'ERROR_COMPRA',
                              child: Text('Error de compra'),
                            ),
                            DropdownMenuItem(
                              value: 'EXCEDENTE',
                              child: Text('Excedente'),
                            ),
                            DropdownMenuItem(
                              value: 'CAMBIO_PRECIO',
                              child: Text('Cambio de precio'),
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
          _AccionesDevolucionProveedor(
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
              'Devolución a proveedor',
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

class _AccionesDevolucionProveedor extends StatelessWidget {
  final bool procesando;
  final VoidCallback onGuardar;

  const _AccionesDevolucionProveedor({
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

class _PaginadorOrigen extends StatelessWidget {
  final int pagina;
  final int totalPaginas;
  final int total;
  final VoidCallback? onAnterior;
  final VoidCallback? onSiguiente;

  const _PaginadorOrigen({
    required this.pagina,
    required this.totalPaginas,
    required this.total,
    required this.onAnterior,
    required this.onSiguiente,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onAnterior,
          icon: const Icon(Icons.chevron_left, size: 18),
          tooltip: 'Pagina anterior',
          visualDensity: VisualDensity.compact,
        ),
        Expanded(
          child: Text(
            '$total resultados | Pagina $pagina de $totalPaginas',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textoSecundario,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          onPressed: onSiguiente,
          icon: const Icon(Icons.chevron_right, size: 18),
          tooltip: 'Pagina siguiente',
          visualDensity: VisualDensity.compact,
        ),
      ],
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

String _formatoFechaApi(dynamic fecha) {
  if (fecha == null) return '';

  if (fecha is DateTime) {
    final mes = fecha.month.toString().padLeft(2, '0');
    final dia = fecha.day.toString().padLeft(2, '0');

    return '${fecha.year}-$mes-$dia';
  }

  return fecha.toString();
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
