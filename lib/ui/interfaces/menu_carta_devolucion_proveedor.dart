import 'package:flutter/material.dart';

import '../../services/compras_api_service.dart';
import '../../services/devoluciones_api_service.dart';

const Color _fondoPanel = Color(0xFFF8F8F8);
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

  bool _cargando = true;
  bool _cargandoDetalle = false;

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
    super.dispose();
  }

  Future<void> _cargarCompras() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final compras = await widget.comprasApiService.listarCompras(
        estatus: 'REGISTRADA',
        limite: 300,
      );

      if (!mounted) return;

      setState(() {
        _compras = compras;
        _cargando = false;

        if (compras.isEmpty) {
          _error = 'No se pudieron cargar compras registradas';
        }
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'No se pudieron cargar compras registradas';
        _cargando = false;
      });
    }
  }

  Future<void> _seleccionarCompra(int? idCompra) async {
    if (idCompra == null) return;

    setState(() {
      _idCompra = idCompra;
      _idCompraDetalle = null;
      _compraDetalle = null;
      _cargandoDetalle = true;
      _error = null;
    });

    try {
      final detalle = await widget.comprasApiService.obtenerCompra(idCompra);

      if (!mounted) return;

      setState(() {
        _compraDetalle = detalle;
        _idCompraDetalle = detalle.detalles.isNotEmpty
            ? detalle.detalles.first.idCompraDetalle
            : null;
        _cargandoDetalle = false;
      });
    } catch (_) {
      if (!mounted) return;

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
    final compra = _compraDetalle;
    final detalle = _detalleSeleccionado();
    final cantidad = int.tryParse(_cantidadController.text.trim()) ?? 0;

    if (compra == null || detalle == null) {
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
                      etiqueta: 'Compra origen',
                      valor: _idCompra,
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
            'Devolución a proveedor',
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