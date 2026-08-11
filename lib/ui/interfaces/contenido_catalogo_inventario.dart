import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/inventario_api_service.dart';
import '../../utils/config_moneda.dart';

const Color _fondoPagina = Color(0xFFE2E2E2);
const Color _verdeOscuro = Color(0xFF397800);
const Color _azul = Color(0xFF0B63CE);
const Color _textoPrincipal = Color(0xFF1F2933);
const Color _textoSecundario = Color(0xFF667085);
const Color _bordeSuave = Color(0xFFD9E6D3);
const Color _grisCampo = Color(0xFFFFFFFF);
const Color _rojo = Color(0xFFE02020);

class ContenidoCatalogoInventario extends StatefulWidget {
  final bool soloLectura;

  const ContenidoCatalogoInventario({
    super.key,
    this.soloLectura = false,
  });

  @override
  State<ContenidoCatalogoInventario> createState() =>
      _ContenidoCatalogoInventarioState();
}

class _ContenidoCatalogoInventarioState
    extends State<ContenidoCatalogoInventario> {
  final InventarioApiService _inventarioApiService = InventarioApiService();

  final TextEditingController _busquedaController = TextEditingController();

  String _categoriaSeleccionada = 'Todas las categorias';
  String _estadoSeleccionado = 'En existencia';

  bool _cargando = true;
  String? _error;

  List<InventarioItem> _productos = [];

  int _pagina = 1;
  int _limite = 25;
  int _totalProductos = 0;
  int _totalPaginas = 1;
  bool _hayAnterior = false;
  bool _haySiguiente = false;

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
        .map(
          (producto) => producto.categoria,
        )
        .where(
          (categoria) => categoria.trim().isNotEmpty,
        )
        .toSet()
        .toList()
      ..sort();

    return [
      'Todas las categorias',
      if (_categoriaSeleccionada != 'Todas las categorias' &&
          !categorias.contains(
            _categoriaSeleccionada,
          ))
        _categoriaSeleccionada,
      ...categorias,
    ];
  }

  List<InventarioItem> get _productosFiltrados {
    return _productos.where((producto) {
      final coincideCategoria =
          _categoriaSeleccionada == 'Todas las categorias' ||
              producto.categoria == _categoriaSeleccionada;

      final coincideEstado = switch (_estadoSeleccionado) {
        'En existencia' => producto.stockActual > 0,
        'Stock bajo' => producto.estadoStock == EstadoStockInventario.stockBajo,
        'Agotado' => producto.estadoStock == EstadoStockInventario.agotado,
        _ => true,
      };

      return coincideCategoria && coincideEstado;
    }).toList();
  }

  Future<void> _cargarInventario({
    int? pagina,
  }) async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final estadoStock = switch (_estadoSeleccionado) {
        'En existencia' => EstadoStockInventario.enExistencia,
        'Stock bajo' => EstadoStockInventario.stockBajo,
        'Agotado' => EstadoStockInventario.agotado,
        _ => null,
      };

      final categoria = _categoriaSeleccionada == 'Todas las categorias'
          ? null
          : _categoriaSeleccionada;

      final resultado = await _inventarioApiService.listarActualPaginado(
        busqueda: _busquedaController.text,
        categoria: categoria,
        estadoStock: estadoStock,
        pagina: pagina ?? _pagina,
        limite: _limite,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _productos = resultado.items;
        _pagina = resultado.pagina;
        _limite = resultado.limite;
        _totalProductos = resultado.total;
        _totalPaginas = resultado.totalPaginas;
        _hayAnterior = resultado.hayAnterior;
        _haySiguiente = resultado.haySiguiente;

        if (!_categorias.contains(
          _categoriaSeleccionada,
        )) {
          _categoriaSeleccionada = 'Todas las categorias';
        }

        _cargando = false;
      });
    } on ApiException catch (error) {
      _mostrarError(
        error.message,
      );
    } catch (_) {
      _mostrarError(
        'No se pudo cargar el inventario',
      );
    }
  }

  void _mostrarError(
    String mensaje,
  ) {
    if (!mounted) {
      return;
    }

    setState(() {
      _error = mensaje;
      _cargando = false;
    });
  }

  void _mostrarDetalle(
    InventarioItem producto,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return _DialogoDetalleInventario(
          producto: producto,
        );
      },
    );
  }

  Future<void> _editarLote(
    InventarioItem producto,
  ) async {
    final datos = await showDialog<_DatosLoteInventario>(
      context: context,
      builder: (context) {
        return _DialogoLoteInventario(
          producto: producto,
        );
      },
    );

    if (datos == null) {
      return;
    }

    try {
      final actualizado = await _inventarioApiService.actualizarDatosLote(
        idInventario: producto.idInventario,
        codigoLote: datos.codigoLote,
        fechaCaducidad: datos.fechaCaducidad,
        precioVenta: datos.precioVenta,
        ubicacionLetra: datos.ubicacionLetra,
        ubicacionNumero: datos.ubicacionNumero,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        final index = _productos.indexWhere(
          (item) {
            return item.idInventario == actualizado.idInventario;
          },
        );

        if (index >= 0) {
          _productos[index] = actualizado;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Datos del lote actualizados',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudieron actualizar los datos del lote',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _fondoPagina,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          10,
          20,
          10,
          28,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PanelFiltrosInventario(
              busquedaController: _busquedaController,
              categoriaSeleccionada: _categoriaSeleccionada,
              categorias: _categorias,
              estadoSeleccionado: _estadoSeleccionado,
              onCategoriaChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _categoriaSeleccionada = value;
                });

                _cargarInventario(
                  pagina: 1,
                );
              },
              onEstadoChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _estadoSeleccionado = value;
                });

                _cargarInventario(
                  pagina: 1,
                );
              },
              onBuscar: () {
                _cargarInventario(
                  pagina: 1,
                );
              },
              onRefrescar: _cargarInventario,
            ),
            const SizedBox(height: 18),
            if (_cargando)
              const _EstadoInventarioCatalogo(
                mensaje: 'Cargando inventario...',
              )
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
                  final anchoTabla =
                      constraints.maxWidth < 980 ? 980.0 : constraints.maxWidth;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: anchoTabla,
                      child: _TablaInventario(
                        productos: _productos,
                        soloLectura: widget.soloLectura,
                        onVerDetalle: _mostrarDetalle,
                        onEditarUbicacion: _editarLote,
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 12),
            _PaginadorCatalogoInventario(
              pagina: _pagina,
              totalPaginas: _totalPaginas,
              total: _totalProductos,
              limite: _limite,
              hayAnterior: _hayAnterior,
              haySiguiente: _haySiguiente,
              onAnterior: () {
                _cargarInventario(
                  pagina: _pagina - 1,
                );
              },
              onSiguiente: () {
                _cargarInventario(
                  pagina: _pagina + 1,
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
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        18,
        14,
        18,
        14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: _bordeSuave,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 240,
            child: _CampoBusqueda(
              controller: busquedaController,
              onBuscar: onBuscar,
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 190,
            child: _CampoDropdown(
              etiqueta: 'Categoría',
              valor: categoriaSeleccionada,
              opciones: categorias,
              onChanged: onCategoriaChanged,
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 170,
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
            onSubmitted: (_) {
              onBuscar();
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: _grisCampo,
              hintText: 'Nombre, codigo, lote o ubicacion',
              hintStyle: const TextStyle(
                fontSize: 11,
              ),
              prefixIcon: const Icon(
                Icons.search,
                size: 16,
              ),
              suffixIcon: IconButton(
                onPressed: onBuscar,
                icon: const Icon(
                  Icons.arrow_forward,
                  size: 16,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: const BorderSide(
                  color: Color(
                    0xFFC8D6C0,
                  ),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: const BorderSide(
                  color: Color(
                    0xFFC8D6C0,
                  ),
                ),
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
                borderSide: const BorderSide(
                  color: Color(
                    0xFFC8D6C0,
                  ),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: const BorderSide(
                  color: Color(
                    0xFFC8D6C0,
                  ),
                ),
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
      width: 138,
      height: 32,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(
          icono,
          size: 14,
          color: Colors.white,
        ),
        label: Text(
          texto,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 2,
          backgroundColor: const Color(0xFF417A00),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
          ),
          shadowColor: const Color(0xFF417A00).withValues(
            alpha: 0.25,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}

class _TablaInventario extends StatelessWidget {
  final List<InventarioItem> productos;
  final bool soloLectura;

  final ValueChanged<InventarioItem> onVerDetalle;

  final ValueChanged<InventarioItem> onEditarUbicacion;

  const _TablaInventario({
    required this.productos,
    required this.soloLectura,
    required this.onVerDetalle,
    required this.onEditarUbicacion,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < productos.length; index++) ...[
          if (index > 0)
            const SizedBox(
              height: 10,
            ),
          _FilaProductoInventario(
            producto: productos[index],
            soloLectura: soloLectura,
            onVerDetalle: () {
              onVerDetalle(
                productos[index],
              );
            },
            onEditarUbicacion: () {
              onEditarUbicacion(
                productos[index],
              );
            },
          ),
        ],
      ],
    );
  }
}

class _PaginadorCatalogoInventario extends StatelessWidget {
  final int pagina;
  final int totalPaginas;
  final int total;
  final int limite;
  final bool hayAnterior;
  final bool haySiguiente;
  final VoidCallback onAnterior;
  final VoidCallback onSiguiente;

  const _PaginadorCatalogoInventario({
    required this.pagina,
    required this.totalPaginas,
    required this.total,
    required this.limite,
    required this.hayAnterior,
    required this.haySiguiente,
    required this.onAnterior,
    required this.onSiguiente,
  });

  @override
  Widget build(BuildContext context) {
    final desde = total == 0 ? 0 : ((pagina - 1) * limite) + 1;

    final hasta = total == 0
        ? 0
        : (desde + limite - 1).clamp(
            0,
            total,
          );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _bordeSuave,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$desde-$hasta de $total | '
              'Pagina $pagina de $totalPaginas',
              style: const TextStyle(
                color: _textoSecundario,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: hayAnterior ? onAnterior : null,
            tooltip: 'Pagina anterior',
            icon: const Icon(
              Icons.chevron_left,
            ),
            color: _verdeOscuro,
          ),
          IconButton(
            onPressed: haySiguiente ? onSiguiente : null,
            tooltip: 'Pagina siguiente',
            icon: const Icon(
              Icons.chevron_right,
            ),
            color: _verdeOscuro,
          ),
        ],
      ),
    );
  }
}

class _FilaProductoInventario extends StatelessWidget {
  final InventarioItem producto;
  final bool soloLectura;
  final VoidCallback onVerDetalle;
  final VoidCallback onEditarUbicacion;

  const _FilaProductoInventario({
    required this.producto,
    required this.soloLectura,
    required this.onVerDetalle,
    required this.onEditarUbicacion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        16,
        14,
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _bordeSuave,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.05,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _fondoIcono(),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color: _colorIcono(),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 16,
            child: _MetricaInventario(
              titulo: 'Codigo',
              child: Text(
                producto.codigoVisible,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _textoPrincipal,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 28,
            child: _MetricaInventario(
              titulo: 'Producto',
              child: Text(
                producto.nombre,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _textoPrincipal,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 11,
            child: _MetricaInventario(
              titulo: 'Stock',
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
          ),
          Expanded(
            flex: 14,
            child: _MetricaInventario(
              titulo: 'Precio',
              child: Text(
                ConfigMoneda.formato(
                  producto.precioVenta,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _verdeOscuro,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 14,
            child: _MetricaInventario(
              titulo: 'Ubicacion',
              child: Text(
                producto.ubicacionVisible,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: producto.ubicacionVisible == '-'
                      ? _textoSecundario
                      : _textoPrincipal,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 17,
            child: _MetricaInventario(
              titulo: 'Estado',
              child: Align(
                alignment: Alignment.centerLeft,
                child: _BadgeEstado(
                  estado: producto.estadoStock,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 14,
            child: _MetricaInventario(
              titulo: 'Accion',
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Ver detalle',
                    onPressed: onVerDetalle,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 30,
                    ),
                    icon: const Icon(
                      Icons.visibility_outlined,
                    ),
                    color: _verdeOscuro,
                    iconSize: 18,
                  ),
                  if (!soloLectura) ...[
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: 'Editar lote',
                      onPressed: onEditarUbicacion,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 30,
                      ),
                      icon: const Icon(
                        Icons.edit_note_outlined,
                      ),
                      color: _azul,
                      iconSize: 18,
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

  Color _fondoIcono() {
    switch (producto.estadoStock) {
      case EstadoStockInventario.enExistencia:
        return const Color(
          0xFFEAF7DF,
        );

      case EstadoStockInventario.stockBajo:
        return const Color(
          0xFFE7F0FF,
        );

      case EstadoStockInventario.agotado:
        return const Color(
          0xFFFFE8E8,
        );
    }
  }

  Color _colorIcono() {
    switch (producto.estadoStock) {
      case EstadoStockInventario.enExistencia:
        return _verdeOscuro;

      case EstadoStockInventario.stockBajo:
        return _azul;

      case EstadoStockInventario.agotado:
        return _rojo;
    }
  }
}

class _MetricaInventario extends StatelessWidget {
  final String titulo;
  final Widget child;

  const _MetricaInventario({
    required this.titulo,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textoSecundario,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          child,
        ],
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
        fondo = const Color(
          0xFFE8F5DD,
        );
        texto = _verdeOscuro;
        label = 'En existencia';
        break;

      case EstadoStockInventario.stockBajo:
        fondo = const Color(
          0xFFE7F0FF,
        );
        texto = _azul;
        label = 'Stock bajo';
        break;

      case EstadoStockInventario.agotado:
        fondo = const Color(
          0xFFFFE9E9,
        );
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
        padding: const EdgeInsets.symmetric(
          vertical: 42,
        ),
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
                icon: const Icon(
                  Icons.refresh,
                ),
                label: const Text(
                  'Reintentar',
                ),
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
    final inventarioActivo = producto.inventarioActivo;

    final productoActivo = producto.productoActivo;

    final registroActivo = inventarioActivo && productoActivo;

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 760,
        height: 455,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.18,
              ),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 250,
              child: _ResumenProductoDetalle(
                producto: producto,
                activo: registroActivo,
              ),
            ),
            Container(
              width: 1,
              color: const Color(
                0xFFE7E8E3,
              ),
            ),
            Expanded(
              child: _PanelDetallesTecnicos(
                producto: producto,
                inventarioActivo: inventarioActivo,
                productoActivo: productoActivo,
                onCerrar: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumenProductoDetalle extends StatelessWidget {
  final InventarioItem producto;
  final bool activo;

  const _ResumenProductoDetalle({
    required this.producto,
    required this.activo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        28,
        28,
        28,
        26,
      ),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: const BoxDecoration(
              color: Color(0xFFEEF8E4),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: _verdeOscuro,
              size: 44,
            ),
          ),
          const SizedBox(height: 16),
          _BadgeActivoDetalle(
            activo: activo,
          ),
          const SizedBox(height: 12),
          Text(
            producto.nombre,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textoPrincipal,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Categoría: '
            '${producto.categoria.trim().isEmpty ? 'Sin categoría' : producto.categoria}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textoSecundario,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          _DatoResumenLateral(
            label: 'Precio',
            child: Text(
              ConfigMoneda.formato(
                producto.precioVenta,
              ),
              style: const TextStyle(
                color: _verdeOscuro,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _DatoResumenLateral(
            label: 'Stock',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${producto.stockActual}',
                  style: TextStyle(
                    color: producto.stockActual == 0 ? _rojo : _azul,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 5),
                const Padding(
                  padding: EdgeInsets.only(
                    bottom: 2,
                  ),
                  child: Text(
                    'pzas',
                    style: TextStyle(
                      color: _azul,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeActivoDetalle extends StatelessWidget {
  final bool activo;

  const _BadgeActivoDetalle({
    required this.activo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: activo ? const Color(0xFF6FD000) : const Color(0xFFFFE8E8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        activo ? 'Activo' : 'Inactivo',
        style: TextStyle(
          color: activo ? Colors.white : _rojo,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DatoResumenLateral extends StatelessWidget {
  final String label;
  final Widget child;

  const _DatoResumenLateral({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: _textoPrincipal,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _PanelDetallesTecnicos extends StatelessWidget {
  final InventarioItem producto;
  final bool inventarioActivo;
  final bool productoActivo;
  final VoidCallback onCerrar;

  const _PanelDetallesTecnicos({
    required this.producto,
    required this.inventarioActivo,
    required this.productoActivo,
    required this.onCerrar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFAF9F7),
      padding: const EdgeInsets.fromLTRB(
        28,
        24,
        28,
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'DETALLES TÉCNICOS',
                  style: TextStyle(
                    color: _textoPrincipal,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              IconButton(
                onPressed: onCerrar,
                tooltip: 'Cerrar',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                icon: const Icon(
                  Icons.close,
                  color: _textoSecundario,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const separacion = 14.0;

                final anchoTarjeta =
                    (constraints.maxWidth - (separacion * 2)) / 3;

                return Align(
                  alignment: Alignment.topLeft,
                  child: Wrap(
                    spacing: separacion,
                    runSpacing: 16,
                    children: [
                      _TarjetaDetalleTecnico(
                        width: anchoTarjeta,
                        label: 'ID Inventario',
                        value: '${producto.idInventario}',
                      ),
                      _TarjetaDetalleTecnico(
                        width: anchoTarjeta,
                        label: 'ID Producto',
                        value: '${producto.idProducto ?? '-'}',
                      ),
                      _TarjetaDetalleTecnico(
                        width: anchoTarjeta,
                        label: 'Código',
                        value: producto.codigoVisible,
                      ),
                      _TarjetaDetalleTecnico(
                        width: anchoTarjeta,
                        label: 'Lote',
                        value: producto.codigoLote.trim().isEmpty
                            ? '-'
                            : producto.codigoLote,
                      ),
                      _TarjetaDetalleTecnico(
                        width: anchoTarjeta,
                        label: 'Ubicación',
                        value: producto.ubicacionVisible == '-'
                            ? 'No especificada'
                            : producto.ubicacionVisible,
                        valueItalic: producto.ubicacionVisible == '-',
                      ),
                      _TarjetaDetalleTecnico(
                        width: anchoTarjeta,
                        label: 'Unidad',
                        value: producto.unidad.trim().isEmpty
                            ? '-'
                            : producto.unidad,
                        valueColor: producto.unidad.trim().isEmpty
                            ? _textoSecundario
                            : _textoPrincipal,
                      ),
                      _TarjetaDetalleTecnico(
                        width: anchoTarjeta,
                        label: 'Caducidad',
                        value: _formatoFechaDetalle(
                          producto.fechaCaducidad,
                        ),
                      ),
                      _TarjetaDetalleTecnico(
                        width: anchoTarjeta,
                        label: 'Inv. Activo',
                        value: inventarioActivo ? 'Sí' : 'No',
                        trailing: Icon(
                          inventarioActivo
                              ? Icons.check_circle_outline
                              : Icons.cancel_outlined,
                          color: inventarioActivo ? _verdeOscuro : _rojo,
                          size: 19,
                        ),
                      ),
                      _TarjetaDetalleTecnico(
                        width: anchoTarjeta,
                        label: 'Prod. Activo',
                        value: productoActivo ? 'Sí' : 'No',
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            width: double.infinity,
            height: 1,
            color: const Color(
              0xFFE7E8E3,
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaDetalleTecnico extends StatelessWidget {
  final double width;
  final String label;
  final String value;
  final Widget? trailing;
  final bool valueItalic;
  final Color? valueColor;

  const _TarjetaDetalleTecnico({
    required this.width,
    required this.label,
    required this.value,
    this.trailing,
    this.valueItalic = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 76,
      padding: const EdgeInsets.fromLTRB(
        12,
        11,
        10,
        10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: const Color(
            0xFFE8E9E5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.035,
            ),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textoSecundario,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  value.trim().isEmpty ? '-' : value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: valueColor ?? _textoPrincipal,
                    fontSize: valueItalic ? 10 : 12,
                    fontWeight: valueItalic ? FontWeight.w600 : FontWeight.w900,
                    fontStyle:
                        valueItalic ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 6),
                trailing!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

String _formatoFechaDetalle(
  DateTime? fecha,
) {
  if (fecha == null) {
    return 'Sin fecha';
  }

  return '${fecha.day.toString().padLeft(2, '0')}/'
      '${fecha.month.toString().padLeft(2, '0')}/'
      '${fecha.year}';
}

class _DatosLoteInventario {
  final String codigoLote;
  final String? fechaCaducidad;
  final double precioVenta;
  final String? ubicacionLetra;
  final int? ubicacionNumero;

  const _DatosLoteInventario({
    required this.codigoLote,
    required this.fechaCaducidad,
    required this.precioVenta,
    required this.ubicacionLetra,
    required this.ubicacionNumero,
  });
}

class _DialogoLoteInventario extends StatefulWidget {
  final InventarioItem producto;

  const _DialogoLoteInventario({
    required this.producto,
  });

  @override
  State<_DialogoLoteInventario> createState() => _DialogoLoteInventarioState();
}

class _DialogoLoteInventarioState extends State<_DialogoLoteInventario> {
  late final TextEditingController _loteController;

  late final TextEditingController _fechaController;

  late final TextEditingController _precioController;

  late final TextEditingController _letraController;

  late final TextEditingController _numeroController;

  String? _error;

  @override
  void initState() {
    super.initState();

    _loteController = TextEditingController(
      text: widget.producto.codigoLote,
    );

    _fechaController = TextEditingController(
      text: _formatoFechaApi(
        widget.producto.fechaCaducidad,
      ),
    );

    _precioController = TextEditingController(
      text: widget.producto.precioVenta.toStringAsFixed(2),
    );

    _letraController = TextEditingController(
      text: widget.producto.ubicacionLetra,
    );

    _numeroController = TextEditingController(
      text: widget.producto.ubicacionNumero?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _loteController.dispose();
    _fechaController.dispose();
    _precioController.dispose();
    _letraController.dispose();
    _numeroController.dispose();
    super.dispose();
  }

  void _guardar() {
    final lote = _loteController.text.trim();

    if (lote.isEmpty) {
      setState(() {
        _error = 'Ingresa el lote o deja SIN_LOTE.';
      });

      return;
    }

    final precio = double.tryParse(
      _precioController.text.trim().replaceAll(',', '.'),
    );

    if (precio == null || precio < 0) {
      setState(() {
        _error = 'Ingresa un precio de venta valido.';
      });

      return;
    }

    final letra = _letraController.text.trim().toUpperCase();

    final numeroTexto = _numeroController.text.trim();

    if (letra.isEmpty && numeroTexto.isEmpty) {
      Navigator.of(context).pop(
        _DatosLoteInventario(
          codigoLote: lote,
          fechaCaducidad: _limpiarTextoFecha(
            _fechaController.text,
          ),
          precioVenta: precio,
          ubicacionLetra: null,
          ubicacionNumero: null,
        ),
      );

      return;
    }

    final numero = int.tryParse(numeroTexto);

    if (letra.length != 1 || !RegExp(r'^[A-Z]$').hasMatch(letra)) {
      setState(() {
        _error = 'La letra debe ser una sola letra, por ejemplo A.';
      });

      return;
    }

    if (numero == null || numero <= 0 || numero > 999) {
      setState(() {
        _error = 'El numero debe estar entre 1 y 999.';
      });

      return;
    }

    Navigator.of(context).pop(
      _DatosLoteInventario(
        codigoLote: lote,
        fechaCaducidad: _limpiarTextoFecha(
          _fechaController.text,
        ),
        precioVenta: precio,
        ubicacionLetra: letra,
        ubicacionNumero: numero,
      ),
    );
  }

  Future<void> _seleccionarFecha() async {
    final inicial = DateTime.tryParse(
          _fechaController.text,
        ) ??
        DateTime.now();

    final seleccionada = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Selecciona caducidad',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (seleccionada == null) {
      return;
    }

    setState(() {
      _fechaController.text = _formatoFechaApi(seleccionada);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Editar lote de '
        '${widget.producto.nombre}',
      ),
      content: SizedBox(
        width: 430,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _loteController,
              decoration: const InputDecoration(
                labelText: 'Lote',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _fechaController,
                    readOnly: true,
                    onTap: _seleccionarFecha,
                    decoration: InputDecoration(
                      labelText: 'Fecha de caducidad',
                      hintText: 'YYYY-MM-DD',
                      border: const OutlineInputBorder(),
                      suffixIcon: _fechaController.text.isEmpty
                          ? const Icon(
                              Icons.calendar_month_outlined,
                            )
                          : IconButton(
                              onPressed: () {
                                setState(() {
                                  _fechaController.clear();
                                });
                              },
                              icon: const Icon(
                                Icons.close,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _precioController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Precio venta',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _letraController,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 1,
                    decoration: const InputDecoration(
                      labelText: 'Letra',
                      hintText: 'A',
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _numeroController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Numero',
                      hintText: '1',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Ejemplo: A1, B2, C12. '
              'Deja ambos campos vacios para '
              'quitar la ubicacion. La caducidad '
              'se guarda como YYYY-MM-DD.',
              style: TextStyle(
                color: _textoSecundario,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(
                  color: _rojo,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            'Cancelar',
          ),
        ),
        ElevatedButton(
          onPressed: _guardar,
          child: const Text(
            'Guardar',
          ),
        ),
      ],
    );
  }
}

String _formatoFechaApi(
  DateTime? fecha,
) {
  if (fecha == null) {
    return '';
  }

  return '${fecha.year.toString().padLeft(4, '0')}-'
      '${fecha.month.toString().padLeft(2, '0')}-'
      '${fecha.day.toString().padLeft(2, '0')}';
}

String? _limpiarTextoFecha(String value) {
  final text = value.trim();
  return text.isEmpty ? null : text;
}
