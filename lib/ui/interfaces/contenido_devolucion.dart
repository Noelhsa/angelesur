import 'package:flutter/material.dart';

import '../../utils/config_moneda.dart';
import 'menu_carta_devolucion_cliente.dart';
import 'menu_carta_devolucion_proveedor.dart';

const Color _fondoPagina = Color(0xFFE2E2E2);
const Color _verdeOscuro = Color(0xFF397800);
const Color _verde = Color(0xFF64D20A);
const Color _azul = Color(0xFF0B63CE);
const Color _textoPrincipal = Color(0xFF101828);
const Color _textoSecundario = Color(0xFF667085);
const Color _bordeSuave = Color(0xFFD9E6D3);
const Color _grisCabeceraTabla = Color(0xFFE7E3E3);
const Color _rojo = Color(0xFFE02020);
const Color _naranja = Color(0xFFFF8A00);

class ContenidoDevolucion extends StatefulWidget {
  const ContenidoDevolucion({super.key});

  @override
  State<ContenidoDevolucion> createState() => _ContenidoDevolucionState();
}

class _ContenidoDevolucionState extends State<ContenidoDevolucion> {
  String _filtroSeleccionado = 'Todos';
  bool _mostrarMenuDevolucionCliente = false;
  bool _mostrarMenuDevolucionProveedor = false;

  final List<_Devolucion> _devoluciones = const [
    _Devolucion(
      id: '#RET-8842',
      fecha: '12 Oct 2023',
      tipo: _TipoDevolucion.cliente,
      observaciones: 'Caducidad próxima',
      estado: _EstadoDevolucion.procesado,
      total: 450.00,
    ),
    _Devolucion(
      id: '#RET-8843',
      fecha: '12 Oct 2023',
      tipo: _TipoDevolucion.proveedor,
      observaciones: 'Producto dañado',
      estado: _EstadoDevolucion.pendiente,
      total: 1200.50,
    ),
    _Devolucion(
      id: '#RET-8844',
      fecha: '11 Oct 2023',
      tipo: _TipoDevolucion.cliente,
      observaciones: 'Error en despacho',
      estado: _EstadoDevolucion.procesado,
      total: 85.00,
    ),
    _Devolucion(
      id: '#RET-8845',
      fecha: '11 Oct 2023',
      tipo: _TipoDevolucion.cliente,
      observaciones: 'Caducidad',
      estado: _EstadoDevolucion.pendiente,
      total: 120.00,
    ),
    _Devolucion(
      id: '#RET-8846',
      fecha: '10 Oct 2023',
      tipo: _TipoDevolucion.proveedor,
      observaciones: 'Sobrestock / Acuerdo',
      estado: _EstadoDevolucion.procesado,
      total: 3400.00,
    ),
  ];

  List<_Devolucion> get _devolucionesFiltradas {
    return _devoluciones.where((devolucion) {
      if (_filtroSeleccionado == 'Clientes') {
        return devolucion.tipo == _TipoDevolucion.cliente;
      }

      if (_filtroSeleccionado == 'Proveedores') {
        return devolucion.tipo == _TipoDevolucion.proveedor;
      }

      return true;
    }).toList();
  }

  double get _totalRetornos {
    return _devoluciones.fold<double>(
      0,
      (total, devolucion) => total + devolucion.total,
    );
  }

  int get _devolucionesClientes {
    return _devoluciones
        .where((devolucion) => devolucion.tipo == _TipoDevolucion.cliente)
        .length;
  }

  int get _devolucionesProveedores {
    return _devoluciones
        .where((devolucion) => devolucion.tipo == _TipoDevolucion.proveedor)
        .length;
  }

  void _abrirMenuDevolucionCliente() {
    setState(() {
      _mostrarMenuDevolucionProveedor = false;
      _mostrarMenuDevolucionCliente = true;
    });
  }

  void _cerrarMenuDevolucionCliente() {
    setState(() {
      _mostrarMenuDevolucionCliente = false;
    });
  }

  void _guardarDevolucionCliente() {
    setState(() {
      _mostrarMenuDevolucionCliente = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Devolución a cliente guardada localmente. Falta conectar endpoint.',
        ),
      ),
    );
  }

  void _abrirMenuDevolucionProveedor() {
    setState(() {
      _mostrarMenuDevolucionCliente = false;
      _mostrarMenuDevolucionProveedor = true;
    });
  }

  void _cerrarMenuDevolucionProveedor() {
    setState(() {
      _mostrarMenuDevolucionProveedor = false;
    });
  }

  void _guardarDevolucionProveedor() {
    setState(() {
      _mostrarMenuDevolucionProveedor = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Devolución a proveedor guardada localmente. Falta conectar endpoint.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _fondoPagina,
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.topLeft,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(26, 26, 26, 34),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _EncabezadoDevoluciones(
                      onDevolucionProveedor: _abrirMenuDevolucionProveedor,
                      onDevolucionCliente: _abrirMenuDevolucionCliente,
                    ),
                    const SizedBox(height: 28),
                    _ResumenDevoluciones(
                      devolucionesClientes: _devolucionesClientes,
                      devolucionesProveedores: _devolucionesProveedores,
                      totalRetornos: _totalRetornos,
                    ),
                    const SizedBox(height: 28),
                    _PanelDevoluciones(
                      filtroSeleccionado: _filtroSeleccionado,
                      onFiltroSeleccionado: (filtro) {
                        setState(() {
                          _filtroSeleccionado = filtro;
                        });
                      },
                      devoluciones: _devolucionesFiltradas,
                    ),
                    const SizedBox(height: 28),
                    const _MotivosDevolucion(),
                  ],
                ),
              ),
            ),
          ),
          if (_mostrarMenuDevolucionCliente)
            MenuCartaDevolucionCliente(
              onCerrar: _cerrarMenuDevolucionCliente,
              onGuardarDevolucion: _guardarDevolucionCliente,
            ),
          if (_mostrarMenuDevolucionProveedor)
            MenuCartaDevolucionProveedor(
              onCerrar: _cerrarMenuDevolucionProveedor,
              onGuardarDevolucion: _guardarDevolucionProveedor,
            ),
        ],
      ),
    );
  }
}

class _EncabezadoDevoluciones extends StatelessWidget {
  final VoidCallback onDevolucionProveedor;
  final VoidCallback onDevolucionCliente;

  const _EncabezadoDevoluciones({
    required this.onDevolucionProveedor,
    required this.onDevolucionCliente,
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
                'Gestión de Devoluciones',
                style: TextStyle(
                  color: _textoPrincipal,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Monitoreo y procesamiento de retornos de inventario en tiempo real.',
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
          height: 38,
          child: OutlinedButton.icon(
            onPressed: onDevolucionProveedor,
            icon: const Icon(
              Icons.local_shipping_outlined,
              color: _textoPrincipal,
              size: 16,
            ),
            label: const Text(
              'Devolución a Proveedor',
              style: TextStyle(
                color: _textoPrincipal,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFFF6F4F1),
              side: const BorderSide(color: Color(0xFFC8D6C0)),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 38,
          child: ElevatedButton.icon(
            onPressed: onDevolucionCliente,
            icon: const Icon(
              Icons.person_outline,
              color: Colors.white,
              size: 17,
            ),
            label: const Text(
              'Devolución a Cliente',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _verdeOscuro,
              elevation: 6,
              shadowColor: _verdeOscuro.withOpacity(0.25),
              padding: const EdgeInsets.symmetric(horizontal: 22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResumenDevoluciones extends StatelessWidget {
  final int devolucionesClientes;
  final int devolucionesProveedores;
  final double totalRetornos;

  const _ResumenDevoluciones({
    required this.devolucionesClientes,
    required this.devolucionesProveedores,
    required this.totalRetornos,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TarjetaResumenDevolucion(
            titulo: 'Devoluciones de Clientes',
            valor: '$devolucionesClientes',
            extra: '+12%',
            extraColor: _verdeOscuro,
            icono: Icons.manage_accounts_outlined,
            fondoIcono: const Color(0xFFEAF7DF),
            colorIcono: _verdeOscuro,
          ),
        ),
        const SizedBox(width: 22),
        Expanded(
          child: _TarjetaResumenDevolucion(
            titulo: 'Devoluciones a Proveedores',
            valor: '$devolucionesProveedores',
            extra: '-5%',
            extraColor: _rojo,
            icono: Icons.local_shipping_outlined,
            fondoIcono: const Color(0xFFE8F1FF),
            colorIcono: _azul,
          ),
        ),
        const SizedBox(width: 22),
        Expanded(
          child: _TarjetaResumenDevolucion(
            titulo: 'Total en Retornos',
            valor: ConfigMoneda.formato(totalRetornos),
            extra: '',
            extraColor: _verdeOscuro,
            icono: Icons.inventory_2_outlined,
            fondoIcono: const Color(0xFFE8F8EE),
            colorIcono: _verdeOscuro,
          ),
        ),
      ],
    );
  }
}

class _TarjetaResumenDevolucion extends StatelessWidget {
  final String titulo;
  final String valor;
  final String extra;
  final Color extraColor;
  final IconData icono;
  final Color fondoIcono;
  final Color colorIcono;

  const _TarjetaResumenDevolucion({
    required this.titulo,
    required this.valor,
    required this.extra,
    required this.extraColor,
    required this.icono,
    required this.fondoIcono,
    required this.colorIcono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _bordeSuave),
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
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
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6A736C),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        valor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textoPrincipal,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (extra.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        extra,
                        style: TextStyle(
                          color: extraColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelDevoluciones extends StatelessWidget {
  final String filtroSeleccionado;
  final ValueChanged<String> onFiltroSeleccionado;
  final List<_Devolucion> devoluciones;

  const _PanelDevoluciones({
    required this.filtroSeleccionado,
    required this.onFiltroSeleccionado,
    required this.devoluciones,
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
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Row(
              children: [
                _TabsDevoluciones(
                  filtroSeleccionado: filtroSeleccionado,
                  onFiltroSeleccionado: onFiltroSeleccionado,
                ),
                const Spacer(),
                _BotonSecundario(
                  texto: 'Filtros',
                  icono: Icons.filter_list,
                  onTap: () {},
                ),
                const SizedBox(width: 8),
                _BotonSecundario(
                  texto: 'Ordenar',
                  icono: Icons.sort,
                  onTap: () {},
                ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final anchoTabla =
                  constraints.maxWidth < 900 ? 900.0 : constraints.maxWidth;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: anchoTabla,
                  child: _TablaDevoluciones(
                    devoluciones: devoluciones,
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

class _TabsDevoluciones extends StatelessWidget {
  final String filtroSeleccionado;
  final ValueChanged<String> onFiltroSeleccionado;

  const _TabsDevoluciones({
    required this.filtroSeleccionado,
    required this.onFiltroSeleccionado,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TabDevolucion(
          texto: 'Todos',
          activo: filtroSeleccionado == 'Todos',
          onTap: () => onFiltroSeleccionado('Todos'),
        ),
        _TabDevolucion(
          texto: 'Clientes',
          activo: filtroSeleccionado == 'Clientes',
          onTap: () => onFiltroSeleccionado('Clientes'),
        ),
        _TabDevolucion(
          texto: 'Proveedores',
          activo: filtroSeleccionado == 'Proveedores',
          onTap: () => onFiltroSeleccionado('Proveedores'),
        ),
      ],
    );
  }
}

class _TabDevolucion extends StatelessWidget {
  final String texto;
  final bool activo;
  final VoidCallback onTap;

  const _TabDevolucion({
    required this.texto,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 5, 22, 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: activo ? _verdeOscuro : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          texto,
          style: TextStyle(
            color: activo ? _verdeOscuro : _textoSecundario,
            fontSize: 12,
            fontWeight: activo ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _BotonSecundario extends StatelessWidget {
  final String texto;
  final IconData icono;
  final VoidCallback onTap;

  const _BotonSecundario({
    required this.texto,
    required this.icono,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(
          icono,
          color: _textoPrincipal,
          size: 14,
        ),
        label: Text(
          texto,
          style: const TextStyle(
            color: _textoPrincipal,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFF6F4F1),
          side: const BorderSide(color: Color(0xFFC8D6C0)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
    );
  }
}

class _TablaDevoluciones extends StatelessWidget {
  final List<_Devolucion> devoluciones;

  const _TablaDevoluciones({
    required this.devoluciones,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _HeaderTablaDevoluciones(),
        for (final devolucion in devoluciones)
          _FilaDevolucion(devolucion: devolucion),
      ],
    );
  }
}

class _HeaderTablaDevoluciones extends StatelessWidget {
  const _HeaderTablaDevoluciones();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      color: _grisCabeceraTabla,
      child: const Row(
        children: [
          SizedBox(width: 22),
          Expanded(flex: 15, child: _TextoHeaderTabla('ID Devolución')),
          Expanded(flex: 16, child: _TextoHeaderTabla('Fecha')),
          Expanded(flex: 14, child: _TextoHeaderTabla('Tipo')),
          Expanded(flex: 24, child: _TextoHeaderTabla('Observaciones')),
          Expanded(flex: 16, child: _TextoHeaderTabla('Estado')),
          Expanded(flex: 15, child: _TextoHeaderTabla('Total')),
          Expanded(flex: 12, child: _TextoHeaderTabla('Acciones')),
          SizedBox(width: 16),
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
        color: Color(0xFF747B65),
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _FilaDevolucion extends StatelessWidget {
  final _Devolucion devolucion;

  const _FilaDevolucion({
    required this.devolucion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: const BoxDecoration(
        color: Colors.white,
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
            flex: 15,
            child: Text(
              devolucion.id,
              style: const TextStyle(
                color: _textoPrincipal,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            flex: 16,
            child: Text(
              devolucion.fecha,
              style: const TextStyle(
                color: Color(0xFF56605A),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 14,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _BadgeTipo(tipo: devolucion.tipo),
            ),
          ),
          Expanded(
            flex: 24,
            child: Text(
              devolucion.observaciones,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF56605A),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 16,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _BadgeEstado(estado: devolucion.estado),
            ),
          ),
          Expanded(
            flex: 15,
            child: Text(
              ConfigMoneda.formato(devolucion.total),
              style: const TextStyle(
                color: _textoPrincipal,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            flex: 12,
            child: IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.remove_red_eye_outlined,
                color: Color(0xFF667085),
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

class _BadgeTipo extends StatelessWidget {
  final _TipoDevolucion tipo;

  const _BadgeTipo({
    required this.tipo,
  });

  @override
  Widget build(BuildContext context) {
    final esCliente = tipo == _TipoDevolucion.cliente;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: esCliente ? const Color(0xFFE8F5DD) : const Color(0xFFE4E4E4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        esCliente ? 'CLIENTE' : 'PROVEEDOR',
        style: TextStyle(
          color: esCliente ? _verdeOscuro : const Color(0xFF555D66),
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BadgeEstado extends StatelessWidget {
  final _EstadoDevolucion estado;

  const _BadgeEstado({
    required this.estado,
  });

  @override
  Widget build(BuildContext context) {
    final procesado = estado == _EstadoDevolucion.procesado;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: procesado ? const Color(0xFFE8F1FF) : const Color(0xFFFFF0DE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        procesado ? 'PROCESADO' : 'PENDIENTE',
        style: TextStyle(
          color: procesado ? _azul : _naranja,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MotivosDevolucion extends StatelessWidget {
  const _MotivosDevolucion();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _bordeSuave),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        children: [
          const Text(
            'Motivos de Devolución',
            style: TextStyle(
              color: _textoPrincipal,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Distribución porcentual de las causas más frecuentes este trimestre.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textoSecundario,
              fontSize: 11,
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 125,
                  height: 125,
                  child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 20,
                    backgroundColor: const Color(0xFFE8E8E8),
                    color: _verde,
                  ),
                ),
                const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '100%',
                      style: TextStyle(
                        color: _textoPrincipal,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Total Causas',
                      style: TextStyle(
                        color: _textoSecundario,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Row(
            children: [
              Expanded(
                child: _LeyendaMotivo(
                  texto: 'Caducidad (45%)',
                  color: _verde,
                  fondo: Color(0xFFEAF7DF),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _LeyendaMotivo(
                  texto: 'Daño (22%)',
                  color: _azul,
                  fondo: Color(0xFFE8F1FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Expanded(
                child: _LeyendaMotivo(
                  texto: 'Error Pedido (18%)',
                  color: Color(0xFF9CA3AF),
                  fondo: Color(0xFFF3F4F6),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _LeyendaMotivo(
                  texto: 'Otros (15%)',
                  color: _rojo,
                  fondo: Color(0xFFFFE8E8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeyendaMotivo extends StatelessWidget {
  final String texto;
  final Color color;
  final Color fondo;

  const _LeyendaMotivo({
    required this.texto,
    required this.color,
    required this.fondo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _textoPrincipal,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Devolucion {
  final String id;
  final String fecha;
  final _TipoDevolucion tipo;
  final String observaciones;
  final _EstadoDevolucion estado;
  final double total;

  const _Devolucion({
    required this.id,
    required this.fecha,
    required this.tipo,
    required this.observaciones,
    required this.estado,
    required this.total,
  });
}

enum _TipoDevolucion {
  cliente,
  proveedor,
}

enum _EstadoDevolucion {
  procesado,
  pendiente,
}