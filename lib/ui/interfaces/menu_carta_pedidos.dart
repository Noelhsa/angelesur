import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/compras_api_service.dart';
import '../../services/inventario_api_service.dart';
import '../../services/productos_api_service.dart';
import '../../services/proveedores_api_service.dart';
import '../../utils/config_moneda.dart';

const Color _verdeOscuro = Color(0xFF397800);
const Color _verde = Color(0xFF64D20A);
const Color _textoPrincipal = Color(0xFF101828);
const Color _textoSecundario = Color(0xFF667085);
const Color _bordeSuave = Color(0xFFD9E6D3);
const Color _grisCampo = Color(0xFFF8F7F4);
const Color _rojo = Color(0xFFE02020);

class MenuCartaPedidos extends StatefulWidget {
  final VoidCallback onCerrar;
  final ValueChanged<CompraPayload> onGuardarOrden;
  final int idUsuario;
  final bool guardando;

  const MenuCartaPedidos({
    super.key,
    required this.onCerrar,
    required this.onGuardarOrden,
    required this.idUsuario,
    required this.guardando,
  });

  @override
  State<MenuCartaPedidos> createState() => _MenuCartaPedidosState();
}

class _MenuCartaPedidosState extends State<MenuCartaPedidos> {
  final ProveedoresApiService _proveedoresApiService = ProveedoresApiService();
  final ProductosApiService _productosApiService = ProductosApiService();
  final InventarioApiService _inventarioApiService = InventarioApiService();
  final TextEditingController _folioController = TextEditingController();
  final TextEditingController _descuentoController =
      TextEditingController(text: '0');
  final TextEditingController _observacionesController =
      TextEditingController();

  bool _cargandoCatalogos = true;
  String? _errorCatalogos;
  int? _idProveedorSeleccionado;
  String _medioPago = 'EFECTIVO';
  List<ProveedorApi> _proveedores = [];
  List<ProductoCatalogoApi> _productos = [];
  final List<_LineaCompraForm> _lineas = [_LineaCompraForm()];

  @override
  void initState() {
    super.initState();
    _cargarCatalogos();
    _descuentoController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _folioController.dispose();
    _descuentoController.dispose();
    _observacionesController.dispose();
    for (final linea in _lineas) {
      linea.dispose();
    }
    super.dispose();
  }

  double get _subtotal => _lineas.fold<double>(
        0,
        (total, linea) => total + linea.subtotal,
      );

  double get _descuento {
    final value = double.tryParse(_descuentoController.text.trim()) ?? 0;
    if (value < 0) return 0;
    return value;
  }

  double get _total {
    final total = _subtotal - _descuento;
    return total < 0 ? 0 : total;
  }

  Future<void> _cargarCatalogos() async {
    setState(() {
      _cargandoCatalogos = true;
      _errorCatalogos = null;
    });

    try {
      final results = await Future.wait([
        _proveedoresApiService.listarProveedores(
          incluirInactivos: false,
          limite: 500,
        ),
        _productosApiService.listarProductos(
          incluirInactivos: false,
          limite: 500,
        ),
      ]);

      if (!mounted) return;
      final proveedores = results[0] as List<ProveedorApi>;
      final productos = results[1] as List<ProductoCatalogoApi>;
      setState(() {
        _proveedores = proveedores;
        _productos = productos;
        _idProveedorSeleccionado =
            proveedores.isNotEmpty ? proveedores.first.idProveedor : null;
        _cargandoCatalogos = false;
      });
    } on ApiException catch (error) {
      _mostrarErrorCatalogos(error.message);
    } catch (_) {
      _mostrarErrorCatalogos('No se pudieron cargar proveedores y productos');
    }
  }

  void _mostrarErrorCatalogos(String mensaje) {
    if (!mounted) return;
    setState(() {
      _errorCatalogos = mensaje;
      _cargandoCatalogos = false;
    });
  }

  void _agregarLinea() {
    setState(() {
      _lineas.add(_LineaCompraForm());
    });
  }

  void _quitarLinea(int index) {
    if (_lineas.length == 1) return;
    setState(() {
      final linea = _lineas.removeAt(index);
      linea.dispose();
    });
  }

  Future<void> _seleccionarProductoLinea(
    _LineaCompraForm linea,
    int? idProducto,
  ) async {
    final producto =
        _productos.where((item) => item.idProducto == idProducto).firstOrNull;

    setState(() {
      linea.idProducto = idProducto;
      linea.productoController.text =
          producto == null ? '' : _etiquetaProductoPedido(producto);
      linea.ubicacionLetraController.clear();
      linea.ubicacionNumeroController.clear();
      linea.cargandoUbicacion = producto?.esMedicamento ?? false;
    });

    if (idProducto == null || producto == null || !producto.esMedicamento) {
      return;
    }

    try {
      final ubicacion =
          await _inventarioApiService.obtenerUbicacionSugerida(idProducto);
      if (!mounted || linea.idProducto != idProducto) return;

      setState(() {
        if (ubicacion.tieneUbicacion) {
          linea.ubicacionLetraController.text = ubicacion.ubicacionLetra;
          linea.ubicacionNumeroController.text =
              ubicacion.ubicacionNumero.toString();
        }
        linea.cargandoUbicacion = false;
      });
    } catch (_) {
      if (!mounted || linea.idProducto != idProducto) return;
      setState(() {
        linea.cargandoUbicacion = false;
      });
    }
  }

  void _guardar() {
    final detalles = <CompraDetallePayload>[];

    for (final linea in _lineas) {
      final idProducto = linea.idProducto;
      final cantidad = int.tryParse(linea.cantidadController.text.trim()) ?? 0;
      final costo = double.tryParse(linea.costoController.text.trim()) ?? -1;
      final precio = double.tryParse(linea.precioController.text.trim()) ?? -1;
      final lote = linea.loteController.text.trim();
      final caducidad = linea.caducidadController.text.trim();
      final producto =
          _productos.where((item) => item.idProducto == idProducto).firstOrNull;

      if (idProducto == null || cantidad <= 0 || costo < 0 || precio < 0) {
        _mostrarMensaje(
          'Completa producto, cantidad, costo y precio en cada renglon',
        );
        return;
      }

      String? ubicacionLetra;
      int? ubicacionNumero;

      if (producto?.esMedicamento ?? false) {
        final letra = linea.ubicacionLetraController.text.trim().toUpperCase();
        final numeroTexto = linea.ubicacionNumeroController.text.trim();

        if (letra.isNotEmpty || numeroTexto.isNotEmpty) {
          final numero = int.tryParse(numeroTexto);
          final letraValida = letra.length == 1 &&
              letra.codeUnitAt(0) >= 65 &&
              letra.codeUnitAt(0) <= 90;

          if (!letraValida || numero == null || numero < 1 || numero > 999) {
            _mostrarMensaje(
              'Completa la ubicacion del medicamento con letra A-Z y numero 1-999',
            );
            return;
          }

          ubicacionLetra = letra;
          ubicacionNumero = numero;
        }
      }

      detalles.add(
        CompraDetallePayload(
          idProducto: idProducto,
          cantidad: cantidad,
          costoUnitario: costo,
          precioVenta: precio,
          codigoLote: lote.isEmpty ? 'SIN_LOTE' : lote,
          fechaCaducidad: caducidad.isEmpty ? null : caducidad,
          ubicacionLetra: ubicacionLetra,
          ubicacionNumero: ubicacionNumero,
        ),
      );
    }

    if (_productos.isEmpty) {
      _mostrarMensaje('Primero registra productos en catalogo');
      return;
    }

    widget.onGuardarOrden(
      CompraPayload(
        idUsuario: widget.idUsuario,
        idProveedor: _idProveedorSeleccionado,
        folioProveedor: _textoONulo(_folioController.text),
        descuento: _descuento,
        observaciones: _textoONulo(_observacionesController.text),
        detalles: detalles,
        medioPago: _medioPago,
        montoPagado: _total,
      ),
    );
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  String? _textoONulo(String value) {
    final texto = value.trim();
    return texto.isEmpty ? null : texto;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: _bordeSuave)),
      ),
      child: Column(
        children: [
          _EncabezadoNuevaOrden(onCerrar: widget.onCerrar),
          Expanded(
            child: _cargandoCatalogos
                ? const Center(child: CircularProgressIndicator())
                : _errorCatalogos != null
                    ? _EstadoCarga(
                        mensaje: _errorCatalogos!,
                        onReintentar: _cargarCatalogos,
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(12, 16, 12, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SelectorProveedor(
                              proveedores: _proveedores,
                              idSeleccionado: _idProveedorSeleccionado,
                              onChanged: (value) {
                                setState(() {
                                  _idProveedorSeleccionado = value;
                                });
                              },
                            ),
                            const SizedBox(height: 14),
                            _CampoTextoPedido(
                              etiqueta: 'Folio proveedor',
                              controller: _folioController,
                              hintText: 'Factura, nota o remision',
                            ),
                            const SizedBox(height: 14),
                            _MedioPagoPedido(
                              valor: _medioPago,
                              onChanged: (value) {
                                setState(() {
                                  _medioPago = value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            _EncabezadoProductos(onAgregar: _agregarLinea),
                            const SizedBox(height: 10),
                            for (var i = 0; i < _lineas.length; i++) ...[
                              _LineaCompraWidget(
                                key: ValueKey(_lineas[i]),
                                linea: _lineas[i],
                                productos: _productos,
                                puedeQuitar: _lineas.length > 1,
                                onChanged: () => setState(() {}),
                                onProductoChanged: _seleccionarProductoLinea,
                                onQuitar: () => _quitarLinea(i),
                              ),
                              const SizedBox(height: 10),
                            ],
                            const SizedBox(height: 6),
                            _CampoTextoPedido(
                              etiqueta: 'Descuento',
                              controller: _descuentoController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              prefixText: r'$ ',
                            ),
                            const SizedBox(height: 14),
                            _ResumenFinalPedido(
                              subtotal: _subtotal,
                              descuento: _descuento,
                              total: _total,
                            ),
                            const SizedBox(height: 14),
                            _CampoTextoPedido(
                              etiqueta: 'Observaciones',
                              controller: _observacionesController,
                              hintText:
                                  'Notas sobre envio, urgencia o condiciones',
                              maxLines: 4,
                            ),
                          ],
                        ),
                      ),
          ),
          _AccionesNuevaOrden(
            onCancelar: widget.onCerrar,
            onGuardar: _guardar,
            guardando: widget.guardando,
          ),
        ],
      ),
    );
  }
}

class _LineaCompraForm {
  int? idProducto;
  final TextEditingController productoController = TextEditingController();
  final FocusNode productoFocusNode = FocusNode();
  final TextEditingController cantidadController =
      TextEditingController(text: '1');
  final TextEditingController costoController = TextEditingController();
  final TextEditingController precioController = TextEditingController();
  final TextEditingController loteController = TextEditingController();
  final TextEditingController caducidadController = TextEditingController();
  final TextEditingController ubicacionLetraController =
      TextEditingController();
  final TextEditingController ubicacionNumeroController =
      TextEditingController();
  bool cargandoUbicacion = false;

  double get subtotal {
    final cantidad = int.tryParse(cantidadController.text.trim()) ?? 0;
    final costo = double.tryParse(costoController.text.trim()) ?? 0;
    return cantidad * costo;
  }

  void dispose() {
    productoController.dispose();
    productoFocusNode.dispose();
    cantidadController.dispose();
    costoController.dispose();
    precioController.dispose();
    loteController.dispose();
    caducidadController.dispose();
    ubicacionLetraController.dispose();
    ubicacionNumeroController.dispose();
  }
}

class _EncabezadoNuevaOrden extends StatelessWidget {
  final VoidCallback onCerrar;

  const _EncabezadoNuevaOrden({required this.onCerrar});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _bordeSuave)),
      ),
      child: Row(
        children: [
          const Icon(Icons.add_shopping_cart, color: _verdeOscuro, size: 17),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Nueva Orden',
              style: TextStyle(
                color: _textoPrincipal,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            onPressed: onCerrar,
            icon: const Icon(Icons.close, color: _textoPrincipal, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

class _SelectorProveedor extends StatelessWidget {
  final List<ProveedorApi> proveedores;
  final int? idSeleccionado;
  final ValueChanged<int?> onChanged;

  const _SelectorProveedor({
    required this.proveedores,
    required this.idSeleccionado,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _ContenedorCampo(
      etiqueta: 'Proveedor',
      child: DropdownButtonFormField<int?>(
        initialValue: idSeleccionado,
        isExpanded: true,
        icon: const Icon(
          Icons.keyboard_arrow_down,
          color: _textoSecundario,
          size: 18,
        ),
        decoration: _decoracionCampo(),
        items: [
          const DropdownMenuItem<int?>(
            value: null,
            child: Text('Sin proveedor'),
          ),
          for (final proveedor in proveedores)
            DropdownMenuItem<int?>(
              value: proveedor.idProveedor,
              child: Text(
                proveedor.nombre,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _MedioPagoPedido extends StatelessWidget {
  final String valor;
  final ValueChanged<String> onChanged;

  const _MedioPagoPedido({
    required this.valor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _ContenedorCampo(
      etiqueta: 'Pago de compra',
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(
            value: 'EFECTIVO',
            icon: Icon(Icons.payments_outlined, size: 15),
            label: Text('Efectivo'),
          ),
          ButtonSegment(
            value: 'ELECTRONICO',
            icon: Icon(Icons.credit_card, size: 15),
            label: Text('Electronico'),
          ),
        ],
        selected: {valor},
        onSelectionChanged: (values) => onChanged(values.first),
        style: ButtonStyle(
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
          ),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

class _CampoTextoPedido extends StatelessWidget {
  final String etiqueta;
  final TextEditingController controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? prefixText;

  const _CampoTextoPedido({
    required this.etiqueta,
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.maxLines = 1,
    this.prefixText,
  });

  @override
  Widget build(BuildContext context) {
    return _ContenedorCampo(
      etiqueta: etiqueta,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(
          color: _textoPrincipal,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        decoration: _decoracionCampo(
          hintText: hintText,
          prefixText: prefixText,
        ),
      ),
    );
  }
}

class _EncabezadoProductos extends StatelessWidget {
  final VoidCallback onAgregar;

  const _EncabezadoProductos({required this.onAgregar});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Productos',
            style: TextStyle(
              color: _textoPrincipal,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onAgregar,
          icon: const Icon(Icons.add, size: 15),
          label: const Text('Agregar'),
          style: TextButton.styleFrom(
            foregroundColor: _verdeOscuro,
            textStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _LineaCompraWidget extends StatelessWidget {
  final _LineaCompraForm linea;
  final List<ProductoCatalogoApi> productos;
  final bool puedeQuitar;
  final VoidCallback onChanged;
  final Future<void> Function(_LineaCompraForm linea, int? idProducto)
      onProductoChanged;
  final VoidCallback onQuitar;

  const _LineaCompraWidget({
    super.key,
    required this.linea,
    required this.productos,
    required this.puedeQuitar,
    required this.onChanged,
    required this.onProductoChanged,
    required this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    final producto = productos
        .where((item) => item.idProducto == linea.idProducto)
        .firstOrNull;
    final manejaCaducidad = producto?.manejaCaducidad ?? false;
    final esMedicamento = producto?.esMedicamento ?? false;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCF9),
        border: Border.all(color: _bordeSuave),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SelectorProductoPedido(
                  linea: linea,
                  productos: productos,
                  productoSeleccionado: producto,
                  onProductoChanged: onProductoChanged,
                  onChanged: onChanged,
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: puedeQuitar ? onQuitar : null,
                icon: const Icon(Icons.delete_outline, size: 18),
                color: _rojo,
                tooltip: 'Quitar producto',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MiniCampo(
                  etiqueta: 'Cant.',
                  controller: linea.cantidadController,
                  onChanged: onChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniCampo(
                  etiqueta: 'Costo',
                  controller: linea.costoController,
                  onChanged: onChanged,
                  prefixText: r'$ ',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniCampo(
                  etiqueta: 'Venta',
                  controller: linea.precioController,
                  onChanged: onChanged,
                  prefixText: r'$ ',
                ),
              ),
            ],
          ),
          if (esMedicamento) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _MiniCampo(
                    etiqueta: 'Estante',
                    controller: linea.ubicacionLetraController,
                    onChanged: onChanged,
                    keyboardType: TextInputType.text,
                    hintText: linea.cargandoUbicacion ? 'Cargando...' : 'A-Z',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniCampo(
                    etiqueta: 'No.',
                    controller: linea.ubicacionNumeroController,
                    onChanged: onChanged,
                    hintText: linea.cargandoUbicacion ? 'Cargando...' : '1-999',
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MiniCampo(
                  etiqueta: 'Lote',
                  controller: linea.loteController,
                  onChanged: onChanged,
                  keyboardType: TextInputType.text,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CampoFechaCaducidad(
                  controller: linea.caducidadController,
                  requerida: manejaCaducidad,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Subtotal ${ConfigMoneda.formato(linea.subtotal)}',
              style: const TextStyle(
                color: _verdeOscuro,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectorProductoPedido extends StatelessWidget {
  final _LineaCompraForm linea;
  final List<ProductoCatalogoApi> productos;
  final ProductoCatalogoApi? productoSeleccionado;
  final Future<void> Function(_LineaCompraForm linea, int? idProducto)
      onProductoChanged;
  final VoidCallback onChanged;

  const _SelectorProductoPedido({
    required this.linea,
    required this.productos,
    required this.productoSeleccionado,
    required this.onProductoChanged,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _ContenedorCampo(
      etiqueta: 'Producto',
      child: RawAutocomplete<ProductoCatalogoApi>(
        textEditingController: linea.productoController,
        focusNode: linea.productoFocusNode,
        displayStringForOption: _etiquetaProductoPedido,
        optionsBuilder: (value) {
          final busqueda = value.text.trim().toLowerCase();
          if (busqueda.isEmpty) {
            return productos.take(20);
          }

          return productos.where((producto) {
            final texto = [
              producto.nombre,
              producto.codigoBarras ?? '',
              producto.categoria ?? '',
              producto.tipo,
            ].join(' ').toLowerCase();
            return texto.contains(busqueda);
          }).take(20);
        },
        onSelected: (producto) {
          onProductoChanged(linea, producto.idProducto);
        },
        fieldViewBuilder: (
          context,
          controller,
          focusNode,
          onFieldSubmitted,
        ) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            cursorColor: _verdeOscuro,
            style: const TextStyle(
              color: _textoPrincipal,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            decoration: _decoracionCampo(
              hintText: 'Buscar producto...',
              suffixIcon: Icons.search,
            ),
            onChanged: (value) {
              final texto = value.trim();
              final seleccionado = productoSeleccionado == null
                  ? ''
                  : _etiquetaProductoPedido(productoSeleccionado!);

              if (texto.isEmpty && linea.idProducto != null) {
                linea.idProducto = null;
                linea.ubicacionLetraController.clear();
                linea.ubicacionNumeroController.clear();
                linea.cargandoUbicacion = false;
                onChanged();
                return;
              }

              if (linea.idProducto != null && texto != seleccionado) {
                linea.idProducto = null;
                linea.ubicacionLetraController.clear();
                linea.ubicacionNumeroController.clear();
                linea.cargandoUbicacion = false;
                onChanged();
                return;
              }

              onChanged();
            },
          );
        },
        optionsViewBuilder: (context, onSelected, opciones) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 8,
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 280,
                  maxHeight: 230,
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shrinkWrap: true,
                  itemCount: opciones.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    color: _bordeSuave,
                  ),
                  itemBuilder: (context, index) {
                    final producto = opciones.elementAt(index);
                    return InkWell(
                      onTap: () => onSelected(producto),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              producto.nombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _textoPrincipal,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _detalleProductoPedido(producto),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _textoSecundario,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MiniCampo extends StatelessWidget {
  final String etiqueta;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final String? prefixText;
  final String? hintText;
  final TextInputType keyboardType;

  const _MiniCampo({
    required this.etiqueta,
    required this.controller,
    required this.onChanged,
    this.prefixText,
    this.hintText,
    this.keyboardType = const TextInputType.numberWithOptions(decimal: true),
  });

  @override
  Widget build(BuildContext context) {
    return _ContenedorCampo(
      etiqueta: etiqueta,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: (_) => onChanged(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        decoration: _decoracionCampo(
          prefixText: prefixText,
          hintText: hintText,
        ),
      ),
    );
  }
}

class _CampoFechaCaducidad extends StatelessWidget {
  final TextEditingController controller;
  final bool requerida;
  final VoidCallback onChanged;

  const _CampoFechaCaducidad({
    required this.controller,
    required this.requerida,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _ContenedorCampo(
      etiqueta: 'Caducidad',
      child: TextField(
        controller: controller,
        readOnly: true,
        onTap: () => _seleccionarFecha(context),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        decoration: _decoracionCampo(
          hintText: requerida ? 'Seleccionar fecha' : 'Opcional',
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
    controller.text = _formatoFechaApi(seleccionada);
    onChanged();
  }
}

class _ResumenFinalPedido extends StatelessWidget {
  final double subtotal;
  final double descuento;
  final double total;

  const _ResumenFinalPedido({
    required this.subtotal,
    required this.descuento,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7DF),
        border: Border.all(color: const Color(0xFFCFE8BF)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _LineaResumen('Subtotal', ConfigMoneda.formato(subtotal)),
          const SizedBox(height: 6),
          _LineaResumen('Descuento', ConfigMoneda.formato(descuento)),
          const Divider(height: 18, color: Color(0xFFCFE8BF)),
          _LineaResumen(
            'Total',
            ConfigMoneda.formato(total),
            destacado: true,
          ),
        ],
      ),
    );
  }
}

class _LineaResumen extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final bool destacado;

  const _LineaResumen(
    this.etiqueta,
    this.valor, {
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            etiqueta,
            style: TextStyle(
              color: destacado ? _verdeOscuro : _textoSecundario,
              fontSize: destacado ? 18 : 11,
              fontWeight: destacado ? FontWeight.w900 : FontWeight.w800,
            ),
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            color: destacado ? _verdeOscuro : _textoPrincipal,
            fontSize: destacado ? 18 : 12,
            fontWeight: FontWeight.w900,
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
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 38),
          child: child,
        ),
      ],
    );
  }
}

class _AccionesNuevaOrden extends StatelessWidget {
  final VoidCallback onCancelar;
  final VoidCallback onGuardar;
  final bool guardando;

  const _AccionesNuevaOrden({
    required this.onCancelar,
    required this.onGuardar,
    required this.guardando,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _bordeSuave)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 34,
              child: OutlinedButton(
                onPressed: guardando ? null : onCancelar,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _bordeSuave),
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
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 34,
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
                        size: 13,
                      ),
                label: Text(
                  guardando ? 'Guardando' : 'Guardar',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _verde,
                  disabledBackgroundColor: _verde.withValues(alpha: 0.65),
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

class _EstadoCarga extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;

  const _EstadoCarga({
    required this.mensaje,
    required this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textoSecundario,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _decoracionCampo({
  String? hintText,
  String? prefixText,
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
    prefixText: prefixText,
    prefixStyle: const TextStyle(
      color: _textoPrincipal,
      fontSize: 12,
      fontWeight: FontWeight.w800,
    ),
    suffixIcon: suffixIcon == null
        ? null
        : Icon(
            suffixIcon,
            color: _textoSecundario,
            size: 16,
          ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: _bordeSuave),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: _bordeSuave),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: _verdeOscuro, width: 1.3),
    ),
  );
}

DateTime? _fechaDesdeTexto(String value) {
  if (value.trim().isEmpty) return null;
  return DateTime.tryParse(value.trim());
}

String _formatoFechaApi(DateTime fecha) {
  final mes = fecha.month.toString().padLeft(2, '0');
  final dia = fecha.day.toString().padLeft(2, '0');
  return '${fecha.year}-$mes-$dia';
}

String _etiquetaProductoPedido(ProductoCatalogoApi producto) {
  final codigo = producto.codigoBarras?.trim();
  if (codigo == null || codigo.isEmpty) {
    return producto.nombre;
  }
  return '${producto.nombre} - $codigo';
}

String _detalleProductoPedido(ProductoCatalogoApi producto) {
  final partes = <String>[
    producto.esMedicamento ? 'Medicamento' : 'Producto',
    if ((producto.categoria ?? '').trim().isNotEmpty) producto.categoria!,
    if ((producto.codigoBarras ?? '').trim().isNotEmpty)
      'Cod. ${producto.codigoBarras}',
  ];
  return partes.join(' | ');
}
