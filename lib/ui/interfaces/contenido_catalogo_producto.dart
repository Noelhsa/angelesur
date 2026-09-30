import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/productos_api_service.dart';
import '../../models/vias_administracion.dart';
import '../../models/presentaciones_medicamento.dart';
import '../../models/dosis_medicamento.dart';
import 'menu_carta_catalogo_producto.dart';

const Color _fondoPagina = Color(0xFFE2E2E2);
const Color _verdeOscuro = Color(0xFF397800);
const Color _azul = Color(0xFF0B63CE);
const Color _rojo = Color(0xFFE02020);
const Color _textoPrincipal = Color(0xFF1F2933);
const Color _textoSecundario = Color(0xFF667085);
const Color _bordeSuave = Color(0xFFD9E6D3);
const Color _grisCampo = Color(0xFFFFFFFF);

const List<String> _categoriasProducto = [
  'General',
  'Higiene',
  'Curacion',
  'Bebidas',
  'Dispositivo',
  'Otro',
];

class ContenidoCatalogoProducto extends StatefulWidget {
  final bool soloLectura;

  const ContenidoCatalogoProducto({
    super.key,
    this.soloLectura = false,
  });

  @override
  State<ContenidoCatalogoProducto> createState() =>
      _ContenidoCatalogoProductoState();
}

class _ContenidoCatalogoProductoState extends State<ContenidoCatalogoProducto> {
  final ProductosApiService _productosApiService = ProductosApiService();

  final TextEditingController _busquedaController = TextEditingController();

  String _categoriaSeleccionada = 'Todas las categorias';
  String _estadoSeleccionado = 'Todos los estados';
  String _tipoSeleccionado = 'Todos los tipos';

  bool _mostrarMenuNuevoProducto = false;
  bool _cargando = true;
  bool _procesando = false;

  String? _error;

  List<ProductoCatalogoApi> _productos = [];

  int _pagina = 1;
  int _limite = 25;
  int _totalProductos = 0;
  int _totalPaginas = 1;
  bool _hayAnterior = false;
  bool _haySiguiente = false;

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
      ..._categoriasProducto.where(
        (categoria) => !categorias.contains(categoria),
      ),
      if (_categoriaSeleccionada != 'Todas las categorias' &&
          !categorias.contains(_categoriaSeleccionada) &&
          !_categoriasProducto.contains(_categoriaSeleccionada))
        _categoriaSeleccionada,
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

  Future<void> _cargarProductos({
    int? pagina,
  }) async {
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

      final activo = switch (_estadoSeleccionado) {
        'Activo' => true,
        'Inactivo' => false,
        _ => null,
      };

      final categoria = _categoriaSeleccionada == 'Todas las categorias'
          ? null
          : _categoriaSeleccionada;

      final resultado = await _productosApiService.listarProductosPaginados(
        busqueda: _busquedaController.text,
        tipo: tipo,
        categoria: categoria,
        activo: activo,
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
        'No se pudo cargar el catalogo de productos',
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
      _procesando = false;
    });
  }

  void _mostrarMensaje(
    String mensaje,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
        ),
      ),
    );
  }

  Future<void> _mostrarDetalle(
    ProductoCatalogoApi producto,
  ) async {
    try {
      final detalle = await _productosApiService.obtenerProducto(
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
      _mostrarMensaje(
        error.message,
      );
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
      _mostrarMensaje(
        error.message,
      );
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
      _mostrarMensaje(
        error.message,
      );
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
        producto.activo ? 'Producto desactivado' : 'Producto activado',
      );

      await _cargarProductos();
    } on ApiException catch (error) {
      _mostrarMensaje(
        error.message,
      );
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
          // ==============================================================
          // CONTENIDO PRINCIPAL
          // ==============================================================

          Expanded(
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
                  _PanelFiltrosProducto(
                    busquedaController: _busquedaController,
                    categoriaSeleccionada: _categoriaSeleccionada,
                    categorias: _categorias,
                    estadoSeleccionado: _estadoSeleccionado,
                    tipoSeleccionado: _tipoSeleccionado,
                    procesando: _procesando,
                    soloLectura: widget.soloLectura,

                    // IMPORTANTE:
                    // permite adaptar la barra cuando el menú
                    // derecho está abierto.
                    menuNuevoProductoAbierto: _mostrarMenuNuevoProducto,

                    onCategoriaChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        _categoriaSeleccionada = value;
                      });

                      _cargarProductos(
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

                      _cargarProductos(
                        pagina: 1,
                      );
                    },
                    onTipoChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        _tipoSeleccionado = value;
                      });

                      _cargarProductos(
                        pagina: 1,
                      );
                    },
                    onBuscar: () {
                      _cargarProductos(
                        pagina: 1,
                      );
                    },
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
                      mensaje: 'Cargando productos...',
                    )
                  else if (_error != null)
                    _EstadoProductos(
                      mensaje: _error!,
                      onReintentar: _cargarProductos,
                    )
                  else if (_productosFiltrados.isEmpty)
                    const _EstadoProductos(
                      mensaje: 'No hay productos para mostrar',
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final anchoTabla = constraints.maxWidth < 1050
                            ? 1050.0
                            : constraints.maxWidth;

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: anchoTabla,
                            child: _TablaProductos(
                              productos: _productos,
                              procesando: _procesando,
                              soloLectura: widget.soloLectura,
                              onDetalle: _mostrarDetalle,
                              onEditar: (producto) {
                                _guardarProducto(
                                  producto: producto,
                                );
                              },
                              onCambiarEstado: _cambiarEstado,
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 12),
                  _PaginadorCatalogoProducto(
                    pagina: _pagina,
                    totalPaginas: _totalPaginas,
                    total: _totalProductos,
                    limite: _limite,
                    hayAnterior: _hayAnterior,
                    haySiguiente: _haySiguiente,
                    onAnterior: () {
                      _cargarProductos(
                        pagina: _pagina - 1,
                      );
                    },
                    onSiguiente: () {
                      _cargarProductos(
                        pagina: _pagina + 1,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // ==============================================================
          // MENÚ NUEVO PRODUCTO
          //
          // Se eleva 82 px como en la versión que te gustó,
          // pero además aumentamos su altura para que llegue
          // más abajo y no quede el hueco gris.
          // ==============================================================

          if (_mostrarMenuNuevoProducto && !widget.soloLectura)
            SizedBox(
              width: 354,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const desplazamientoSuperior = 82.0;

                  return OverflowBox(
                    alignment: Alignment.topCenter,
                    minWidth: 354,
                    maxWidth: 354,
                    minHeight: constraints.maxHeight + desplazamientoSuperior,
                    maxHeight: constraints.maxHeight + desplazamientoSuperior,
                    child: Transform.translate(
                      offset: const Offset(
                        0,
                        -82,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          0,
                          8,
                          14,
                          8,
                        ),
                        child: MenuCartaCatalogoProducto(
                          onCerrar: () {
                            setState(() {
                              _mostrarMenuNuevoProducto = false;
                            });
                          },
                          onGuardarProducto: _guardarProductoDesdeCarta,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// PANEL SUPERIOR DE FILTROS
// ============================================================================

class _PanelFiltrosProducto extends StatelessWidget {
  final TextEditingController busquedaController;

  final String categoriaSeleccionada;
  final List<String> categorias;

  final String estadoSeleccionado;
  final String tipoSeleccionado;

  final bool procesando;
  final bool soloLectura;

  final bool menuNuevoProductoAbierto;

  final ValueChanged<String?> onCategoriaChanged;
  final ValueChanged<String?> onEstadoChanged;
  final ValueChanged<String?> onTipoChanged;

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
    required this.soloLectura,
    required this.menuNuevoProductoAbierto,
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
        borderRadius: BorderRadius.circular(
          8,
        ),
      ),
      child: LayoutBuilder(
        builder: (
          context,
          constraints,
        ) {
          // ============================================================
          // MENÚ CERRADO
          // ============================================================

          if (!menuNuevoProductoAbierto) {
            return Row(
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
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(
                    top: 4,
                  ),
                  child: _BotonSecundarioCatalogo(
                    texto: 'Actualizar',
                    icono: Icons.refresh,
                    onTap: onRefrescar,
                    ancho: 138,
                  ),
                ),
                if (!soloLectura) ...[
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 5,
                    ),
                    child: _BotonPrincipalCatalogo(
                      texto: procesando ? 'Guardando...' : 'Nuevo Producto',
                      icono: Icons.add,
                      onTap: procesando ? null : onNuevoProducto,
                    ),
                  ),
                ],
              ],
            );
          }

          // ============================================================
          // MENÚ NUEVO PRODUCTO ABIERTO
          //
          // Los campos se vuelven flexibles.
          // Ya no usamos anchos fijos que exceden el área.
          //
          // El botón "Nuevo Producto" no se muestra porque el
          // formulario ya está abierto.
          //
          // Esto elimina el RenderFlex amarillo/negro.
          // ============================================================

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 20,
                child: _CampoBusqueda(
                  controller: busquedaController,
                  onBuscar: onBuscar,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 13,
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
              const SizedBox(width: 10),
              Expanded(
                flex: 15,
                child: _CampoDropdown(
                  etiqueta: 'Categoría',
                  valor: categoriaSeleccionada,
                  opciones: categorias,
                  onChanged: onCategoriaChanged,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 14,
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
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(
                  top: 4,
                ),
                child: _BotonSecundarioCatalogo(
                  texto: 'Actualizar',
                  icono: Icons.refresh,
                  onTap: onRefrescar,

                  // Más compacto únicamente cuando
                  // el panel derecho está abierto.
                  ancho: 108,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================================
// CAMPO BUSCAR
// ============================================================================

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
            style: const TextStyle(
              color: _textoPrincipal,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: _grisCampo,
              hintText: 'Nombre, codigo o categoria',
              hintStyle: const TextStyle(
                color: _textoPrincipal,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: const Icon(
                Icons.search,
                size: 16,
              ),
              suffixIcon: IconButton(
                onPressed: onBuscar,
                padding: EdgeInsets.zero,
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
                borderRadius: BorderRadius.circular(
                  5,
                ),
                borderSide: const BorderSide(
                  color: Color(
                    0xFFC8D6C0,
                  ),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  5,
                ),
                borderSide: const BorderSide(
                  color: Color(
                    0xFFC8D6C0,
                  ),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  5,
                ),
                borderSide: const BorderSide(
                  color: _verdeOscuro,
                  width: 1.2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// DROPDOWN
// ============================================================================

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
                borderRadius: BorderRadius.circular(
                  5,
                ),
                borderSide: const BorderSide(
                  color: Color(
                    0xFFC8D6C0,
                  ),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  5,
                ),
                borderSide: const BorderSide(
                  color: Color(
                    0xFFC8D6C0,
                  ),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  5,
                ),
                borderSide: const BorderSide(
                  color: _verdeOscuro,
                  width: 1.2,
                ),
              ),
            ),
            items: opciones.map(
              (opcion) {
                return DropdownMenuItem<String>(
                  value: opcion,
                  child: Text(
                    opcion,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// BOTÓN ACTUALIZAR
// ============================================================================

class _BotonSecundarioCatalogo extends StatelessWidget {
  final String texto;
  final IconData icono;
  final VoidCallback onTap;

  // Permite reducirlo únicamente cuando
  // el formulario derecho está abierto.
  final double ancho;

  const _BotonSecundarioCatalogo({
    required this.texto,
    required this.icono,
    required this.onTap,
    this.ancho = 138,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ancho,
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
          backgroundColor: const Color(
            0xFF417A00,
          ),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
          ),
          shadowColor: const Color(
            0xFF417A00,
          ).withValues(
            alpha: 0.25,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              6,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// BOTÓN NUEVO PRODUCTO
// ============================================================================

class _BotonPrincipalCatalogo extends StatelessWidget {
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
          backgroundColor: _azul,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
          ),
          shadowColor: _azul.withValues(
            alpha: 0.25,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              6,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// TABLA PRODUCTOS
// ============================================================================

class _TablaProductos extends StatelessWidget {
  final List<ProductoCatalogoApi> productos;
  final bool procesando;
  final bool soloLectura;

  final ValueChanged<ProductoCatalogoApi> onDetalle;
  final ValueChanged<ProductoCatalogoApi> onEditar;
  final ValueChanged<ProductoCatalogoApi> onCambiarEstado;

  const _TablaProductos({
    required this.productos,
    required this.procesando,
    required this.soloLectura,
    required this.onDetalle,
    required this.onEditar,
    required this.onCambiarEstado,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < productos.length; index++) ...[
          if (index > 0)
            const SizedBox(
              height: 10,
            ),
          _FilaProductoCatalogo(
            producto: productos[index],
            procesando: procesando,
            soloLectura: soloLectura,
            onDetalle: onDetalle,
            onEditar: onEditar,
            onCambiarEstado: onCambiarEstado,
          ),
        ],
      ],
    );
  }
}

// ============================================================================
// PAGINADOR
// ============================================================================

class _PaginadorCatalogoProducto extends StatelessWidget {
  final int pagina;
  final int totalPaginas;
  final int total;
  final int limite;
  final bool hayAnterior;
  final bool haySiguiente;

  final VoidCallback onAnterior;
  final VoidCallback onSiguiente;

  const _PaginadorCatalogoProducto({
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

// ============================================================================
// FILA PRODUCTO
// ============================================================================

class _FilaProductoCatalogo extends StatelessWidget {
  final ProductoCatalogoApi producto;
  final bool procesando;
  final bool soloLectura;

  final ValueChanged<ProductoCatalogoApi> onDetalle;
  final ValueChanged<ProductoCatalogoApi> onEditar;
  final ValueChanged<ProductoCatalogoApi> onCambiarEstado;

  const _FilaProductoCatalogo({
    required this.producto,
    required this.procesando,
    required this.soloLectura,
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
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.05,
            ),
            blurRadius: 10,
            offset: const Offset(
              0,
              4,
            ),
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
              borderRadius: BorderRadius.circular(
                8,
              ),
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
            child: _MetricaProductoCatalogo(
              titulo: 'Código',
              child: Text(
                producto.codigoBarras ?? 'S/C',
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
            child: _MetricaProductoCatalogo(
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
            flex: 14,
            child: _MetricaProductoCatalogo(
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
            child: _MetricaProductoCatalogo(
              titulo: 'Categoría',
              child: Text(
                producto.categoria ?? 'Sin categoría',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _textoPrincipal,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 12,
            child: _MetricaProductoCatalogo(
              titulo: 'Estado',
              child: _BadgeEstado(
                activo: producto.activo,
              ),
            ),
          ),
          Expanded(
            flex: 17,
            child: _MetricaProductoCatalogo(
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
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 30,
                    ),
                    tooltip: 'Ver detalle',
                    icon: const Icon(
                      Icons.visibility_outlined,
                    ),
                    color: _azul,
                    iconSize: 18,
                  ),
                  if (!soloLectura) ...[
                    const SizedBox(
                      width: 4,
                    ),
                    IconButton(
                      onPressed: procesando
                          ? null
                          : () {
                              onEditar(
                                producto,
                              );
                            },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
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
                    const SizedBox(
                      width: 4,
                    ),
                    IconButton(
                      onPressed: procesando
                          ? null
                          : () {
                              onCambiarEstado(
                                producto,
                              );
                            },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 30,
                      ),
                      tooltip: producto.activo ? 'Desactivar' : 'Activar',
                      icon: Icon(
                        producto.activo
                            ? Icons.toggle_on_outlined
                            : Icons.toggle_off_outlined,
                      ),
                      color: producto.activo ? _verdeOscuro : _rojo,
                      iconSize: 22,
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

// ============================================================================
// MÉTRICA PRODUCTO
// ============================================================================

class _MetricaProductoCatalogo extends StatelessWidget {
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

// ============================================================================
// BADGE TIPO
// ============================================================================

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
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: const Color(
            0xFFEDEDEA,
          ),
          borderRadius: BorderRadius.circular(
            4,
          ),
        ),
        child: Text(
          texto,
          style: const TextStyle(
            color: Color(
              0xFF5E675F,
            ),
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// BADGE ESTADO
// ============================================================================

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
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: activo
              ? const Color(
                  0xFFEAF8DD,
                )
              : const Color(
                  0xFFFFE8E8,
                ),
          borderRadius: BorderRadius.circular(
            4,
          ),
        ),
        child: Text(
          activo ? 'Activo' : 'Inactivo',
          style: TextStyle(
            color: activo ? _verdeOscuro : _rojo,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ESTADO PRODUCTOS
// ============================================================================

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
        padding: const EdgeInsets.symmetric(
          vertical: 42,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textoPrincipal,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (onReintentar != null) ...[
              const SizedBox(
                height: 12,
              ),
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

// ============================================================================
// DIÁLOGO CREAR / EDITAR PRODUCTO
// ============================================================================

class _DialogoProducto extends StatefulWidget {
  final ProductoCatalogoApi? producto;

  const _DialogoProducto({
    this.producto,
  });

  @override
  State<_DialogoProducto> createState() => _DialogoProductoState();
}

class _DialogoProductoState extends State<_DialogoProducto> {
  static const List<String> _tipos = [
    'PRODUCTO',
    'MEDICAMENTO',
  ];

  static const List<String> _edades = [
    'GENERAL',
    'PEDIATRICO',
    'INFANTIL',
    'ADULTO',
  ];

  static const List<String> _presentaciones = [
    'Tableta',
    'Capsula',
    'Pastilla',
    'Jarabe',
    'Suspension',
    'Gotas',
    'Inyectable',
    'Crema',
    'Pomada',
    'Spray',
    'Solucion',
    'Otro',
  ];

  static const List<String> _unidadesDosis = [
    'mg',
    'g',
    'mcg',
    'ml',
    'l',
    'UI',
    '%',
    'gotas',
    'tabletas',
    'capsulas',
  ];

  late final TextEditingController _codigoController;
  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _sustanciaController;
  late final TextEditingController _dosisCantidadController;

  late String _tipo;
  late String _categoria;
  late String _presentacion;
  String? _via;
  late String _edad;
  late String _dosisUnidad;
  late DosisMedicamento _dosisOriginal;

  late bool _manejaCaducidad;
  late bool _requiereReceta;

  String? _error;

  @override
  void initState() {
    super.initState();

    final producto = widget.producto;

    _codigoController = TextEditingController(
      text: producto?.codigoBarras ?? '',
    );

    _nombreController = TextEditingController(
      text: producto?.nombre ?? '',
    );

    _descripcionController = TextEditingController(
      text: producto?.descripcion ?? '',
    );

    _sustanciaController = TextEditingController(
      text: producto?.sustanciaActiva ?? '',
    );

    final dosis = DosisMedicamento.desdeTexto(
      producto?.dosis,
    );
    _dosisOriginal = dosis;

    _dosisCantidadController = TextEditingController(
      text: dosis.cantidad,
    );

    _tipo = _tipos.contains(
      producto?.tipo,
    )
        ? producto!.tipo
        : 'PRODUCTO';

    _categoria = producto == null ? 'General' : (producto.categoria ?? '');

    _presentacion = _presentacionVisible(
      producto?.presentacion,
    );

    _via = viasAdministracion.containsKey(
      producto?.viaAdministracion,
    )
        ? producto!.viaAdministracion!
        : null;

    _edad = producto == null ? 'GENERAL' : (producto.edad ?? '');

    _dosisUnidad = dosis.unidad;

    _manejaCaducidad = producto?.manejaCaducidad ?? false;
    _requiereReceta = producto?.requiereReceta ?? false;
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _sustanciaController.dispose();
    _dosisCantidadController.dispose();

    super.dispose();
  }

  void _confirmar() {
    final nombre = _nombreController.text.trim();

    if (nombre.isEmpty) {
      setState(() {
        _error = 'Ingresa el nombre del producto';
      });

      return;
    }

    Map<String, dynamic>? infoMedicamento;

    if (_tipo == 'MEDICAMENTO') {
      infoMedicamento = {
        'presentacion': _presentacionNormalizada(
          _presentacion,
        ),
        'viaAdministracion': _via,
        'edad': _limpiar(_edad),
        'requiereReceta': _requiereReceta,
        'sustanciaActiva': _limpiar(
          _sustanciaController.text,
        ),
        'dosis': _dosisTexto(),
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
        categoria: _tipo == 'PRODUCTO' ? _limpiar(_categoria) : null,
        manejaCaducidad: _manejaCaducidad,
        infoMedicamento: infoMedicamento,
      ),
    );
  }

  String? _dosisTexto() {
    return _dosisOriginal.guardar(
      _dosisCantidadController.text,
      _dosisUnidad,
    );
  }

  String _presentacionNormalizada(
    String value,
  ) {
    return normalizarPresentacion(value);
  }

  @override
  Widget build(BuildContext context) {
    final esMedicamento = _tipo == 'MEDICAMENTO';
    final esEdicion = widget.producto != null;

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.18,
                ),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _EncabezadoFormularioProducto(
                titulo: esEdicion ? 'Editar producto' : 'Nuevo producto',
                subtitulo: esEdicion
                    ? 'Modificación de ficha técnica y parámetros de venta'
                    : 'Registro de ficha técnica y parámetros de venta',
                esMedicamento: esMedicamento,
                onCerrar: () {
                  Navigator.of(context).pop();
                },
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    18,
                    18,
                    18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _CampoTextoEdicionProducto(
                              etiqueta: 'Código de barras',
                              controller: _codigoController,
                              prefixIcon: Icons.qr_code_2_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: _CampoDropdownEdicionProducto(
                              etiqueta: 'Tipo',
                              valor: _tipo,
                              opciones: _tipos,
                              textoOpcion: _etiqueta,
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }

                                setState(() {
                                  _tipo = value;

                                  _error = null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _CampoTextoEdicionProducto(
                        etiqueta: 'Nombre del producto',
                        controller: _nombreController,
                      ),
                      const SizedBox(height: 14),
                      if (!esMedicamento) ...[
                        _CampoDropdownEdicionProducto(
                          etiqueta: 'Categoría',
                          valor: _categoria,
                          opciones: ['', ..._opcionesCategoria(_categoria)],
                          textoOpcion: (value) =>
                              value.isEmpty ? 'Sin asignar' : value,
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }

                            setState(() {
                              _categoria = value;
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                      ],
                      _CampoTextoEdicionProducto(
                        etiqueta: 'Descripción',
                        controller: _descripcionController,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      _CheckTarjetaEdicionProducto(
                        titulo: 'Maneja caducidad',
                        subtitulo:
                            'Habilita registro de número de lote y fecha de expiración',
                        value: _manejaCaducidad,
                        onChanged: (value) {
                          setState(() {
                            _manejaCaducidad = value;
                          });
                        },
                      ),
                      if (esMedicamento) ...[
                        const SizedBox(height: 16),
                        _CampoDropdownEdicionProducto(
                          etiqueta: 'Presentación',
                          valor: _presentacion,
                          opciones: [
                            ..._presentaciones,
                            if (!_presentaciones.contains(_presentacion))
                              _presentacion,
                          ],
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }

                            setState(() {
                              _presentacion = value;
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _CampoDropdownEdicionProducto(
                                etiqueta: 'Vía de administración',
                                valor: _via,
                                opciones: viasAdministracion.keys.toList(),
                                hintText: 'Seleccionar',
                                textoOpcion: etiquetaViaAdministracion,
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: _CampoDropdownEdicionProducto(
                                etiqueta: 'Edad',
                                valor: _edad,
                                opciones: [
                                  '',
                                  ..._edades,
                                  if (_edad.isNotEmpty &&
                                      !_edades.contains(_edad))
                                    _edad,
                                ],
                                textoOpcion: (value) => value.isEmpty
                                    ? 'Sin asignar'
                                    : _etiqueta(value),
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
                        const SizedBox(height: 14),
                        _CampoTextoEdicionProducto(
                          etiqueta: 'Sustancia activa',
                          controller: _sustanciaController,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _CampoTextoEdicionProducto(
                                etiqueta:
                                    _dosisUnidad == DosisMedicamento.sinUnidad
                                        ? 'Dosis'
                                        : 'Cantidad',
                                controller: _dosisCantidadController,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _CampoDropdownEdicionProducto(
                                etiqueta: 'Unidad',
                                valor: _dosisUnidad,
                                opciones: {
                                  ..._unidadesDosis,
                                  _dosisOriginal.unidad,
                                }.toList(),
                                onChanged: (value) {
                                  if (value == null) {
                                    return;
                                  }

                                  setState(() {
                                    _dosisUnidad = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _CheckLineaEdicionProducto(
                          texto: 'Requiere receta',
                          value: _requiereReceta,
                          onChanged: (value) {
                            setState(() {
                              _requiereReceta = value;
                            });
                          },
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        _MensajeErrorProducto(
                          mensaje: _error!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              _AccionesFormularioProducto(
                onGuardar: _confirmar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EncabezadoFormularioProducto extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final bool esMedicamento;
  final VoidCallback onCerrar;

  const _EncabezadoFormularioProducto({
    required this.titulo,
    required this.subtitulo,
    required this.esMedicamento,
    required this.onCerrar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        15,
        12,
        15,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFBFAF9),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE9EEF3),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8DD),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFD6EFC4),
              ),
            ),
            child: Icon(
              esMedicamento
                  ? Icons.medication_outlined
                  : Icons.inventory_2_outlined,
              color: _verdeOscuro,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textoPrincipal,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textoSecundario,
                    fontSize: 10,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCerrar,
            icon: const Icon(
              Icons.close,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }
}

class _CampoTextoEdicionProducto extends StatelessWidget {
  final String etiqueta;
  final TextEditingController controller;
  final IconData? prefixIcon;
  final int maxLines;

  const _CampoTextoEdicionProducto({
    required this.etiqueta,
    required this.controller,
    this.prefixIcon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return _ContenedorCampoEdicionProducto(
      etiqueta: etiqueta,
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        cursorColor: _verdeOscuro,
        style: const TextStyle(
          color: _textoPrincipal,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        decoration: _decoracionCampoEdicionProducto(
          prefixIcon: prefixIcon,
        ),
      ),
    );
  }
}

class _CampoDropdownEdicionProducto extends StatelessWidget {
  final String etiqueta;
  final String? valor;
  final String? hintText;
  final List<String> opciones;
  final String Function(String)? textoOpcion;
  final ValueChanged<String?> onChanged;

  const _CampoDropdownEdicionProducto({
    required this.etiqueta,
    required this.valor,
    required this.opciones,
    required this.onChanged,
    this.hintText,
    this.textoOpcion,
  });

  @override
  Widget build(BuildContext context) {
    return _ContenedorCampoEdicionProducto(
      etiqueta: etiqueta,
      child: DropdownButtonFormField<String>(
        initialValue: opciones.contains(valor) ? valor : null,
        isExpanded: true,
        hint: hintText == null
            ? null
            : Text(
                hintText!,
                style: const TextStyle(
                  color: _textoSecundario,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
        icon: const Icon(
          Icons.keyboard_arrow_down,
          color: _textoSecundario,
          size: 18,
        ),
        style: const TextStyle(
          color: _textoPrincipal,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        decoration: _decoracionCampoEdicionProducto(),
        items: opciones.map(
          (opcion) {
            final texto = textoOpcion == null
                ? opcion
                : textoOpcion!(
                    opcion,
                  );

            return DropdownMenuItem<String>(
              value: opcion,
              child: Text(
                texto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
        ).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _CheckTarjetaEdicionProducto extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CheckTarjetaEdicionProducto({
    required this.titulo,
    required this.subtitulo,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onChanged(
          !value,
        );
      },
      borderRadius: BorderRadius.circular(9),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          10,
          10,
          12,
          10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: const Color(0xFFD8E0E8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.025,
              ),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: value,
                activeColor: const Color(0xFF58D000),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                onChanged: (checked) {
                  onChanged(
                    checked ?? false,
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: _textoPrincipal,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      color: _textoSecundario,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckLineaEdicionProducto extends StatelessWidget {
  final String texto;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CheckLineaEdicionProducto({
    required this.texto,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onChanged(
          !value,
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: value,
              activeColor: const Color(0xFF58D000),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              onChanged: (checked) {
                onChanged(
                  checked ?? false,
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Text(
            texto,
            style: const TextStyle(
              color: _textoPrincipal,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContenedorCampoEdicionProducto extends StatelessWidget {
  final String etiqueta;
  final Widget child;

  const _ContenedorCampoEdicionProducto({
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _textoSecundario,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _MensajeErrorProducto extends StatelessWidget {
  final String mensaje;

  const _MensajeErrorProducto({
    required this.mensaje,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEAEA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFFC9C9),
        ),
      ),
      child: Row(
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
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccionesFormularioProducto extends StatelessWidget {
  final VoidCallback onGuardar;

  const _AccionesFormularioProducto({
    required this.onGuardar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      padding: const EdgeInsets.fromLTRB(
        18,
        11,
        18,
        12,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFBFAF9),
        border: Border(
          top: BorderSide(
            color: Color(0xFFE9EEF3),
          ),
        ),
      ),
      child: Row(
        children: [
          const Spacer(),
          SizedBox(
            width: 112,
            height: 40,
            child: ElevatedButton.icon(
              onPressed: onGuardar,
              icon: const Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              ),
              label: const Text(
                'Guardar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3A7704),
                foregroundColor: Colors.white,
                elevation: 6,
                shadowColor: const Color(0xFF3A7704).withValues(
                  alpha: 0.28,
                ),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _decoracionCampoEdicionProducto({
  IconData? prefixIcon,
}) {
  return InputDecoration(
    filled: true,
    fillColor: Colors.white,
    prefixIcon: prefixIcon == null
        ? null
        : Icon(
            prefixIcon,
            color: _textoSecundario,
            size: 16,
          ),
    prefixIconConstraints: const BoxConstraints(
      minWidth: 34,
      minHeight: 0,
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 10,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(
        color: Color(0xFFD8E0E8),
        width: 1,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(
        color: Color(0xFFD8E0E8),
        width: 1,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(
        color: _verdeOscuro,
        width: 1.2,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(
        color: _rojo,
        width: 1,
      ),
    ),
  );
}

// ============================================================================
// DETALLE PRODUCTO
// ============================================================================

class _DialogoDetalleProducto extends StatelessWidget {
  final ProductoCatalogoApi producto;

  const _DialogoDetalleProducto({
    required this.producto,
  });

  @override
  Widget build(BuildContext context) {
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
              child: _ResumenProductoCatalogoDetalle(
                producto: producto,
              ),
            ),
            Container(
              width: 1,
              color: const Color(0xFFE7E8E3),
            ),
            Expanded(
              child: _PanelDetallesProductoCatalogo(
                producto: producto,
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

class _ResumenProductoCatalogoDetalle extends StatelessWidget {
  final ProductoCatalogoApi producto;

  const _ResumenProductoCatalogoDetalle({
    required this.producto,
  });

  @override
  Widget build(BuildContext context) {
    final categoria = producto.categoria?.trim().isEmpty ?? true
        ? 'Sin categoría'
        : producto.categoria!.trim();

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
            decoration: BoxDecoration(
              color: producto.activo
                  ? producto.esMedicamento
                      ? const Color(0xFFE8F1FF)
                      : const Color(0xFFEEF8E4)
                  : const Color(0xFFFFE8E8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              producto.esMedicamento
                  ? Icons.medication_outlined
                  : Icons.inventory_2_outlined,
              color: producto.activo
                  ? producto.esMedicamento
                      ? _azul
                      : _verdeOscuro
                  : _rojo,
              size: 44,
            ),
          ),
          const SizedBox(height: 16),
          _BadgeActivoDetalleProducto(
            activo: producto.activo,
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
            'Categoría: $categoria',
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
          _DatoResumenProductoCatalogo(
            label: 'Tipo',
            child: Text(
              _etiqueta(producto.tipo),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _textoPrincipal,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _DatoResumenProductoCatalogo(
            label: 'Estado',
            child: Text(
              producto.activo ? 'Activo' : 'Inactivo',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: producto.activo ? _verdeOscuro : _rojo,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeActivoDetalleProducto extends StatelessWidget {
  final bool activo;

  const _BadgeActivoDetalleProducto({
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

class _DatoResumenProductoCatalogo extends StatelessWidget {
  final String label;
  final Widget child;

  const _DatoResumenProductoCatalogo({
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

class _PanelDetallesProductoCatalogo extends StatelessWidget {
  final ProductoCatalogoApi producto;
  final VoidCallback onCerrar;

  const _PanelDetallesProductoCatalogo({
    required this.producto,
    required this.onCerrar,
  });

  @override
  Widget build(BuildContext context) {
    final categoria = producto.categoria?.trim().isEmpty ?? true
        ? 'Sin categoría'
        : producto.categoria!.trim();

    final codigo = producto.codigoBarras?.trim().isEmpty ?? true
        ? 'Sin código'
        : producto.codigoBarras!.trim();

    final descripcion = producto.descripcion?.trim().isEmpty ?? true
        ? 'Sin descripción'
        : producto.descripcion!.trim();

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
                      _TarjetaDetalleProductoCatalogo(
                        width: anchoTarjeta,
                        label: 'ID Producto',
                        value: '${producto.idProducto}',
                      ),
                      _TarjetaDetalleProductoCatalogo(
                        width: anchoTarjeta,
                        label: 'Código',
                        value: codigo,
                        valueItalic: codigo == 'Sin código',
                        valueColor: codigo == 'Sin código'
                            ? _textoSecundario
                            : _textoPrincipal,
                      ),
                      _TarjetaDetalleProductoCatalogo(
                        width: anchoTarjeta,
                        label: 'Categoría',
                        value: categoria,
                        valueItalic: categoria == 'Sin categoría',
                        valueColor: categoria == 'Sin categoría'
                            ? _textoSecundario
                            : _textoPrincipal,
                      ),
                      _TarjetaDetalleProductoCatalogo(
                        width: anchoTarjeta,
                        label: 'Maneja caducidad',
                        value: producto.manejaCaducidad ? 'Sí' : 'No',
                      ),
                      _TarjetaDetalleProductoCatalogo(
                        width: anchoTarjeta,
                        label: 'Descripción',
                        value: descripcion,
                        valueItalic: descripcion == 'Sin descripción',
                        valueColor: descripcion == 'Sin descripción'
                            ? _textoSecundario
                            : _textoPrincipal,
                      ),
                      if (producto.esMedicamento) ...[
                        _TarjetaDetalleProductoCatalogo(
                          width: anchoTarjeta,
                          label: 'Presentación',
                          value: producto.presentacion?.trim().isEmpty ?? true
                              ? 'Sin presentación'
                              : _presentacionVisible(producto.presentacion),
                          valueItalic:
                              producto.presentacion?.trim().isEmpty ?? true,
                          valueColor:
                              producto.presentacion?.trim().isEmpty ?? true
                                  ? _textoSecundario
                                  : _textoPrincipal,
                        ),
                        _TarjetaDetalleProductoCatalogo(
                          width: anchoTarjeta,
                          label: 'Vía',
                          value:
                              producto.viaAdministracion?.trim().isEmpty ?? true
                                  ? 'Sin vía'
                                  : etiquetaViaAdministracion(
                                      producto.viaAdministracion,
                                    ),
                          valueItalic:
                              producto.viaAdministracion?.trim().isEmpty ??
                                  true,
                          valueColor:
                              producto.viaAdministracion?.trim().isEmpty ?? true
                                  ? _textoSecundario
                                  : _textoPrincipal,
                        ),
                        _TarjetaDetalleProductoCatalogo(
                          width: anchoTarjeta,
                          label: 'Edad',
                          value: producto.edad == null
                              ? 'Sin edad'
                              : _etiqueta(producto.edad!),
                          valueItalic: producto.edad == null,
                          valueColor: producto.edad == null
                              ? _textoSecundario
                              : _textoPrincipal,
                        ),
                        _TarjetaDetalleProductoCatalogo(
                          width: anchoTarjeta,
                          label: 'Sustancia activa',
                          value:
                              producto.sustanciaActiva?.trim().isEmpty ?? true
                                  ? 'Sin sustancia'
                                  : producto.sustanciaActiva!,
                          valueItalic:
                              producto.sustanciaActiva?.trim().isEmpty ?? true,
                          valueColor:
                              producto.sustanciaActiva?.trim().isEmpty ?? true
                                  ? _textoSecundario
                                  : _textoPrincipal,
                        ),
                        _TarjetaDetalleProductoCatalogo(
                          width: anchoTarjeta,
                          label: 'Dosis',
                          value: producto.dosis?.trim().isEmpty ?? true
                              ? 'Sin dosis'
                              : producto.dosis!,
                          valueItalic: producto.dosis?.trim().isEmpty ?? true,
                          valueColor: producto.dosis?.trim().isEmpty ?? true
                              ? _textoSecundario
                              : _textoPrincipal,
                        ),
                        _TarjetaDetalleProductoCatalogo(
                          width: anchoTarjeta,
                          label: 'Requiere receta',
                          value: producto.requiereReceta ? 'Sí' : 'No',
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            width: double.infinity,
            height: 1,
            color: const Color(0xFFE7E8E3),
          ),
        ],
      ),
    );
  }
}

class _TarjetaDetalleProductoCatalogo extends StatelessWidget {
  final double width;
  final String label;
  final String value;
  final Widget? trailing;
  final bool valueItalic;
  final Color? valueColor;

  const _TarjetaDetalleProductoCatalogo({
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
          color: const Color(0xFFE8E9E5),
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

// ============================================================================
// FUNCIONES AUXILIARES
// ============================================================================

String? _limpiar(
  String value,
) {
  final text = value.trim();

  return text.isEmpty ? null : text;
}

List<String> _opcionesCategoria([
  String? actual,
]) {
  final opciones = [
    ..._categoriasProducto,
  ];

  final categoriaActual = actual?.trim();

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

String _presentacionVisible(
  String? value,
) {
  return presentacionVisible(value);
}

String _etiqueta(
  String value,
) {
  if (value.isEmpty) {
    return value;
  }

  return value
      .toLowerCase()
      .split(
        '_',
      )
      .where(
        (part) => part.isNotEmpty,
      )
      .map(
        (part) => '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(
        ' ',
      );
}
