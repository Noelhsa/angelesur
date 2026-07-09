import 'package:flutter/material.dart';
import 'menu_carta_pedidos.dart';

const Color _fondoPagina = Color(0xFFF8F6F5);
const Color _verdeOscuro = Color(0xFF397800);
const Color _verdeTexto = Color(0xFF4F7D35);
const Color _azul = Color(0xFF0B63CE);
const Color _textoPrincipal = Color(0xFF101828);
const Color _textoSecundario = Color(0xFF526171);
const Color _bordeSuave = Color(0xFFD9E6D3);
const Color _grisCabecera = Color(0xFFE7E3E3);
const Color _grisCampo = Color(0xFFF8F7F4);
const Color _rojo = Color(0xFFE02020);

class ContenidoPedidos extends StatefulWidget {
  const ContenidoPedidos({super.key});

  @override
  State<ContenidoPedidos> createState() => _ContenidoPedidosState();
}

class _ContenidoPedidosState extends State<ContenidoPedidos> {
  final TextEditingController _busquedaController = TextEditingController();

  bool _mostrarMenuNuevaOrden = false;
  String _filtroSeleccionado = 'Todos';

  final List<_Pedido> _pedidos = const [
    _Pedido(
      ordenId: 'ORD-7721',
      fecha: 'Oct 24, 2023 · 10:30 AM',
      cliente: 'Carlos Méndez',
      medicamento: 'Amoxicilina 500mg',
      cantidad: 3,
      total: 45.50,
      estado: _EstadoPedido.pending,
    ),
    _Pedido(
      ordenId: 'ORD-7719',
      fecha: 'Oct 24, 2023 · 09:15 AM',
      cliente: 'Lucía Fernandez',
      medicamento: 'Paracetamol 1g (Caja)',
      cantidad: 1,
      total: 12.20,
      estado: _EstadoPedido.shipped,
    ),
    _Pedido(
      ordenId: 'ORD-7715',
      fecha: 'Oct 23, 2023 · 05:45 PM',
      cliente: 'Marcos Ruiz',
      medicamento: 'Ibuprofeno 400mg',
      cantidad: 5,
      total: 68.90,
      estado: _EstadoPedido.delivered,
    ),
    _Pedido(
      ordenId: 'ORD-7710',
      fecha: 'Oct 23, 2023 · 02:20 PM',
      cliente: 'Elena Santos',
      medicamento: 'Insulina Glargina',
      cantidad: 2,
      total: 120.00,
      estado: _EstadoPedido.cancelled,
    ),
    _Pedido(
      ordenId: 'ORD-7708',
      fecha: 'Oct 23, 2023 · 11:05 AM',
      cliente: 'David Vaca',
      medicamento: 'Vitamina C + Zinc',
      cantidad: 4,
      total: 35.00,
      estado: _EstadoPedido.delivered,
    ),
  ];

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  List<_Pedido> get _pedidosFiltrados {
    final texto = _busquedaController.text.trim().toLowerCase();

    return _pedidos.where((pedido) {
      final coincideBusqueda = texto.isEmpty ||
          pedido.ordenId.toLowerCase().contains(texto) ||
          pedido.cliente.toLowerCase().contains(texto) ||
          pedido.medicamento.toLowerCase().contains(texto);

      final coincideFiltro = switch (_filtroSeleccionado) {
        'Pendientes' => pedido.estado == _EstadoPedido.pending,
        'Completados' => pedido.estado == _EstadoPedido.delivered,
        _ => true,
      };

      return coincideBusqueda && coincideFiltro;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _fondoPagina,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _EncabezadoPedidos(
                    onNuevaOrden: () {
                      setState(() {
                        _mostrarMenuNuevaOrden = true;
                      });
                    },
                  ),
                  const SizedBox(height: 28),
                  const _ResumenPedidos(),
                  const SizedBox(height: 28),
                  _PanelPedidos(
                    busquedaController: _busquedaController,
                    filtroSeleccionado: _filtroSeleccionado,
                    onFiltroSeleccionado: (filtro) {
                      setState(() {
                        _filtroSeleccionado = filtro;
                      });
                    },
                    onBuscar: () {
                      setState(() {});
                    },
                    pedidos: _pedidosFiltrados,
                  ),
                ],
              ),
            ),
          ),
          if (_mostrarMenuNuevaOrden)
            MenuCartaPedidos(
              onCerrar: () {
                setState(() {
                  _mostrarMenuNuevaOrden = false;
                });
              },
              onGuardarOrden: () {
                setState(() {
                  _mostrarMenuNuevaOrden = false;
                });
              },
            ),
        ],
      ),
    );
  }
}

class _EncabezadoPedidos extends StatelessWidget {
  final VoidCallback onNuevaOrden;

  const _EncabezadoPedidos({
    required this.onNuevaOrden,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lista de Pedidos',
                style: TextStyle(
                  color: _textoPrincipal,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Gestión y seguimiento de órdenes de medicamentos en tiempo real.',
                style: TextStyle(
                  color: Color(0xFF214025),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 36,
          child: ElevatedButton.icon(
            onPressed: onNuevaOrden,
            icon: const Icon(
              Icons.add,
              size: 18,
              color: Colors.white,
            ),
            label: const Text(
              'Nueva Orden',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _verdeOscuro,
              elevation: 7,
              shadowColor: _verdeOscuro.withOpacity(0.35),
              padding: const EdgeInsets.symmetric(horizontal: 27),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResumenPedidos extends StatelessWidget {
  const _ResumenPedidos();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _TarjetaResumenPedido(
            titulo: 'TOTAL HOY',
            valor: '142',
            icono: Icons.shopping_cart_outlined,
            fondoIcono: Color(0xFFEAF7DF),
            colorIcono: _verdeOscuro,
          ),
        ),
        SizedBox(width: 20),
        Expanded(
          child: _TarjetaResumenPedido(
            titulo: 'PENDIENTES',
            valor: '28',
            icono: Icons.assignment_outlined,
            fondoIcono: Color(0xFFE8F1FF),
            colorIcono: _azul,
          ),
        ),
        SizedBox(width: 20),
        Expanded(
          child: _TarjetaResumenPedido(
            titulo: 'EN CAMINO',
            valor: '15',
            icono: Icons.local_shipping_outlined,
            fondoIcono: Color(0xFFEAF7DF),
            colorIcono: _verdeOscuro,
          ),
        ),
        SizedBox(width: 20),
        Expanded(
          child: _TarjetaResumenPedido(
            titulo: 'CANCELADOS',
            valor: '3',
            icono: Icons.cancel_outlined,
            fondoIcono: Color(0xFFFFE8E8),
            colorIcono: _rojo,
          ),
        ),
      ],
    );
  }
}

class _TarjetaResumenPedido extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color fondoIcono;
  final Color colorIcono;

  const _TarjetaResumenPedido({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.fondoIcono,
    required this.colorIcono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _bordeSuave),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: fondoIcono,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(
              icono,
              color: colorIcono,
              size: 23,
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  color: Color(0xFF34423B),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                valor,
                style: const TextStyle(
                  color: _textoPrincipal,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PanelPedidos extends StatelessWidget {
  final TextEditingController busquedaController;
  final String filtroSeleccionado;
  final ValueChanged<String> onFiltroSeleccionado;
  final VoidCallback onBuscar;
  final List<_Pedido> pedidos;

  const _PanelPedidos({
    required this.busquedaController,
    required this.filtroSeleccionado,
    required this.onFiltroSeleccionado,
    required this.onBuscar,
    required this.pedidos,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _fondoPagina,
        border: Border.all(color: _bordeSuave),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
            child: Row(
              children: [
                SizedBox(
                  width: 280,
                  height: 36,
                  child: TextField(
                    controller: busquedaController,
                    onChanged: (_) => onBuscar(),
                    cursorColor: _verdeOscuro,
                    style: const TextStyle(
                      color: _textoPrincipal,
                      fontSize: 12,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Buscar por ID, Cliente o Medicamento...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF7E8790),
                        fontSize: 12,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 18,
                        color: Color(0xFF34423B),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 36,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFFC8D6C0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFFC8D6C0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(
                          color: _verdeOscuro,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      side: const BorderSide(color: Color(0xFFC8D6C0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Icon(
                      Icons.filter_list,
                      color: Color(0xFF34423B),
                      size: 20,
                    ),
                  ),
                ),
                const Spacer(),
                _FiltroEstadoPedidos(
                  seleccionado: filtroSeleccionado,
                  onSeleccionar: onFiltroSeleccionado,
                ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final anchoTabla =
                  constraints.maxWidth < 940 ? 940.0 : constraints.maxWidth;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: anchoTabla,
                  child: _TablaPedidos(
                    pedidos: pedidos,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FiltroEstadoPedidos extends StatelessWidget {
  final String seleccionado;
  final ValueChanged<String> onSeleccionar;

  const _FiltroEstadoPedidos({
    required this.seleccionado,
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      width: 306,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFC8D6C0)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          _BotonFiltroPedido(
            texto: 'Todos',
            activo: seleccionado == 'Todos',
            onTap: () => onSeleccionar('Todos'),
          ),
          _BotonFiltroPedido(
            texto: 'Pendientes',
            activo: seleccionado == 'Pendientes',
            onTap: () => onSeleccionar('Pendientes'),
          ),
          _BotonFiltroPedido(
            texto: 'Completados',
            activo: seleccionado == 'Completados',
            onTap: () => onSeleccionar('Completados'),
          ),
        ],
      ),
    );
  }
}

class _BotonFiltroPedido extends StatelessWidget {
  final String texto;
  final bool activo;
  final VoidCallback onTap;

  const _BotonFiltroPedido({
    required this.texto,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 28,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: EdgeInsets.zero,
            backgroundColor: activo ? const Color(0xFFF6F4F1) : Colors.white,
            foregroundColor: _textoPrincipal,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          child: Text(
            texto,
            style: TextStyle(
              fontSize: 11,
              fontWeight: activo ? FontWeight.w900 : FontWeight.w700,
              color: activo ? _verdeOscuro : _textoPrincipal,
            ),
          ),
        ),
      ),
    );
  }
}

class _TablaPedidos extends StatelessWidget {
  final List<_Pedido> pedidos;

  const _TablaPedidos({
    required this.pedidos,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _HeaderTablaPedidos(),
        for (final pedido in pedidos) _FilaPedido(pedido: pedido),
      ],
    );
  }
}

class _HeaderTablaPedidos extends StatelessWidget {
  const _HeaderTablaPedidos();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: const BoxDecoration(
        color: _fondoPagina,
        border: Border(
          top: BorderSide(color: Color(0xFFE0E8D8), width: 1),
          bottom: BorderSide(color: Color(0xFFE0E8D8), width: 1),
        ),
      ),
      child: const Row(
        children: [
          SizedBox(width: 20),
          Expanded(flex: 12, child: _TextoHeaderTabla('ORDER\nID')),
          Expanded(flex: 15, child: _TextoHeaderTabla('FECHA')),
          Expanded(flex: 18, child: _TextoHeaderTabla('CLIENTE')),
          Expanded(flex: 22, child: _TextoHeaderTabla('MEDICAMENTO')),
          Expanded(flex: 8, child: _TextoHeaderTabla('CANT.')),
          Expanded(flex: 12, child: _TextoHeaderTabla('TOTAL')),
          Expanded(flex: 16, child: _TextoHeaderTabla('ESTADO')),
          Expanded(flex: 12, child: _TextoHeaderTabla('ACCIONES')),
          SizedBox(width: 18),
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
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _FilaPedido extends StatelessWidget {
  final _Pedido pedido;

  const _FilaPedido({
    required this.pedido,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE0E8D8),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 20),
          Expanded(
            flex: 12,
            child: Text(
              pedido.ordenId.replaceFirst('-', '-\n'),
              style: const TextStyle(
                color: _verdeOscuro,
                fontSize: 12,
                height: 1.1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            flex: 15,
            child: Text(
              pedido.fecha.replaceAll(' · ', ' ·\n'),
              style: const TextStyle(
                color: _textoPrincipal,
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              pedido.cliente.replaceFirst(' ', '\n'),
              style: const TextStyle(
                color: _textoPrincipal,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 22,
            child: Text(
              pedido.medicamento.replaceFirst(' ', '\n'),
              style: const TextStyle(
                color: _textoPrincipal,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 8,
            child: Text(
              '${pedido.cantidad}',
              style: const TextStyle(
                color: _textoPrincipal,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            flex: 12,
            child: Text(
              '\$${pedido.total.toStringAsFixed(2)}',
              style: const TextStyle(
                color: _textoPrincipal,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            flex: 16,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _BadgeEstadoPedido(estado: pedido.estado),
            ),
          ),
          Expanded(
            flex: 12,
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.remove_red_eye_outlined,
                  color: _verdeOscuro,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
        ],
      ),
    );
  }
}

class _BadgeEstadoPedido extends StatelessWidget {
  final _EstadoPedido estado;

  const _BadgeEstadoPedido({
    required this.estado,
  });

  @override
  Widget build(BuildContext context) {
    Color fondo;
    Color texto;
    String label;

    switch (estado) {
      case _EstadoPedido.pending:
        fondo = const Color(0xFFE8F1FF);
        texto = _azul;
        label = '● Pending';
        break;
      case _EstadoPedido.shipped:
        fondo = const Color(0xFFE8F5DD);
        texto = _verdeOscuro;
        label = '● Shipped';
        break;
      case _EstadoPedido.delivered:
        fondo = const Color(0xFFE8EDE1);
        texto = _verdeOscuro;
        label = '● Delivered';
        break;
      case _EstadoPedido.cancelled:
        fondo = const Color(0xFFFFE8E8);
        texto = _rojo;
        label = '● Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: texto,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Pedido {
  final String ordenId;
  final String fecha;
  final String cliente;
  final String medicamento;
  final int cantidad;
  final double total;
  final _EstadoPedido estado;

  const _Pedido({
    required this.ordenId,
    required this.fecha,
    required this.cliente,
    required this.medicamento,
    required this.cantidad,
    required this.total,
    required this.estado,
  });
}

enum _EstadoPedido {
  pending,
  shipped,
  delivered,
  cancelled,
}