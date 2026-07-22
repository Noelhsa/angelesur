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
const Color _grisCampo = Color(0xFFF8F7F4);
const Color _rojo = Color(0xFFE02020);

class ContenidoCatalogoInventario extends StatefulWidget {
  const ContenidoCatalogoInventario({
    super.key,
  });

  @override
  State<ContenidoCatalogoInventario> createState() =>
      _ContenidoCatalogoInventarioState();
}

class _ContenidoCatalogoInventarioState
    extends State<ContenidoCatalogoInventario> {
  final InventarioApiService _inventarioApiService =
      InventarioApiService();

  final TextEditingController _busquedaController =
      TextEditingController();

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
        .where(
          (categoria) => categoria.trim().isNotEmpty,
        )
        .toSet()
        .toList()
      ..sort();

    return [
      'Todas las categorias',
      ...categorias,
    ];
  }

  List<InventarioItem> get _productosFiltrados {
    return _productos.where((producto) {
      final coincideCategoria =
          _categoriaSeleccionada == 'Todas las categorias' ||
              producto.categoria == _categoriaSeleccionada;

      final coincideEstado = switch (_estadoSeleccionado) {
        'En existencia' =>
          producto.estadoStock ==
              EstadoStockInventario.enExistencia,
        'Stock bajo' =>
          producto.estadoStock ==
              EstadoStockInventario.stockBajo,
        'Agotado' =>
          producto.estadoStock ==
              EstadoStockInventario.agotado,
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
      final productos =
          await _inventarioApiService.listarActual(
        busqueda: _busquedaController.text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _productos = productos;

        if (!_categorias.contains(
          _categoriaSeleccionada,
        )) {
          _categoriaSeleccionada =
              'Todas las categorias';
        }

        _cargando = false;
      });
    } on ApiException catch (error) {
      _mostrarError(error.message);
    } catch (_) {
      _mostrarError(
        'No se pudo cargar el inventario',
      );
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

  Future<void> _editarUbicacion(
    InventarioItem producto,
  ) async {
    final datos =
        await showDialog<_DatosUbicacionInventario>(
      context: context,
      builder: (context) {
        return _DialogoUbicacionInventario(
          producto: producto,
        );
      },
    );

    if (datos == null) {
      return;
    }

    try {
      final actualizado =
          await _inventarioApiService.actualizarUbicacion(
        idInventario: producto.idInventario,
        ubicacionLetra: datos.ubicacionLetra,
        ubicacionNumero: datos.ubicacionNumero,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        final index = _productos.indexWhere(
          (item) {
            return item.idInventario ==
                actualizado.idInventario;
          },
        );

        if (index >= 0) {
          _productos[index] = actualizado;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ubicacion actualizada',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo actualizar la ubicacion',
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
              busquedaController:
                  _busquedaController,
              categoriaSeleccionada:
                  _categoriaSeleccionada,
              categorias: _categorias,
              estadoSeleccionado:
                  _estadoSeleccionado,
              onCategoriaChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _categoriaSeleccionada = value;
                });
              },
              onEstadoChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _estadoSeleccionado = value;
                });
              },
              onBuscar: _cargarInventario,
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
                mensaje:
                    'No hay productos para mostrar',
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final anchoTabla =
                      constraints.maxWidth < 980
                          ? 980.0
                          : constraints.maxWidth;

                  return SingleChildScrollView(
                    scrollDirection:
                        Axis.horizontal,
                    child: SizedBox(
                      width: anchoTabla,
                      child: _TablaInventario(
                        productos:
                            _productosFiltrados,
                        onVerDetalle:
                            _mostrarDetalle,
                        onEditarUbicacion:
                            _editarUbicacion,
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
  final TextEditingController
      busquedaController;

  final String categoriaSeleccionada;
  final List<String> categorias;
  final String estadoSeleccionado;

  final ValueChanged<String?>
      onCategoriaChanged;

  final ValueChanged<String?>
      onEstadoChanged;

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
      padding: const EdgeInsets.fromLTRB(
        18,
        14,
        18,
        14,
      ),
      decoration: BoxDecoration(
        color: _fondoPagina,
        border: Border.all(
          color: _bordeSuave,
        ),
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
      crossAxisAlignment:
          CrossAxisAlignment.start,
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
              hintText:
                  'Nombre, codigo, lote o ubicacion',
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
              contentPadding:
                  const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(5),
                borderSide: const BorderSide(
                  color: Color(0xFFC8D6C0),
                ),
              ),
              enabledBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(5),
                borderSide: const BorderSide(
                  color: Color(0xFFC8D6C0),
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
    final valorSeguro =
        opciones.contains(valor)
            ? valor
            : opciones.first;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
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
          child:
              DropdownButtonFormField<String>(
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
              contentPadding:
                  const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(5),
                borderSide: const BorderSide(
                  color: Color(0xFFC8D6C0),
                ),
              ),
              enabledBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(5),
                borderSide: const BorderSide(
                  color: Color(0xFFC8D6C0),
                ),
              ),
              focusedBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(5),
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

class _BotonSecundarioCatalogo
    extends StatelessWidget {
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
          padding:
              const EdgeInsets.symmetric(
            horizontal: 14,
          ),
          side: const BorderSide(
            color: Color(0xFFC8D6C0),
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(5),
          ),
        ),
      ),
    );
  }
}

class _TablaInventario extends StatelessWidget {
  final List<InventarioItem> productos;

  final ValueChanged<InventarioItem>
      onVerDetalle;

  final ValueChanged<InventarioItem>
      onEditarUbicacion;

  const _TablaInventario({
    required this.productos,
    required this.onVerDetalle,
    required this.onEditarUbicacion,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0;
            index < productos.length;
            index++) ...[
          if (index > 0)
            const SizedBox(
              height: 10,
            ),
          _FilaProductoInventario(
            producto: productos[index],
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

class _FilaProductoInventario
    extends StatelessWidget {
  final InventarioItem producto;
  final VoidCallback onVerDetalle;
  final VoidCallback onEditarUbicacion;

  const _FilaProductoInventario({
    required this.producto,
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
        borderRadius:
            BorderRadius.circular(8),
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
              borderRadius:
                  BorderRadius.circular(8),
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
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _textoPrincipal,
                  fontSize: 10,
                  fontWeight:
                      FontWeight.w800,
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
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _textoPrincipal,
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w900,
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
                  fontWeight:
                      FontWeight.w900,
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
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _verdeOscuro,
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w900,
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
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      producto.ubicacionVisible ==
                              '-'
                          ? _textoSecundario
                          : _textoPrincipal,
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 17,
            child: _MetricaInventario(
              titulo: 'Estado',
              child: Align(
                alignment:
                    Alignment.centerLeft,
                child: _BadgeEstado(
                  estado:
                      producto.estadoStock,
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
                    constraints:
                        const BoxConstraints(
                      minWidth: 32,
                      minHeight: 30,
                    ),
                    icon: const Icon(
                      Icons.visibility_outlined,
                    ),
                    color: _verdeOscuro,
                    iconSize: 18,
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip:
                        'Editar ubicacion',
                    onPressed:
                        onEditarUbicacion,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(
                      minWidth: 32,
                      minHeight: 30,
                    ),
                    icon: const Icon(
                      Icons
                          .edit_location_alt_outlined,
                    ),
                    color: _azul,
                    iconSize: 18,
                  ),
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
        return const Color(0xFFEAF7DF);

      case EstadoStockInventario.stockBajo:
        return const Color(0xFFE7F0FF);

      case EstadoStockInventario.agotado:
        return const Color(0xFFFFE8E8);
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

class _MetricaInventario
    extends StatelessWidget {
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
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textoSecundario,
              fontSize: 9,
              fontWeight:
                  FontWeight.w700,
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
        borderRadius:
            BorderRadius.circular(14),
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

class _EstadoInventarioCatalogo
    extends StatelessWidget {
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
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Text(
              mensaje,
              style: const TextStyle(
                color: _textoPrincipal,
                fontSize: 15,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
            if (onReintentar != null) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed:
                    onReintentar,
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

class _DialogoDetalleInventario
    extends StatelessWidget {
  final InventarioItem producto;

  const _DialogoDetalleInventario({
    required this.producto,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        producto.nombre,
      ),
      content: SizedBox(
        width: 460,
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _DatoInventario(
              label: 'ID inventario',
              value:
                  '${producto.idInventario}',
            ),
            _DatoInventario(
              label: 'ID producto',
              value:
                  '${producto.idProducto ?? '-'}',
            ),
            _DatoInventario(
              label: 'Codigo',
              value:
                  producto.codigoVisible,
            ),
            _DatoInventario(
              label: 'Lote',
              value: producto.codigoLote,
            ),
            _DatoInventario(
              label: 'Ubicacion',
              value:
                  producto.ubicacionVisible,
            ),
            _DatoInventario(
              label: 'Categoria',
              value: producto.categoria,
            ),
            _DatoInventario(
              label: 'Unidad',
              value: producto.unidad,
            ),
            _DatoInventario(
              label: 'Stock',
              value:
                  '${producto.stockActual}',
            ),
            _DatoInventario(
              label: 'Precio',
              value: ConfigMoneda.formato(
                producto.precioVenta,
              ),
            ),
            _DatoInventario(
              label: 'Caducidad',
              value: _formatoFecha(
                producto.fechaCaducidad,
              ),
            ),
            _DatoInventario(
              label: 'Inventario activo',
              value:
                  producto.inventarioActivo
                      ? 'Si'
                      : 'No',
            ),
            _DatoInventario(
              label: 'Producto activo',
              value: producto.productoActivo
                  ? 'Si'
                  : 'No',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            'Cerrar',
          ),
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

class _DatosUbicacionInventario {
  final String? ubicacionLetra;
  final int? ubicacionNumero;

  const _DatosUbicacionInventario({
    required this.ubicacionLetra,
    required this.ubicacionNumero,
  });
}

class _DialogoUbicacionInventario
    extends StatefulWidget {
  final InventarioItem producto;

  const _DialogoUbicacionInventario({
    required this.producto,
  });

  @override
  State<_DialogoUbicacionInventario>
      createState() =>
          _DialogoUbicacionInventarioState();
}

class _DialogoUbicacionInventarioState
    extends State<_DialogoUbicacionInventario> {
  late final TextEditingController
      _letraController;

  late final TextEditingController
      _numeroController;

  String? _error;

  @override
  void initState() {
    super.initState();

    _letraController =
        TextEditingController(
      text: widget.producto.ubicacionLetra,
    );

    _numeroController =
        TextEditingController(
      text: widget.producto.ubicacionNumero
              ?.toString() ??
          '',
    );
  }

  @override
  void dispose() {
    _letraController.dispose();
    _numeroController.dispose();
    super.dispose();
  }

  void _guardar() {
    final letra =
        _letraController.text
            .trim()
            .toUpperCase();

    final numeroTexto =
        _numeroController.text.trim();

    if (letra.isEmpty &&
        numeroTexto.isEmpty) {
      Navigator.of(context).pop(
        const _DatosUbicacionInventario(
          ubicacionLetra: null,
          ubicacionNumero: null,
        ),
      );

      return;
    }

    final numero =
        int.tryParse(numeroTexto);

    if (letra.length != 1 ||
        !RegExp(r'^[A-Z]$')
            .hasMatch(letra)) {
      setState(() {
        _error =
            'La letra debe ser una sola letra, por ejemplo A.';
      });

      return;
    }

    if (numero == null ||
        numero <= 0 ||
        numero > 999) {
      setState(() {
        _error =
            'El numero debe estar entre 1 y 999.';
      });

      return;
    }

    Navigator.of(context).pop(
      _DatosUbicacionInventario(
        ubicacionLetra: letra,
        ubicacionNumero: numero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Ubicacion de ${widget.producto.nombre}',
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller:
                        _letraController,
                    textCapitalization:
                        TextCapitalization
                            .characters,
                    maxLength: 1,
                    decoration:
                        const InputDecoration(
                      labelText: 'Letra',
                      hintText: 'A',
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller:
                        _numeroController,
                    keyboardType:
                        TextInputType.number,
                    decoration:
                        const InputDecoration(
                      labelText: 'Numero',
                      hintText: '1',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Ejemplo: A1, B2, C12. Deja ambos campos vacios para quitar la ubicacion.',
              style: TextStyle(
                color: _textoSecundario,
                fontSize: 12,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(
                  color: _rojo,
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w800,
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
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F4F1),
        border: Border.all(
          color: _bordeSuave,
        ),
        borderRadius:
            BorderRadius.circular(7),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _textoSecundario,
              fontSize: 10,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? '-' : value,
            maxLines: 2,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textoPrincipal,
              fontSize: 12,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}