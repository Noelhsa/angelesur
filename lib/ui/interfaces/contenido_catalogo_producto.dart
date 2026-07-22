import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/productos_api_service.dart';
import 'menu_carta_catalogo_producto.dart';

const Color _fondoPagina = Color(0xFFF8F6F5);
const Color _verdeOscuro = Color(0xFF397800);
const Color _azul = Color(0xFF0B63CE);
const Color _rojo = Color(0xFFE02020);
const Color _textoPrincipal = Color(0xFF1F2933);
const Color _textoSecundario = Color(0xFF667085);
const Color _bordeSuave = Color(0xFFD9E6D3);
const Color _grisCampo = Color(0xFFF8F7F4);

const List<String> _categoriasProducto = [
  'General',
  'Higiene',
  'Curacion',
  'Bebidas',
  'Dispositivo',
  'Otro',
];

class ContenidoCatalogoProducto extends StatefulWidget {
  const ContenidoCatalogoProducto({
    super.key,
  });

  @override
  State<ContenidoCatalogoProducto> createState() =>
      _ContenidoCatalogoProductoState();
}

class _ContenidoCatalogoProductoState
    extends State<ContenidoCatalogoProducto> {
  final ProductosApiService _productosApiService =
      ProductosApiService();

  final TextEditingController _busquedaController =
      TextEditingController();

  String _categoriaSeleccionada = 'Todas las categorias';
  String _estadoSeleccionado = 'Todos los estados';
  String _tipoSeleccionado = 'Todos los tipos';

  bool _mostrarMenuNuevoProducto = false;
  bool _cargando = true;
  bool _procesando = false;

  String? _error;

  List<ProductoCatalogoApi> _productos = [];

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  List<String> get _categorias {
    final categorias = _productos
        .map(
          (producto) => producto.categoria ?? '',
        )
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

  List<ProductoCatalogoApi> get _productosFiltrados {
    return _productos.where((producto) {
      final coincideCategoria =
          _categoriaSeleccionada == 'Todas las categorias' ||
              producto.categoria == _categoriaSeleccionada;

      final coincideEstado = switch (_estadoSeleccionado) {
        'Activo' => producto.activo,
        'Inactivo' => !producto.activo,
        _ => true,
      };

      return coincideCategoria && coincideEstado;
    }).toList();
  }

  Future<void> _cargarProductos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final tipo = switch (_tipoSeleccionado) {
        'Medicamentos' => 'MEDICAMENTO',
        'Productos' => 'PRODUCTO',
        _ => null,
      };

      final productos =
          await _productosApiService.listarProductos(
        busqueda: _busquedaController.text,
        tipo: tipo,
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
        'No se pudo cargar el catalogo de productos',
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
      _procesando = false;
    });
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
      ),
    );
  }

  Future<void> _mostrarDetalle(
    ProductoCatalogoApi producto,
  ) async {
    try {
      final detalle =
          await _productosApiService.obtenerProducto(
        producto.idProducto,
      );

      if (!mounted) {
        return;
      }

      showDialog<void>(
        context: context,
        builder: (context) {
          return _DialogoDetalleProducto(
            producto: detalle,
          );
        },
      );
    } on ApiException catch (error) {
      _mostrarMensaje(error.message);
    } catch (_) {
      _mostrarMensaje(
        'No se pudo cargar el detalle',
      );
    }
  }

  Future<void> _guardarProducto({
    ProductoCatalogoApi? producto,
  }) async {
    final datos = await showDialog<ProductoPayload>(
      context: context,
      builder: (context) {
        return _DialogoProducto(
          producto: producto,
        );
      },
    );

    if (datos == null) {
      return;
    }

    setState(() {
      _procesando = true;
    });

    try {
      if (producto == null) {
        await _productosApiService.crearProducto(
          datos,
        );

        _mostrarMensaje(
          'Producto creado',
        );
      } else {
        await _productosApiService.actualizarProducto(
          producto.idProducto,
          datos,
        );

        _mostrarMensaje(
          'Producto actualizado',
        );
      }

      await _cargarProductos();
    } on ApiException catch (error) {
      _mostrarMensaje(error.message);
    } catch (_) {
      _mostrarMensaje(
        'No se pudo guardar el producto',
      );
    } finally {
      if (mounted) {
        setState(() {
          _procesando = false;
        });
      }
    }
  }

  Future<void> _guardarProductoDesdeCarta(
    ProductoPayload datos,
  ) async {
    setState(() {
      _procesando = true;
    });

    try {
      await _productosApiService.crearProducto(
        datos,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _mostrarMenuNuevoProducto = false;
      });

      _mostrarMensaje(
        datos.tipo == 'MEDICAMENTO'
            ? 'Medicamento registrado'
            : 'Producto registrado',
      );

      await _cargarProductos();
    } on ApiException catch (error) {
      _mostrarMensaje(error.message);
    } catch (_) {
      _mostrarMensaje(
        'No se pudo registrar el producto',
      );
    } finally {
      if (mounted) {
        setState(() {
          _procesando = false;
        });
      }
    }
  }

  Future<void> _cambiarEstado(
    ProductoCatalogoApi producto,
  ) async {
    setState(() {
      _procesando = true;
    });

    try {
      await _productosApiService.cambiarEstado(
        producto.idProducto,
        activo: !producto.activo,
      );

      _mostrarMensaje(
        producto.activo
            ? 'Producto desactivado'
            : 'Producto activado',
      );

      await _cargarProductos();
    } on ApiException catch (error) {
      _mostrarMensaje(error.message);
    } catch (_) {
      _mostrarMensaje(
        'No se pudo cambiar el estado del producto',
      );
    } finally {
      if (mounted) {
        setState(() {
          _procesando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _fondoPagina,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                10,
                20,
                10,
                28,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _PanelFiltrosProducto(
                    busquedaController:
                        _busquedaController,
                    categoriaSeleccionada:
                        _categoriaSeleccionada,
                    categorias: _categorias,
                    estadoSeleccionado:
                        _estadoSeleccionado,
                    tipoSeleccionado:
                        _tipoSeleccionado,
                    procesando: _procesando,
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
                    onTipoChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        _tipoSeleccionado = value;
                      });

                      _cargarProductos();
                    },
                    onBuscar: _cargarProductos,
                    onRefrescar: _cargarProductos,
                    onNuevoProducto: () {
                      setState(() {
                        _mostrarMenuNuevoProducto = true;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  if (_cargando)
                    const _EstadoProductos(
                      mensaje:
                          'Cargando productos...',
                    )
                  else if (_error != null)
                    _EstadoProductos(
                      mensaje: _error!,
                      onReintentar:
                          _cargarProductos,
                    )
                  else if (_productosFiltrados.isEmpty)
                    const _EstadoProductos(
                      mensaje:
                          'No hay productos para mostrar',
                    )
                  else
                    LayoutBuilder(
                      builder:
                          (context, constraints) {
                        final anchoTabla =
                            constraints.maxWidth <
                                    1050
                                ? 1050.0
                                : constraints
                                    .maxWidth;

                        return SingleChildScrollView(
                          scrollDirection:
                              Axis.horizontal,
                          child: SizedBox(
                            width: anchoTabla,
                            child:
                                _TablaProductos(
                              productos:
                                  _productosFiltrados,
                              procesando:
                                  _procesando,
                              onDetalle:
                                  _mostrarDetalle,
                              onEditar: (producto) {
                                _guardarProducto(
                                  producto: producto,
                                );
                              },
                              onCambiarEstado:
                                  _cambiarEstado,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          if (_mostrarMenuNuevoProducto)
            MenuCartaCatalogoProducto(
              onCerrar: () {
                setState(() {
                  _mostrarMenuNuevoProducto = false;
                });
              },
              onGuardarProducto:
                  _guardarProductoDesdeCarta,
            ),
        ],
      ),
    );
  }
}

class _PanelFiltrosProducto extends StatelessWidget {
  final TextEditingController
      busquedaController;

  final String categoriaSeleccionada;
  final List<String> categorias;
  final String estadoSeleccionado;
  final String tipoSeleccionado;
  final bool procesando;

  final ValueChanged<String?>
      onCategoriaChanged;

  final ValueChanged<String?>
      onEstadoChanged;

  final ValueChanged<String?>
      onTipoChanged;

  final VoidCallback onBuscar;
  final VoidCallback onRefrescar;
  final VoidCallback onNuevoProducto;

  const _PanelFiltrosProducto({
    required this.busquedaController,
    required this.categoriaSeleccionada,
    required this.categorias,
    required this.estadoSeleccionado,
    required this.tipoSeleccionado,
    required this.procesando,
    required this.onCategoriaChanged,
    required this.onEstadoChanged,
    required this.onTipoChanged,
    required this.onBuscar,
    required this.onRefrescar,
    required this.onNuevoProducto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Wrap(
        spacing: 14,
        runSpacing: 12,
        crossAxisAlignment:
            WrapCrossAlignment.end,
        children: [
          SizedBox(
            width: 240,
            child: _CampoBusqueda(
              controller: busquedaController,
              onSubmitted: onBuscar,
            ),
          ),
          SizedBox(
            width: 175,
            child: _CampoDropdown(
              etiqueta: 'Tipo',
              valor: tipoSeleccionado,
              opciones: const [
                'Todos los tipos',
                'Medicamentos',
                'Productos',
              ],
              onChanged: onTipoChanged,
            ),
          ),
          SizedBox(
            width: 190,
            child: _CampoDropdown(
              etiqueta: 'Categoria',
              valor: categoriaSeleccionada,
              opciones: categorias,
              onChanged: onCategoriaChanged,
            ),
          ),
          SizedBox(
            width: 170,
            child: _CampoDropdown(
              etiqueta: 'Estado',
              valor: estadoSeleccionado,
              opciones: const [
                'Todos los estados',
                'Activo',
                'Inactivo',
              ],
              onChanged: onEstadoChanged,
            ),
          ),
          _BotonSecundarioCatalogo(
            texto: 'Buscar',
            icono: Icons.search,
            onTap: onBuscar,
          ),
          _BotonSecundarioCatalogo(
            texto: 'Actualizar',
            icono: Icons.refresh,
            onTap: onRefrescar,
          ),
          _BotonPrincipalCatalogo(
            texto: procesando
                ? 'Guardando...'
                : 'Nuevo Producto',
            icono: Icons.add,
            onTap:
                procesando ? null : onNuevoProducto,
          ),
        ],
      ),
    );
  }
}

class _CampoBusqueda extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmitted;

  const _CampoBusqueda({
    required this.controller,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onSubmitted: (_) {
        onSubmitted();
      },
      decoration: InputDecoration(
        labelText: 'Buscar producto',
        hintText:
            'Nombre, codigo o categoria',
        prefixIcon: const Icon(
          Icons.search,
          size: 18,
        ),
        filled: true,
        fillColor: _grisCampo,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(5),
          borderSide: const BorderSide(
            color: Color(0xFFC8D6C0),
          ),
        ),
        isDense: true,
      ),
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
    final value = opciones.contains(valor)
        ? valor
        : opciones.first;

    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: etiqueta,
        filled: true,
        fillColor: _grisCampo,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(5),
          borderSide: const BorderSide(
            color: Color(0xFFC8D6C0),
          ),
        ),
        isDense: true,
      ),
      items: opciones.map((opcion) {
        return DropdownMenuItem<String>(
          value: opcion,
          child: Text(opcion),
        );
      }).toList(),
      onChanged: onChanged,
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
      height: 42,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(
          icono,
          size: 16,
          color: _textoSecundario,
        ),
        label: Text(
          texto,
          style: const TextStyle(
            color: _textoPrincipal,
            fontSize: 12,
            fontWeight: FontWeight.w800,
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

class _BotonPrincipalCatalogo
    extends StatelessWidget {
  final String texto;
  final IconData icono;
  final VoidCallback? onTap;

  const _BotonPrincipalCatalogo({
    required this.texto,
    required this.icono,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(
          icono,
          size: 16,
          color: Colors.white,
        ),
        label: Text(
          texto,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _verdeOscuro,
          elevation: 0,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 16,
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

class _TablaProductos extends StatelessWidget {
  final List<ProductoCatalogoApi> productos;
  final bool procesando;

  final ValueChanged<ProductoCatalogoApi>
      onDetalle;

  final ValueChanged<ProductoCatalogoApi>
      onEditar;

  final ValueChanged<ProductoCatalogoApi>
      onCambiarEstado;

  const _TablaProductos({
    required this.productos,
    required this.procesando,
    required this.onDetalle,
    required this.onEditar,
    required this.onCambiarEstado,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        for (var index = 0;
            index < productos.length;
            index++) ...[
          if (index > 0)
            const SizedBox(
              height: 10,
            ),
          _FilaProductoCatalogo(
            producto: productos[index],
            procesando: procesando,
            onDetalle: onDetalle,
            onEditar: onEditar,
            onCambiarEstado:
                onCambiarEstado,
          ),
        ],
      ],
    );
  }
}

class _FilaProductoCatalogo
    extends StatelessWidget {
  final ProductoCatalogoApi producto;
  final bool procesando;

  final ValueChanged<ProductoCatalogoApi>
      onDetalle;

  final ValueChanged<ProductoCatalogoApi>
      onEditar;

  final ValueChanged<ProductoCatalogoApi>
      onCambiarEstado;

  const _FilaProductoCatalogo({
    required this.producto,
    required this.procesando,
    required this.onDetalle,
    required this.onEditar,
    required this.onCambiarEstado,
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
        border: Border.all(
          color: _bordeSuave,
        ),
        borderRadius:
            BorderRadius.circular(8),
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
              color: _fondoIconoProducto(),
              borderRadius:
                  BorderRadius.circular(8),
            ),
            child: Icon(
              producto.esMedicamento
                  ? Icons.medication_outlined
                  : Icons.inventory_2_outlined,
              color: _colorIconoProducto(),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 15,
            child:
                _MetricaProductoCatalogo(
              titulo: 'Código',
              child: Text(
                producto.codigoBarras ??
                    'S/C',
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
            child:
                _MetricaProductoCatalogo(
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
            flex: 14,
            child:
                _MetricaProductoCatalogo(
              titulo: 'Tipo',
              child: _Badge(
                texto: _etiqueta(
                  producto.tipo,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 18,
            child:
                _MetricaProductoCatalogo(
              titulo: 'Categoría',
              child: Text(
                producto.categoria ??
                    'Sin categoría',
                maxLines: 2,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _textoPrincipal,
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 12,
            child:
                _MetricaProductoCatalogo(
              titulo: 'Estado',
              child: _BadgeEstado(
                activo: producto.activo,
              ),
            ),
          ),
          Expanded(
            flex: 17,
            child:
                _MetricaProductoCatalogo(
              titulo: 'Acciones',
              child: Row(
                children: [
                  IconButton(
                    onPressed: procesando
                        ? null
                        : () {
                            onDetalle(
                              producto,
                            );
                          },
                    padding:
                        EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(
                      minWidth: 32,
                      minHeight: 30,
                    ),
                    tooltip:
                        'Ver detalle',
                    icon: const Icon(
                      Icons
                          .visibility_outlined,
                    ),
                    color: _azul,
                    iconSize: 18,
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: procesando
                        ? null
                        : () {
                            onEditar(
                              producto,
                            );
                          },
                    padding:
                        EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(
                      minWidth: 32,
                      minHeight: 30,
                    ),
                    tooltip: 'Editar',
                    icon: const Icon(
                      Icons.edit_outlined,
                    ),
                    color: _verdeOscuro,
                    iconSize: 18,
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: procesando
                        ? null
                        : () {
                            onCambiarEstado(
                              producto,
                            );
                          },
                    padding:
                        EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(
                      minWidth: 32,
                      minHeight: 30,
                    ),
                    tooltip: producto.activo
                        ? 'Desactivar'
                        : 'Activar',
                    icon: Icon(
                      producto.activo
                          ? Icons
                              .toggle_on_outlined
                          : Icons
                              .toggle_off_outlined,
                    ),
                    color: producto.activo
                        ? _verdeOscuro
                        : _rojo,
                    iconSize: 22,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _fondoIconoProducto() {
    if (!producto.activo) {
      return const Color(
        0xFFFFE8E8,
      );
    }

    if (producto.esMedicamento) {
      return const Color(
        0xFFE8F1FF,
      );
    }

    return const Color(
      0xFFEAF7DF,
    );
  }

  Color _colorIconoProducto() {
    if (!producto.activo) {
      return _rojo;
    }

    if (producto.esMedicamento) {
      return _azul;
    }

    return _verdeOscuro;
  }
}

class _MetricaProductoCatalogo
    extends StatelessWidget {
  final String titulo;
  final Widget child;

  const _MetricaProductoCatalogo({
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

class _Badge extends StatelessWidget {
  final String texto;

  const _Badge({
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFEDEDEA),
          borderRadius:
              BorderRadius.circular(4),
        ),
        child: Text(
          texto,
          style: const TextStyle(
            color: Color(0xFF5E675F),
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _BadgeEstado extends StatelessWidget {
  final bool activo;

  const _BadgeEstado({
    required this.activo,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: activo
              ? const Color(0xFFEAF8DD)
              : const Color(0xFFFFE8E8),
          borderRadius:
              BorderRadius.circular(4),
        ),
        child: Text(
          activo
              ? 'Activo'
              : 'Inactivo',
          style: TextStyle(
            color: activo
                ? _verdeOscuro
                : _rojo,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _EstadoProductos extends StatelessWidget {
  final String mensaje;
  final VoidCallback? onReintentar;

  const _EstadoProductos({
    required this.mensaje,
    this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          vertical: 42,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Text(
              mensaje,
              textAlign: TextAlign.center,
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

class _DialogoProducto extends StatefulWidget {
  final ProductoCatalogoApi? producto;

  const _DialogoProducto({
    this.producto,
  });

  @override
  State<_DialogoProducto> createState() =>
      _DialogoProductoState();
}

class _DialogoProductoState
    extends State<_DialogoProducto> {
  static const List<String> _tipos = [
    'PRODUCTO',
    'MEDICAMENTO',
  ];

  static const List<String> _vias = [
    'CAPSULA',
    'TABLETA',
    'PASTILLA',
    'SUSPENSION',
    'GOTAS',
    'INYECCION',
    'JARABE',
    'CREMA',
    'POMADA',
    'AEROSOL',
    'SOLUCION',
    'OTRO',
  ];

  static const List<String> _edades = [
    'GENERAL',
    'PEDIATRICO',
    'INFANTIL',
    'ADULTO',
  ];

  late final TextEditingController
      _codigoController;

  late final TextEditingController
      _nombreController;

  late final TextEditingController
      _descripcionController;

  late final TextEditingController
      _presentacionController;

  late final TextEditingController
      _sustanciaController;

  late final TextEditingController
      _dosisController;

  late String _tipo;
  late String _categoria;
  late String _via;
  late String _edad;

  late bool _manejaCaducidad;
  late bool _requiereReceta;

  String? _error;

  @override
  void initState() {
    super.initState();

    final producto = widget.producto;

    _codigoController =
        TextEditingController(
      text: producto?.codigoBarras ?? '',
    );

    _nombreController =
        TextEditingController(
      text: producto?.nombre ?? '',
    );

    _descripcionController =
        TextEditingController(
      text: producto?.descripcion ?? '',
    );

    _presentacionController =
        TextEditingController(
      text: producto?.presentacion ?? '',
    );

    _sustanciaController =
        TextEditingController(
      text: producto?.sustanciaActiva ?? '',
    );

    _dosisController =
        TextEditingController(
      text: producto?.dosis ?? '',
    );

    _tipo = _tipos.contains(
      producto?.tipo,
    )
        ? producto!.tipo
        : 'PRODUCTO';

    _categoria = _opcionesCategoria(
      producto?.categoria,
    ).contains(producto?.categoria)
        ? producto!.categoria!
        : 'General';

    _via = _vias.contains(
      producto?.viaAdministracion,
    )
        ? producto!.viaAdministracion!
        : 'OTRO';

    _edad = _edades.contains(
      producto?.edad,
    )
        ? producto!.edad!
        : 'GENERAL';

    _manejaCaducidad =
        producto?.manejaCaducidad ?? false;

    _requiereReceta =
        producto?.requiereReceta ?? false;
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _presentacionController.dispose();
    _sustanciaController.dispose();
    _dosisController.dispose();

    super.dispose();
  }

  void _confirmar() {
    final nombre =
        _nombreController.text.trim();

    if (nombre.isEmpty) {
      setState(() {
        _error =
            'Ingresa el nombre del producto';
      });

      return;
    }

    Map<String, dynamic>?
        infoMedicamento;

    if (_tipo == 'MEDICAMENTO') {
      infoMedicamento = {
        'presentacion': _limpiar(
          _presentacionController.text,
        ),
        'viaAdministracion': _via,
        'edad': _edad,
        'requiereReceta':
            _requiereReceta,
        'sustanciaActiva': _limpiar(
          _sustanciaController.text,
        ),
        'dosis': _limpiar(
          _dosisController.text,
        ),
      };
    }

    Navigator.of(context).pop(
      ProductoPayload(
        codigoBarras: _limpiar(
          _codigoController.text,
        ),
        nombre: nombre,
        descripcion: _limpiar(
          _descripcionController.text,
        ),
        tipo: _tipo,
        categoria:
            _tipo == 'PRODUCTO'
                ? _categoria
                : null,
        manejaCaducidad:
            _manejaCaducidad,
        infoMedicamento:
            infoMedicamento,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esMedicamento =
        _tipo == 'MEDICAMENTO';

    return AlertDialog(
      title: Text(
        widget.producto == null
            ? 'Nuevo producto'
            : 'Editar producto',
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _CampoTexto(
                      label:
                          'Codigo de barras',
                      controller:
                          _codigoController,
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child:
                        DropdownButtonFormField<
                            String>(
                      initialValue: _tipo,
                      decoration:
                          const InputDecoration(
                        labelText: 'Tipo',
                        border:
                            OutlineInputBorder(),
                      ),
                      items:
                          _tipos.map((tipo) {
                        return DropdownMenuItem<
                            String>(
                          value: tipo,
                          child: Text(
                            _etiqueta(
                              tipo,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _tipo = value;

                          if (value ==
                                  'PRODUCTO' &&
                              !_opcionesCategoria()
                                  .contains(
                                _categoria,
                              )) {
                            _categoria =
                                'General';
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _CampoTexto(
                label: 'Nombre',
                controller:
                    _nombreController,
              ),
              const SizedBox(height: 12),
              if (!esMedicamento)
                DropdownButtonFormField<
                    String>(
                  initialValue:
                      _opcionesCategoria(
                    _categoria,
                  ).contains(_categoria)
                          ? _categoria
                          : 'General',
                  decoration:
                      const InputDecoration(
                    labelText: 'Categoria',
                    border:
                        OutlineInputBorder(),
                  ),
                  items:
                      _opcionesCategoria(
                    _categoria,
                  ).map((categoria) {
                    return DropdownMenuItem<
                        String>(
                      value: categoria,
                      child: Text(
                        categoria,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _categoria = value;
                    });
                  },
                ),
              const SizedBox(height: 12),
              _CampoTexto(
                label: 'Descripcion',
                controller:
                    _descripcionController,
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value:
                    _manejaCaducidad,
                onChanged: (value) {
                  setState(() {
                    _manejaCaducidad =
                        value ?? false;
                  });
                },
                contentPadding:
                    EdgeInsets.zero,
                title: const Text(
                  'Maneja caducidad',
                ),
                controlAffinity:
                    ListTileControlAffinity
                        .leading,
              ),
              if (esMedicamento) ...[
                const Divider(height: 24),
                _CampoTexto(
                  label: 'Presentacion',
                  controller:
                      _presentacionController,
                ),
                const SizedBox(
                  height: 12,
                ),
                Row(
                  children: [
                    Expanded(
                      child:
                          DropdownButtonFormField<
                              String>(
                        initialValue: _via,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Via de administracion',
                          border:
                              OutlineInputBorder(),
                        ),
                        items:
                            _vias.map((via) {
                          return DropdownMenuItem<
                              String>(
                            value: via,
                            child: Text(
                              _etiqueta(
                                via,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            _via = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Expanded(
                      child:
                          DropdownButtonFormField<
                              String>(
                        initialValue: _edad,
                        decoration:
                            const InputDecoration(
                          labelText: 'Edad',
                          border:
                              OutlineInputBorder(),
                        ),
                        items:
                            _edades.map((edad) {
                          return DropdownMenuItem<
                              String>(
                            value: edad,
                            child: Text(
                              _etiqueta(
                                edad,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            _edad = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 12,
                ),
                _CampoTexto(
                  label:
                      'Sustancia activa',
                  controller:
                      _sustanciaController,
                ),
                const SizedBox(
                  height: 12,
                ),
                _CampoTexto(
                  label: 'Dosis',
                  controller:
                      _dosisController,
                ),
                CheckboxListTile(
                  value:
                      _requiereReceta,
                  onChanged: (value) {
                    setState(() {
                      _requiereReceta =
                          value ?? false;
                    });
                  },
                  contentPadding:
                      EdgeInsets.zero,
                  title: const Text(
                    'Requiere receta',
                  ),
                  controlAffinity:
                      ListTileControlAffinity
                          .leading,
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment:
                      Alignment.centerLeft,
                  child: Text(
                    _error!,
                    style:
                        const TextStyle(
                      color: _rojo,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
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
          onPressed: _confirmar,
          child: const Text(
            'Guardar',
          ),
        ),
      ],
    );
  }
}

class _CampoTexto extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;

  const _CampoTexto({
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border:
            const OutlineInputBorder(),
      ),
    );
  }
}

class _DialogoDetalleProducto
    extends StatelessWidget {
  final ProductoCatalogoApi producto;

  const _DialogoDetalleProducto({
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _DatoDetalle(
              'ID',
              '${producto.idProducto}',
            ),
            _DatoDetalle(
              'Codigo',
              producto.codigoBarras ??
                  'Sin codigo',
            ),
            _DatoDetalle(
              'Tipo',
              _etiqueta(
                producto.tipo,
              ),
            ),
            _DatoDetalle(
              'Categoria',
              producto.categoria ??
                  'Sin categoria',
            ),
            _DatoDetalle(
              'Estado',
              producto.activo
                  ? 'Activo'
                  : 'Inactivo',
            ),
            _DatoDetalle(
              'Maneja caducidad',
              producto.manejaCaducidad
                  ? 'Si'
                  : 'No',
            ),
            _DatoDetalle(
              'Descripcion',
              producto.descripcion ??
                  'Sin descripcion',
            ),
            if (producto
                .esMedicamento) ...[
              const Divider(height: 22),
              _DatoDetalle(
                'Presentacion',
                producto.presentacion ??
                    'Sin presentacion',
              ),
              _DatoDetalle(
                'Via',
                producto.viaAdministracion ==
                        null
                    ? 'Sin via'
                    : _etiqueta(
                        producto
                            .viaAdministracion!,
                      ),
              ),
              _DatoDetalle(
                'Edad',
                producto.edad == null
                    ? 'Sin edad'
                    : _etiqueta(
                        producto.edad!,
                      ),
              ),
              _DatoDetalle(
                'Sustancia activa',
                producto.sustanciaActiva ??
                    'Sin sustancia',
              ),
              _DatoDetalle(
                'Dosis',
                producto.dosis ??
                    'Sin dosis',
              ),
              _DatoDetalle(
                'Requiere receta',
                producto.requiereReceta
                    ? 'Si'
                    : 'No',
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
            'Cerrar',
          ),
        ),
      ],
    );
  }
}

class _DatoDetalle extends StatelessWidget {
  final String label;
  final String value;

  const _DatoDetalle(
    this.label,
    this.value,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: _textoSecundario,
                fontSize: 12,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _textoPrincipal,
                fontSize: 12,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String? _limpiar(String value) {
  final text = value.trim();

  return text.isEmpty
      ? null
      : text;
}

List<String> _opcionesCategoria([
  String? actual,
]) {
  final opciones = [
    ..._categoriasProducto,
  ];

  final categoriaActual =
      actual?.trim();

  if (categoriaActual != null &&
      categoriaActual.isNotEmpty &&
      !opciones.contains(
        categoriaActual,
      )) {
    opciones.add(
      categoriaActual,
    );
  }

  return opciones;
}

String _etiqueta(String value) {
  if (value.isEmpty) {
    return value;
  }

  return value
      .toLowerCase()
      .split('_')
      .where(
        (part) => part.isNotEmpty,
      )
      .map(
        (part) =>
            '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}