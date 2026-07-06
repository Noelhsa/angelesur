import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/inventario_api_service.dart';
import '../../utils/config_moneda.dart';

const Color _fondoPagina = Color(0xFFF8F6F5);
const Color _verdeOscuro = Color(0xFF397800);
const Color _azul = Color(0xFF0B63CE);
const Color _textoPrincipal = Color(0xFF1F2933);
const Color _textoSecundario = Color(0xFF667085);
const Color _bordeSuave = Color(0xFFD9E6D3);
const Color _grisCabecera = Color(0xFFE7E3E3);
const Color _grisCampo = Color(0xFFF8F7F4);
const Color _rojo = Color(0xFFE02020);

class ContenidoCatalogoInventario extends StatefulWidget {
  const ContenidoCatalogoInventario({super.key});

  @override
  State<ContenidoCatalogoInventario> createState() =>
      _ContenidoCatalogoInventarioState();
}

class _ContenidoCatalogoInventarioState
    extends State<ContenidoCatalogoInventario> {
  final InventarioApiService _inventarioApiService = InventarioApiService();
  final TextEditingController _busquedaController = TextEditingController();

  String _categoriaSeleccionada = 'Todas las categorias';
  String _estadoSeleccionado = 'Todos los estados';
  bool _cargando = true;
  String? _error;
  List<InventarioItem> _productos = [];

  @override
  void initState() {
    super.initState();
    _cargarInventario();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  List<String> get _categorias {
    final categorias = _productos
        .map((producto) => producto.categoria)
        .where((categoria) => categoria.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return ['Todas las categorias', ...categorias];
  }

  List<InventarioItem> get _productosFiltrados {
    return _productos.where((producto) {
      final coincideCategoria =
          _categoriaSeleccionada == 'Todas las categorias' ||
              producto.categoria == _categoriaSeleccionada;

      final coincideEstado = switch (_estadoSeleccionado) {
        'En existencia' =>
          producto.estadoStock == EstadoStockInventario.enExistencia,
        'Stock bajo' => producto.estadoStock == EstadoStockInventario.stockBajo,
        'Agotado' => producto.estadoStock == EstadoStockInventario.agotado,
        _ => true,
      };

      return coincideCategoria && coincideEstado;
    }).toList();
  }

  Future<void> _cargarInventario() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final productos = await _inventarioApiService.listarActual(
        busqueda: _busquedaController.text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _productos = productos;
        if (!_categorias.contains(_categoriaSeleccionada)) {
          _categoriaSeleccionada = 'Todas las categorias';
        }
        _cargando = false;
      });
    } on ApiException catch (error) {
      _mostrarError(error.message);
    } catch (_) {
      _mostrarError('No se pudo cargar el inventario');
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) {
      return;
    }

    setState(() {
      _error = mensaje;
      _cargando = false;
    });
  }

  void _mostrarDetalle(InventarioItem producto) {
    showDialog<void>(
      context: context,
      builder: (context) => _DialogoDetalleInventario(producto: producto),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _fondoPagina,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PanelFiltrosInventario(
              busquedaController: _busquedaController,
              categoriaSeleccionada: _categoriaSeleccionada,
              categorias: _categorias,
              estadoSeleccionado: _estadoSeleccionado,
              onCategoriaChanged: (value) {
                if (value == null) return;
                setState(() {
                  _categoriaSeleccionada = value;
                });
              },
              onEstadoChanged: (value) {
                if (value == null) return;
                setState(() {
                  _estadoSeleccionado = value;
                });
              },
              onBuscar: _cargarInventario,
              onRefrescar: _cargarInventario,
            ),
            const SizedBox(height: 18),
            if (_cargando)
              const _EstadoInventarioCatalogo(mensaje: 'Cargando inventario...')
            else if (_error != null)
              _EstadoInventarioCatalogo(
                mensaje: _error!,
                onReintentar: _cargarInventario,
              )
            else if (_productosFiltrados.isEmpty)
              const _EstadoInventarioCatalogo(
                mensaje: 'No hay productos para mostrar',
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final anchoTabla = constraints.maxWidth < 1020
                      ? 1020.0
                      : constraints.maxWidth;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: anchoTabla,
                      child: _TablaInventario(
                        productos: _productosFiltrados,
                        onVerDetalle: _mostrarDetalle,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _PanelFiltrosInventario extends StatelessWidget {
  final TextEditingController busquedaController;
  final String categoriaSeleccionada;
  final List<String> categorias;
  final String estadoSeleccionado;
  final ValueChanged<String?> onCategoriaChanged;
  final ValueChanged<String?> onEstadoChanged;
  final VoidCallback onBuscar;
  final VoidCallback onRefrescar;

  const _PanelFiltrosInventario({
    required this.busquedaController,
    required this.categoriaSeleccionada,
    required this.categorias,
    required this.estadoSeleccionado,
    required this.onCategoriaChanged,
    required this.onEstadoChanged,
    required this.onBuscar,
    required this.onRefrescar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        color: _fondoPagina,
        border: Border.all(color: _bordeSuave),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 240,
            child: _CampoBusqueda(
              controller: busquedaController,
              onBuscar: onBuscar,
            ),
          ),
          const SizedBox(width: 18),
          SizedBox(
            width: 180,
            child: _CampoDropdown(
              etiqueta: 'Categoria',
              valor: categoriaSeleccionada,
              opciones: categorias,
              onChanged: onCategoriaChanged,
            ),
          ),
          const SizedBox(width: 18),
          SizedBox(
            width: 165,
            child: _CampoDropdown(
              etiqueta: 'Estado de stock',
              valor: estadoSeleccionado,
              opciones: const [
                'Todos los estados',
                'En existencia',
                'Stock bajo',
                'Agotado',
              ],
              onChanged: onEstadoChanged,
            ),
          ),
          const Spacer(),
          _BotonSecundarioCatalogo(
            texto: 'Actualizar',
            icono: Icons.refresh,
            onTap: onRefrescar,
          ),
        ],
      ),
    );
  }
}

class _CampoBusqueda extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onBuscar;

  const _CampoBusqueda({
    required this.controller,
    required this.onBuscar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Buscar',
          style: TextStyle(
            color: _textoSecundario,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 34,
          child: TextField(
            controller: controller,
            onSubmitted: (_) => onBuscar(),
            decoration: InputDecoration(
              filled: true,
              fillColor: _grisCampo,
              hintText: 'Nombre, codigo o lote',
              hintStyle: const TextStyle(fontSize: 11),
              prefixIcon: const Icon(Icons.search, size: 16),
              suffixIcon: IconButton(
                onPressed: onBuscar,
                icon: const Icon(Icons.arrow_forward, size: 16),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: const BorderSide(color: Color(0xFFC8D6C0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: const BorderSide(color: Color(0xFFC8D6C0)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CampoDropdown extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final List<String> opciones;
  final ValueChanged<String?> onChanged;

  const _CampoDropdown({
    required this.etiqueta,
    required this.valor,
    required this.opciones,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final valorSeguro = opciones.contains(valor) ? valor : opciones.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: const TextStyle(
            color: _textoSecundario,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 34,
          child: DropdownButtonFormField<String>(
            initialValue: valorSeguro,
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: _textoSecundario,
            ),
            style: const TextStyle(
              color: _textoPrincipal,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: _grisCampo,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: const BorderSide(color: Color(0xFFC8D6C0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: const BorderSide(color: Color(0xFFC8D6C0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: const BorderSide(
                  color: _verdeOscuro,
                  width: 1.2,
                ),
              ),
            ),
            items: opciones.map((opcion) {
              return DropdownMenuItem<String>(
                value: opcion,
                child: Text(opcion),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _BotonSecundarioCatalogo extends StatelessWidget {
  final String texto;
  final IconData icono;
  final VoidCallback onTap;

  const _BotonSecundarioCatalogo({
    required this.texto,
    required this.icono,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(
          icono,
          size: 14,
          color: _textoSecundario,
        ),
        label: Text(
          texto,
          style: const TextStyle(
            color: _textoPrincipal,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          side: const BorderSide(color: Color(0xFFC8D6C0)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
    );
  }
}

class _TablaInventario extends StatelessWidget {
  final List<InventarioItem> productos;
  final ValueChanged<InventarioItem> onVerDetalle;

  const _TablaInventario({
    required this.productos,
    required this.onVerDetalle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _bordeSuave),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        children: [
          const _HeaderTablaInventario(),
          for (final producto in productos)
            _FilaProductoInventario(
              producto: producto,
              onVerDetalle: () => onVerDetalle(producto),
            ),
        ],
      ),
    );
  }
}

class _HeaderTablaInventario extends StatelessWidget {
  const _HeaderTablaInventario();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: const BoxDecoration(
        color: _grisCabecera,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(7),
        ),
      ),
      child: const Row(
        children: [
          SizedBox(width: 22),
          Expanded(flex: 14, child: _TextoHeaderTabla('CODIGO')),
          Expanded(flex: 28, child: _TextoHeaderTabla('PRODUCTO')),
          Expanded(flex: 15, child: _TextoHeaderTabla('CATEGORIA')),
          Expanded(flex: 12, child: _TextoHeaderTabla('STOCK')),
          Expanded(flex: 15, child: _TextoHeaderTabla('PRECIO')),
          Expanded(flex: 14, child: _TextoHeaderTabla('LOTE')),
          Expanded(flex: 16, child: _TextoHeaderTabla('ESTADO')),
          Expanded(flex: 10, child: _TextoHeaderTabla('ACCION')),
          SizedBox(width: 14),
        ],
      ),
    );
  }
}

class _TextoHeaderTabla extends StatelessWidget {
  final String texto;

  const _TextoHeaderTabla(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        color: Color(0xFF34423B),
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _FilaProductoInventario extends StatelessWidget {
  final InventarioItem producto;
  final VoidCallback onVerDetalle;

  const _FilaProductoInventario({
    required this.producto,
    required this.onVerDetalle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(0xFFE0E8D8),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 22),
          Expanded(
            flex: 14,
            child: Text(
              producto.codigoVisible,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _textoPrincipal,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 28,
            child: Text(
              producto.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _textoPrincipal,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            flex: 15,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _BadgeCategoria(texto: producto.categoria),
            ),
          ),
          Expanded(
            flex: 12,
            child: Text(
              producto.stockActual.toString(),
              style: TextStyle(
                color: producto.stockActual == 0
                    ? _rojo
                    : producto.stockActual <= 15
                        ? _azul
                        : _textoPrincipal,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            flex: 15,
            child: Text(
              ConfigMoneda.formato(producto.precioVenta),
              style: const TextStyle(
                color: _verdeOscuro,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            flex: 14,
            child: Text(
              producto.codigoLote.isEmpty ? '-' : producto.codigoLote,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF526171),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 16,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _BadgeEstado(estado: producto.estadoStock),
            ),
          ),
          Expanded(
            flex: 10,
            child: IconButton(
              onPressed: onVerDetalle,
              icon: const Icon(
                Icons.visibility_outlined,
                size: 18,
                color: _verdeOscuro,
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
    );
  }
}

class _BadgeCategoria extends StatelessWidget {
  final String texto;

  const _BadgeCategoria({
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEDEA),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        texto.isEmpty ? 'General' : texto,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF7C817B),
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _BadgeEstado extends StatelessWidget {
  final EstadoStockInventario estado;

  const _BadgeEstado({
    required this.estado,
  });

  @override
  Widget build(BuildContext context) {
    Color fondo;
    Color texto;
    String label;

    switch (estado) {
      case EstadoStockInventario.enExistencia:
        fondo = const Color(0xFFE8F5DD);
        texto = _verdeOscuro;
        label = 'En existencia';
        break;
      case EstadoStockInventario.stockBajo:
        fondo = const Color(0xFFE7F0FF);
        texto = _azul;
        label = 'Stock bajo';
        break;
      case EstadoStockInventario.agotado:
        fondo = const Color(0xFFFFE9E9);
        texto = _rojo;
        label = 'Agotado';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: texto,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EstadoInventarioCatalogo extends StatelessWidget {
  final String mensaje;
  final VoidCallback? onReintentar;

  const _EstadoInventarioCatalogo({
    required this.mensaje,
    this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 42),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mensaje,
              style: const TextStyle(
                color: _textoPrincipal,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (onReintentar != null) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: onReintentar,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DialogoDetalleInventario extends StatelessWidget {
  final InventarioItem producto;

  const _DialogoDetalleInventario({
    required this.producto,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(producto.nombre),
      content: SizedBox(
        width: 460,
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _DatoInventario(
                label: 'ID inventario', value: '${producto.idInventario}'),
            _DatoInventario(
                label: 'ID producto', value: '${producto.idProducto ?? '-'}'),
            _DatoInventario(label: 'Codigo', value: producto.codigoVisible),
            _DatoInventario(label: 'Lote', value: producto.codigoLote),
            _DatoInventario(label: 'Categoria', value: producto.categoria),
            _DatoInventario(label: 'Unidad', value: producto.unidad),
            _DatoInventario(label: 'Stock', value: '${producto.stockActual}'),
            _DatoInventario(
              label: 'Precio',
              value: ConfigMoneda.formato(producto.precioVenta),
            ),
            _DatoInventario(
              label: 'Caducidad',
              value: _formatoFecha(producto.fechaCaducidad),
            ),
            _DatoInventario(
              label: 'Inventario activo',
              value: producto.inventarioActivo ? 'Si' : 'No',
            ),
            _DatoInventario(
              label: 'Producto activo',
              value: producto.productoActivo ? 'Si' : 'No',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  String _formatoFecha(DateTime? fecha) {
    if (fecha == null) {
      return '-';
    }

    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }
}

class _DatoInventario extends StatelessWidget {
  final String label;
  final String value;

  const _DatoInventario({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F4F1),
        border: Border.all(color: _bordeSuave),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _textoSecundario,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? '-' : value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textoPrincipal,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
