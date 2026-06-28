import 'package:flutter/material.dart';

const Color _fondoPagina = Color(0xFFF8F6F5);
const Color _verdeOscuro = Color(0xFF397800);
const Color _verdeTexto = Color(0xFF4F7D35);
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
  String _categoriaSeleccionada = 'Todas las Categorías';
  String _estadoSeleccionado = 'Todos los estados';

  final List<_ProductoInventario> _productos = const [
    _ProductoInventario(
      codigo: 'PHAR-00124',
      nombre: 'Amoxicilina 500mg (Cápsulas)',
      categoria: 'Antibióticos',
      stockActual: 450,
      unidad: 'Caja (30)',
      estado: _EstadoInventario.enExistencia,
      accionPrincipal: _AccionProducto.editar,
    ),
    _ProductoInventario(
      codigo: 'PHAR-00382',
      nombre: 'Ibuprofeno 400mg Forte',
      categoria: 'Analgésicos',
      stockActual: 12,
      unidad: 'Caja (20)',
      estado: _EstadoInventario.stockBajo,
      accionPrincipal: _AccionProducto.comprar,
    ),
    _ProductoInventario(
      codigo: 'PHAR-00912',
      nombre: 'Insulina Humalog Mix 25',
      categoria: 'Diabetes',
      stockActual: 0,
      unidad: 'Vial (10ml)',
      estado: _EstadoInventario.agotado,
      accionPrincipal: _AccionProducto.lista,
    ),
    _ProductoInventario(
      codigo: 'PHAR-01255',
      nombre: 'Paracetamol 1g Gotas Infantiles',
      categoria: 'Analgésicos',
      stockActual: 85,
      unidad: 'Frasco (30ml)',
      estado: _EstadoInventario.enExistencia,
      accionPrincipal: _AccionProducto.editar,
    ),
    _ProductoInventario(
      codigo: 'PHAR-00045',
      nombre: 'Vitamina C 1000mg Efervescente',
      categoria: 'Suplementos',
      stockActual: 210,
      unidad: 'Tubo (10 tab)',
      estado: _EstadoInventario.enExistencia,
      accionPrincipal: _AccionProducto.editar,
    ),
  ];

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
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final anchoTabla =
                    constraints.maxWidth < 920 ? 920.0 : constraints.maxWidth;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: anchoTabla,
                    child: _TablaInventario(productos: _productos),
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
  final String categoriaSeleccionada;
  final String estadoSeleccionado;
  final ValueChanged<String?> onCategoriaChanged;
  final ValueChanged<String?> onEstadoChanged;
  final VoidCallback onFiltrosAvanzados;
  final VoidCallback onExportarCsv;

  const _PanelFiltrosInventario({
    required this.categoriaSeleccionada,
    required this.estadoSeleccionado,
    required this.onCategoriaChanged,
    required this.onEstadoChanged,
    required this.onFiltrosAvanzados,
    required this.onExportarCsv,
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
                'En Existencia',
                'Stock Bajo',
                'Agotado',
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

class _TablaInventario extends StatelessWidget {
  final List<_ProductoInventario> productos;

  const _TablaInventario({
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
          const _HeaderTablaInventario(),
          for (final producto in productos)
            _FilaProductoInventario(producto: producto),
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
          Expanded(flex: 14, child: _TextoHeaderTabla('CÓDIGO')),
          Expanded(flex: 30, child: _TextoHeaderTabla('NOMBRE DEL PRODUCTO')),
          Expanded(flex: 16, child: _TextoHeaderTabla('CATEGORÍA')),
          Expanded(flex: 15, child: _TextoHeaderTabla('STOCK ACTUAL')),
          Expanded(flex: 15, child: _TextoHeaderTabla('UNIDAD')),
          Expanded(flex: 16, child: _TextoHeaderTabla('ESTADO')),
          Expanded(flex: 14, child: _TextoHeaderTabla('ACCIONES')),
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
  final _ProductoInventario producto;

  const _FilaProductoInventario({
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
            flex: 14,
            child: Text(
              producto.codigo,
              style: const TextStyle(
                color: _textoPrincipal,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 30,
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
            flex: 16,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _BadgeCategoria(texto: producto.categoria),
            ),
          ),
          Expanded(
            flex: 15,
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
              producto.unidad,
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
              child: _BadgeEstado(estado: producto.estado),
            ),
          ),
          Expanded(
            flex: 14,
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

class _BadgeEstado extends StatelessWidget {
  final _EstadoInventario estado;

  const _BadgeEstado({
    required this.estado,
  });

  @override
  Widget build(BuildContext context) {
    Color fondo;
    Color texto;
    String label;

    switch (estado) {
      case _EstadoInventario.enExistencia:
        fondo = const Color(0xFFE8F5DD);
        texto = _verdeOscuro;
        label = '● En Existencia';
        break;
      case _EstadoInventario.stockBajo:
        fondo = const Color(0xFFE7F0FF);
        texto = _azul;
        label = '● Stock Bajo';
        break;
      case _EstadoInventario.agotado:
        fondo = const Color(0xFFFFE9E9);
        texto = _rojo;
        label = '● Agotado';
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

class _AccionesProducto extends StatelessWidget {
  final _ProductoInventario producto;

  const _AccionesProducto({
    required this.producto,
  });

  @override
  Widget build(BuildContext context) {
    IconData iconoPrincipal;
    Color colorPrincipal;

    switch (producto.accionPrincipal) {
      case _AccionProducto.editar:
        iconoPrincipal = Icons.edit_square;
        colorPrincipal = _verdeOscuro;
        break;
      case _AccionProducto.comprar:
        iconoPrincipal = Icons.add_shopping_cart;
        colorPrincipal = _verdeOscuro;
        break;
      case _AccionProducto.lista:
        iconoPrincipal = Icons.list;
        colorPrincipal = _verdeOscuro;
        break;
    }

    return Row(
      children: [
        IconButton(
          onPressed: () {},
          icon: Icon(
            iconoPrincipal,
            size: 17,
            color: colorPrincipal,
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

class _ProductoInventario {
  final String codigo;
  final String nombre;
  final String categoria;
  final int stockActual;
  final String unidad;
  final _EstadoInventario estado;
  final _AccionProducto accionPrincipal;

  const _ProductoInventario({
    required this.codigo,
    required this.nombre,
    required this.categoria,
    required this.stockActual,
    required this.unidad,
    required this.estado,
    required this.accionPrincipal,
  });
}

enum _EstadoInventario {
  enExistencia,
  stockBajo,
  agotado,
}

enum _AccionProducto {
  editar,
  comprar,
  lista,
}