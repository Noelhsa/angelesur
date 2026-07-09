import 'package:flutter/material.dart';
import 'menu_carta_catalogo_producto.dart';

const Color _fondoPagina = Color(0xFFF8F6F5);
const Color _verdeOscuro = Color(0xFF397800);
const Color _textoPrincipal = Color(0xFF1F2933);
const Color _textoSecundario = Color(0xFF667085);
const Color _bordeSuave = Color(0xFFD9E6D3);
const Color _grisCabecera = Color(0xFFE7E3E3);
const Color _grisCampo = Color(0xFFF8F7F4);

class ContenidoCatalogoProducto extends StatefulWidget {
  const ContenidoCatalogoProducto({super.key});

  @override
  State<ContenidoCatalogoProducto> createState() =>
      _ContenidoCatalogoProductoState();
}

class _ContenidoCatalogoProductoState extends State<ContenidoCatalogoProducto> {
  String _categoriaSeleccionada = 'Todas las Categorías';
  String _estadoSeleccionado = 'Todos los estados';
  bool _mostrarMenuNuevoProducto = false;

  final List<_ProductoCatalogo> _productos = const [
    _ProductoCatalogo(
      codigo: 'PHAR-00124',
      nombre: 'Amoxicilina 500mg (Cápsulas)',
      categoria: 'Antibióticos',
      accionPrincipal: _AccionProducto.editar,
    ),
    _ProductoCatalogo(
      codigo: 'PHAR-00382',
      nombre: 'Ibuprofeno 400mg Forte',
      categoria: 'Analgésicos',
      accionPrincipal: _AccionProducto.comprar,
    ),
    _ProductoCatalogo(
      codigo: 'PHAR-00912',
      nombre: 'Insulina Humalog Mix 25',
      categoria: 'Diabetes',
      accionPrincipal: _AccionProducto.lista,
    ),
    _ProductoCatalogo(
      codigo: 'PHAR-01255',
      nombre: 'Paracetamol 1g Gotas Infantiles',
      categoria: 'Analgésicos',
      accionPrincipal: _AccionProducto.editar,
    ),
    _ProductoCatalogo(
      codigo: 'PHAR-00045',
      nombre: 'Vitamina C 1000mg Efervescente',
      categoria: 'Suplementos',
      accionPrincipal: _AccionProducto.editar,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _fondoPagina,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(10, 20, 10, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PanelFiltrosProducto(
                    categoriaSeleccionada: _categoriaSeleccionada,
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
                    onFiltrosAvanzados: () {},
                    onExportarCsv: () {},
                    onNuevoProducto: () {
                      setState(() {
                        _mostrarMenuNuevoProducto = true;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final anchoTabla =
                          constraints.maxWidth < 760 ? 760.0 : constraints.maxWidth;

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: anchoTabla,
                          child: _TablaProductos(
                            productos: _productos,
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
              onGuardarMedicamento: () {
                setState(() {
                  _mostrarMenuNuevoProducto = false;
                });
              },
            ),
        ],
      ),
    );
  }
}

class _PanelFiltrosProducto extends StatelessWidget {
  final String categoriaSeleccionada;
  final String estadoSeleccionado;
  final ValueChanged<String?> onCategoriaChanged;
  final ValueChanged<String?> onEstadoChanged;
  final VoidCallback onFiltrosAvanzados;
  final VoidCallback onExportarCsv;
  final VoidCallback onNuevoProducto;

  const _PanelFiltrosProducto({
    required this.categoriaSeleccionada,
    required this.estadoSeleccionado,
    required this.onCategoriaChanged,
    required this.onEstadoChanged,
    required this.onFiltrosAvanzados,
    required this.onExportarCsv,
    required this.onNuevoProducto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        color: _fondoPagina,
        border: Border.all(color: _bordeSuave),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 165,
            child: _CampoDropdown(
              etiqueta: 'Categoría',
              valor: categoriaSeleccionada,
              opciones: const [
                'Todas las Categorías',
                'Antibióticos',
                'Analgésicos',
                'Diabetes',
                'Suplementos',
              ],
              onChanged: onCategoriaChanged,
            ),
          ),
          const SizedBox(width: 22),
          SizedBox(
            width: 165,
            child: _CampoDropdown(
              etiqueta: 'Estado de Stock',
              valor: estadoSeleccionado,
              opciones: const [
                'Todos los estados',
                'Activo',
                'Inactivo',
                'Suspendido',
              ],
              onChanged: onEstadoChanged,
            ),
          ),
          const Spacer(),
          _BotonSecundarioCatalogo(
            texto: 'Filtros Avanzados',
            icono: Icons.filter_list,
            onTap: onFiltrosAvanzados,
          ),
          const SizedBox(width: 10),
          _BotonSecundarioCatalogo(
            texto: 'Exportar CSV',
            icono: Icons.download,
            onTap: onExportarCsv,
          ),
          const SizedBox(width: 10),
          _BotonPrincipalCatalogo(
            texto: 'Nuevo Producto',
            icono: Icons.add,
            onTap: onNuevoProducto,
          ),
        ],
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
            value: valor,
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

class _BotonPrincipalCatalogo extends StatelessWidget {
  final String texto;
  final IconData icono;
  final VoidCallback onTap;

  const _BotonPrincipalCatalogo({
    required this.texto,
    required this.icono,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(
          icono,
          size: 15,
          color: Colors.white,
        ),
        label: Text(
          texto,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _verdeOscuro,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
    );
  }
}

class _TablaProductos extends StatelessWidget {
  final List<_ProductoCatalogo> productos;

  const _TablaProductos({
    required this.productos,
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
          const _HeaderTablaProductos(),
          for (final producto in productos)
            _FilaProductoCatalogo(producto: producto),
        ],
      ),
    );
  }
}

class _HeaderTablaProductos extends StatelessWidget {
  const _HeaderTablaProductos();

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
          Expanded(flex: 10, child: _TextoHeaderTabla('CÓDIGO')),
          Expanded(flex: 34, child: _TextoHeaderTabla('NOMBRE DEL PRODUCTO')),
          Expanded(flex: 12, child: _TextoHeaderTabla('CATEGORÍA')),
          Expanded(flex: 10, child: _TextoHeaderTabla('ACCIONES')),
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

class _FilaProductoCatalogo extends StatelessWidget {
  final _ProductoCatalogo producto;

  const _FilaProductoCatalogo({
    required this.producto,
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
            flex: 10,
            child: Text(
              producto.codigo.replaceFirst('-', '-\n'),
              style: const TextStyle(
                color: _textoPrincipal,
                fontSize: 11,
                height: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 34,
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
            flex: 12,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _BadgeCategoria(texto: producto.categoria),
            ),
          ),
          Expanded(
            flex: 10,
            child: _AccionesProducto(producto: producto),
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
        texto,
        style: const TextStyle(
          color: Color(0xFF7C817B),
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AccionesProducto extends StatelessWidget {
  final _ProductoCatalogo producto;

  const _AccionesProducto({
    required this.producto,
  });

  @override
  Widget build(BuildContext context) {
    IconData iconoPrincipal;

    switch (producto.accionPrincipal) {
      case _AccionProducto.editar:
        iconoPrincipal = Icons.edit_outlined;
        break;
      case _AccionProducto.comprar:
        iconoPrincipal = Icons.add_shopping_cart;
        break;
      case _AccionProducto.lista:
        iconoPrincipal = Icons.list;
        break;
    }

    return Row(
      children: [
        IconButton(
          onPressed: () {},
          icon: Icon(
            iconoPrincipal,
            size: 17,
            color: _verdeOscuro,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 26,
            minHeight: 26,
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.more_vert,
            size: 17,
            color: Color(0xFF006778),
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 26,
            minHeight: 26,
          ),
        ),
      ],
    );
  }
}

class _ProductoCatalogo {
  final String codigo;
  final String nombre;
  final String categoria;
  final _AccionProducto accionPrincipal;

  const _ProductoCatalogo({
    required this.codigo,
    required this.nombre,
    required this.categoria,
    required this.accionPrincipal,
  });
}

enum _AccionProducto {
  editar,
  comprar,
  lista,
}