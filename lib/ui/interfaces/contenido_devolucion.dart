import 'package:flutter/material.dart';

import '../../models/usuario.dart';
import '../../services/api_client.dart';
import '../../services/compras_api_service.dart';
import '../../services/devoluciones_api_service.dart';
import '../../services/ventas_api_service.dart';
import '../../utils/config_moneda.dart';
import 'menu_carta_devolucion_cliente.dart';
import 'menu_carta_devolucion_proveedor.dart';

const Color _fondoPagina = Color(0xFFE2E2E2);
const Color _verdeOscuro = Color(0xFF397800);
const Color _azul = Color(0xFF0B63CE);
const Color _textoPrincipal = Color(0xFF101828);
const Color _textoSecundario = Color(0xFF667085);
const Color _bordeSuave = Color(0xFFD9E6D3);
const Color _grisCabeceraTabla = Color(0xFFE7E3E3);
const Color _rojo = Color(0xFFE02020);

class ContenidoDevolucion extends StatefulWidget {
  final Usuario usuario;

  const ContenidoDevolucion({
    super.key,
    required this.usuario,
  });

  @override
  State<ContenidoDevolucion> createState() => _ContenidoDevolucionState();
}

class _ContenidoDevolucionState extends State<ContenidoDevolucion> {
  final DevolucionesApiService _devolucionesApiService =
      DevolucionesApiService();
  final VentasApiService _ventasApiService = VentasApiService();
  final ComprasApiService _comprasApiService = ComprasApiService();

  String _filtroSeleccionado = 'Todos';
  bool _cargando = true;
  bool _procesando = false;
  bool _mostrarMenuDevolucionCliente = false;
  bool _mostrarMenuDevolucionProveedor = false;

  String? _error;
  List<DevolucionClienteResumen> _clientes = [];
  List<DevolucionProveedorResumen> _proveedores = [];

  @override
  void initState() {
    super.initState();
    _cargarDevoluciones();
  }

  List<_DevolucionFila> get _devoluciones {
    final items = <_DevolucionFila>[
      ..._clientes.map(_DevolucionFila.cliente),
      ..._proveedores.map(_DevolucionFila.proveedor),
    ];

    items.sort((a, b) {
      final fechaA = a.fecha ?? DateTime.fromMillisecondsSinceEpoch(0);
      final fechaB = b.fecha ?? DateTime.fromMillisecondsSinceEpoch(0);
      return fechaB.compareTo(fechaA);
    });

    return items.where((item) {
      if (_filtroSeleccionado == 'Clientes') return item.esCliente;
      if (_filtroSeleccionado == 'Proveedores') return item.esProveedor;
      if (_filtroSeleccionado == 'Canceladas') {
        return item.estatus == 'CANCELADA';
      }
      return true;
    }).toList();
  }

  double get _totalRetornos {
    return _clientes.fold<double>(
          0,
          (total, item) => total + item.totalDevuelto,
        ) +
        _proveedores.fold<double>(
          0,
          (total, item) => total + item.totalDevolucion,
        );
  }

  Future<void> _cargarDevoluciones() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _devolucionesApiService.listarClientes(limite: 300),
        _devolucionesApiService.listarProveedores(limite: 300),
      ]);

      if (!mounted) return;

      setState(() {
        _clientes = results[0] as List<DevolucionClienteResumen>;
        _proveedores = results[1] as List<DevolucionProveedorResumen>;
        _cargando = false;
      });
    } on ApiException catch (error) {
      _mostrarError(error.message);
    } catch (_) {
      _mostrarError('No se pudieron cargar las devoluciones');
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;

    setState(() {
      _error = mensaje;
      _cargando = false;
      _procesando = false;
    });
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  void _registrarCliente() {
    if (_procesando) return;

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

  Future<void> _guardarDevolucionClienteDesdeMenu(
    RegistrarDevolucionClientePayload payload,
  ) async {
    setState(() => _procesando = true);

    try {
      final devolucion = await _devolucionesApiService.registrarCliente(
        payload,
      );

      _mostrarMensaje('Devolucion ${devolucion.folio} registrada');

      setState(() {
        _mostrarMenuDevolucionCliente = false;
      });

      await _cargarDevoluciones();
    } on ApiException catch (error) {
      _mostrarMensaje(error.message);
    } catch (_) {
      _mostrarMensaje('No se pudo registrar la devolucion de cliente');
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  void _registrarProveedor() {
    if (_procesando) return;

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

  Future<void> _guardarDevolucionProveedorDesdeMenu(
    RegistrarDevolucionProveedorPayload payload,
  ) async {
    setState(() => _procesando = true);

    try {
      final devolucion = await _devolucionesApiService.registrarProveedor(
        payload,
      );

      _mostrarMensaje('Devolucion ${devolucion.folio} registrada');

      setState(() {
        _mostrarMenuDevolucionProveedor = false;
      });

      await _cargarDevoluciones();
    } on ApiException catch (error) {
      _mostrarMensaje(error.message);
    } catch (_) {
      _mostrarMensaje('No se pudo registrar la devolucion a proveedor');
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _verDetalle(_DevolucionFila item) async {
    showDialog<void>(
      context: context,
      builder: (context) => item.esCliente
          ? _DialogoDetalleCliente(
              future: _devolucionesApiService.obtenerCliente(item.id),
            )
          : _DialogoDetalleProveedor(
              future: _devolucionesApiService.obtenerProveedor(item.id),
            ),
    );
  }

  Future<void> _cancelar(_DevolucionFila item) async {
    if (item.estatus == 'CANCELADA' || _procesando) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar devolucion'),
        content: Text('Se cancelara la devolucion ${item.folio}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Volver'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancelar devolucion'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _procesando = true);

    try {
      if (item.esCliente) {
        await _devolucionesApiService.cancelarCliente(
          idDevolucion: item.id,
          idUsuario: widget.usuario.id,
          observaciones: 'Cancelada desde interfaz',
        );
      } else {
        await _devolucionesApiService.cancelarProveedor(
          idDevolucion: item.id,
          idUsuario: widget.usuario.id,
          observaciones: 'Cancelada desde interfaz',
        );
      }

      _mostrarMensaje('Devolucion cancelada');

      await _cargarDevoluciones();
    } on ApiException catch (error) {
      _mostrarMensaje(error.message);
    } catch (_) {
      _mostrarMensaje('No se pudo cancelar la devolucion');
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.topLeft,
      color: _fondoPagina,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(26, 26, 26, 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _EncabezadoDevoluciones(
                    procesando: _procesando,
                    onDevolucionProveedor: _registrarProveedor,
                    onDevolucionCliente: _registrarCliente,
                  ),
                  const SizedBox(height: 28),
                  _ResumenDevoluciones(
                    devolucionesClientes: _clientes.length,
                    devolucionesProveedores: _proveedores.length,
                    totalRetornos: _totalRetornos,
                  ),
                  const SizedBox(height: 28),
                  if (_cargando)
                    const _EstadoDevoluciones(
                      mensaje: 'Cargando devoluciones...',
                    )
                  else if (_error != null)
                    _EstadoDevoluciones(
                      mensaje: _error!,
                      onReintentar: _cargarDevoluciones,
                    )
                  else
                    _PanelDevoluciones(
                      filtroSeleccionado: _filtroSeleccionado,
                      onFiltroSeleccionado: (filtro) {
                        setState(() => _filtroSeleccionado = filtro);
                      },
                      devoluciones: _devoluciones,
                      onDetalle: _verDetalle,
                      onCancelar: _cancelar,
                      procesando: _procesando,
                    ),
                ],
              ),
            ),
          ),
          if (_mostrarMenuDevolucionCliente)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 20, 14, 20),
              child: MenuCartaDevolucionCliente(
                idUsuario: widget.usuario.id,
                ventasApiService: _ventasApiService,
                procesando: _procesando,
                onCerrar: _cerrarMenuDevolucionCliente,
                onGuardarDevolucion: _guardarDevolucionClienteDesdeMenu,
              ),
            ),
          if (_mostrarMenuDevolucionProveedor)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 20, 14, 20),
              child: MenuCartaDevolucionProveedor(
                idUsuario: widget.usuario.id,
                comprasApiService: _comprasApiService,
                procesando: _procesando,
                onCerrar: _cerrarMenuDevolucionProveedor,
                onGuardarDevolucion: _guardarDevolucionProveedorDesdeMenu,
              ),
            ),
        ],
      ),
    );
  }
}

class _EncabezadoDevoluciones extends StatelessWidget {
  final bool procesando;
  final VoidCallback onDevolucionProveedor;
  final VoidCallback onDevolucionCliente;

  const _EncabezadoDevoluciones({
    required this.procesando,
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
                'Gestion de Devoluciones',
                style: TextStyle(
                  color: _textoPrincipal,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Retornos de clientes y devoluciones a proveedores desde la base de datos.',
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
            onPressed: procesando ? null : onDevolucionProveedor,
            icon: const Icon(Icons.local_shipping_outlined, size: 16),
            label: const Text('Devolucion a Proveedor'),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 38,
          child: ElevatedButton.icon(
            onPressed: procesando ? null : onDevolucionCliente,
            icon: const Icon(
              Icons.person_outline,
              color: Colors.white,
              size: 17,
            ),
            label: const Text(
              'Devolucion a Cliente',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _verdeOscuro,
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
            icono: Icons.manage_accounts_outlined,
            colorIcono: _verdeOscuro,
          ),
        ),
        const SizedBox(width: 22),
        Expanded(
          child: _TarjetaResumenDevolucion(
            titulo: 'Devoluciones a Proveedores',
            valor: '$devolucionesProveedores',
            icono: Icons.local_shipping_outlined,
            colorIcono: _azul,
          ),
        ),
        const SizedBox(width: 22),
        Expanded(
          child: _TarjetaResumenDevolucion(
            titulo: 'Total en Retornos',
            valor: ConfigMoneda.formato(totalRetornos),
            icono: Icons.inventory_2_outlined,
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
  final IconData icono;
  final Color colorIcono;

  const _TarjetaResumenDevolucion({
    required this.titulo,
    required this.valor,
    required this.icono,
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
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7DF),
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
                Text(
                  valor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textoPrincipal,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
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

class _PanelDevoluciones extends StatelessWidget {
  final String filtroSeleccionado;
  final ValueChanged<String> onFiltroSeleccionado;
  final List<_DevolucionFila> devoluciones;
  final ValueChanged<_DevolucionFila> onDetalle;
  final ValueChanged<_DevolucionFila> onCancelar;
  final bool procesando;

  const _PanelDevoluciones({
    required this.filtroSeleccionado,
    required this.onFiltroSeleccionado,
    required this.devoluciones,
    required this.onDetalle,
    required this.onCancelar,
    required this.procesando,
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
            child: _TabsDevoluciones(
              filtroSeleccionado: filtroSeleccionado,
              onFiltroSeleccionado: onFiltroSeleccionado,
            ),
          ),
          if (devoluciones.isEmpty)
            const _EstadoDevoluciones(
              mensaje: 'No hay devoluciones para mostrar',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final anchoLista =
                    constraints.maxWidth < 980 ? 980.0 : constraints.maxWidth;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: anchoLista,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _TablaDevoluciones(
                        devoluciones: devoluciones,
                        onDetalle: onDetalle,
                        onCancelar: onCancelar,
                        procesando: procesando,
                      ),
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
        for (final tab in const [
          'Todos',
          'Clientes',
          'Proveedores',
          'Canceladas'
        ])
          _TabDevolucion(
            texto: tab,
            activo: filtroSeleccionado == tab,
            onTap: () => onFiltroSeleccionado(tab),
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

class _TablaDevoluciones extends StatelessWidget {
  final List<_DevolucionFila> devoluciones;
  final ValueChanged<_DevolucionFila> onDetalle;
  final ValueChanged<_DevolucionFila> onCancelar;
  final bool procesando;

  const _TablaDevoluciones({
    required this.devoluciones,
    required this.onDetalle,
    required this.onCancelar,
    required this.procesando,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < devoluciones.length; index++) ...[
          if (index > 0) const SizedBox(height: 10),
          _FilaDevolucion(
            devolucion: devoluciones[index],
            onDetalle: onDetalle,
            onCancelar: onCancelar,
            procesando: procesando,
          ),
        ],
      ],
    );
  }
}

class _FilaDevolucion extends StatelessWidget {
  final _DevolucionFila devolucion;
  final ValueChanged<_DevolucionFila> onDetalle;
  final ValueChanged<_DevolucionFila> onCancelar;
  final bool procesando;

  const _FilaDevolucion({
    required this.devolucion,
    required this.onDetalle,
    required this.onCancelar,
    required this.procesando,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _grisCabeceraTabla),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              color: devolucion.esCliente
                  ? const Color(0xFFEAF7DF)
                  : const Color(0xFFE8F1FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              devolucion.esCliente
                  ? Icons.person_outline
                  : Icons.local_shipping_outlined,
              color: devolucion.esCliente ? _verdeOscuro : _azul,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  devolucion.folio,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textoPrincipal,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      _formatoFecha(devolucion.fecha),
                      style: const TextStyle(
                        color: _textoSecundario,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 9),
                    _BadgeTipo(esCliente: devolucion.esCliente),
                  ],
                ),
              ],
            ),
          ),
          _MetricaDevolucion(
            titulo: 'Origen',
            valor: devolucion.origen,
            ancho: 150,
          ),
          _MetricaDevolucion(
            titulo: 'Motivo',
            valor: _textoEnum(devolucion.motivo),
            ancho: 150,
          ),
          SizedBox(
            width: 118,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estado',
                  style: TextStyle(
                    color: _textoSecundario,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _BadgeEstado(estatus: devolucion.estatus),
                ),
              ],
            ),
          ),
          _MetricaDevolucion(
            titulo: 'Total',
            valor: ConfigMoneda.formato(devolucion.total),
            ancho: 96,
            fuerte: true,
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => onDetalle(devolucion),
            icon: const Icon(
              Icons.remove_red_eye_outlined,
              size: 19,
            ),
            tooltip: 'Ver detalle',
          ),
          IconButton(
            onPressed: devolucion.estatus == 'CANCELADA' || procesando
                ? null
                : () => onCancelar(devolucion),
            icon: const Icon(
              Icons.cancel_outlined,
              size: 19,
            ),
            tooltip: 'Cancelar',
          ),
        ],
      ),
    );
  }
}

class _MetricaDevolucion extends StatelessWidget {
  final String titulo;
  final String valor;
  final double ancho;
  final bool fuerte;

  const _MetricaDevolucion({
    required this.titulo,
    required this.valor,
    required this.ancho,
    this.fuerte = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ancho,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: _textoSecundario,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _textoPrincipal,
              fontSize: 12,
              fontWeight: fuerte ? FontWeight.w900 : FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeTipo extends StatelessWidget {
  final bool esCliente;

  const _BadgeTipo({
    required this.esCliente,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 4,
      ),
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
  final String estatus;

  const _BadgeEstado({
    required this.estatus,
  });

  @override
  Widget build(BuildContext context) {
    final cancelada = estatus == 'CANCELADA';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: cancelada ? const Color(0xFFFFE8E8) : const Color(0xFFE8F1FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        cancelada ? 'CANCELADA' : 'REGISTRADA',
        style: TextStyle(
          color: cancelada ? _rojo : _azul,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EstadoDevoluciones extends StatelessWidget {
  final String mensaje;
  final VoidCallback? onReintentar;

  const _EstadoDevoluciones({
    required this.mensaje,
    this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            mensaje,
            style: const TextStyle(
              color: _textoSecundario,
              fontSize: 14,
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
    );
  }
}

class _DialogoDetalleCliente extends StatelessWidget {
  final Future<DevolucionClienteDetalle> future;

  const _DialogoDetalleCliente({
    required this.future,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Detalle devolucion cliente'),
      content: SizedBox(
        width: 680,
        child: FutureBuilder<DevolucionClienteDetalle>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 140,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (!snapshot.hasData) {
              return const Text('No se pudo cargar el detalle');
            }

            final devolucion = snapshot.data!;

            return _DetalleContenido(
              datos: [
                _DatoDetalle('Folio', devolucion.folio),
                _DatoDetalle('Venta', devolucion.folioVenta),
                _DatoDetalle('Metodo', _textoEnum(devolucion.metodoDevolucion)),
                _DatoDetalle('Motivo', _textoEnum(devolucion.motivo)),
                _DatoDetalle(
                  'Total',
                  ConfigMoneda.formato(devolucion.totalDevuelto),
                ),
                _DatoDetalle('Estado', devolucion.estatus),
              ],
              renglones: [
                for (final detalle in devolucion.detalles)
                  '${detalle.producto} | lote ${detalle.codigoLote} | cant. ${detalle.cantidad} | ${ConfigMoneda.formato(detalle.subtotalDevuelto)}',
              ],
              observaciones: devolucion.observaciones,
            );
          },
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
}

class _DialogoDetalleProveedor extends StatelessWidget {
  final Future<DevolucionProveedorDetalle> future;

  const _DialogoDetalleProveedor({
    required this.future,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Detalle devolucion proveedor'),
      content: SizedBox(
        width: 680,
        child: FutureBuilder<DevolucionProveedorDetalle>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 140,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (!snapshot.hasData) {
              return const Text('No se pudo cargar el detalle');
            }

            final devolucion = snapshot.data!;

            return _DetalleContenido(
              datos: [
                _DatoDetalle('Folio', devolucion.folio),
                _DatoDetalle('Proveedor', devolucion.proveedor),
                _DatoDetalle(
                  'Compensacion',
                  _textoEnum(devolucion.tipoCompensacion),
                ),
                _DatoDetalle('Motivo', _textoEnum(devolucion.motivo)),
                _DatoDetalle(
                  'Total',
                  ConfigMoneda.formato(devolucion.totalDevolucion),
                ),
                _DatoDetalle('Estado', devolucion.estatus),
              ],
              renglones: [
                for (final detalle in devolucion.detalles)
                  '${detalle.producto} | lote ${detalle.codigoLote} | cant. ${detalle.cantidad} | ${ConfigMoneda.formato(detalle.subtotal)}',
              ],
              observaciones: devolucion.observaciones,
            );
          },
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
}

class _DetalleContenido extends StatelessWidget {
  final List<_DatoDetalle> datos;
  final List<String> renglones;
  final String observaciones;

  const _DetalleContenido({
    required this.datos,
    required this.renglones,
    required this.observaciones,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: datos,
          ),
          const SizedBox(height: 18),
          const Text(
            'Productos',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          for (final renglon in renglones)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(renglon),
            ),
          if (observaciones.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(observaciones),
          ],
        ],
      ),
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
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _textoSecundario,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
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

class _DevolucionFila {
  final int id;
  final String folio;
  final DateTime? fecha;
  final bool esCliente;
  final String origen;
  final String motivo;
  final String estatus;
  final double total;

  const _DevolucionFila({
    required this.id,
    required this.folio,
    required this.fecha,
    required this.esCliente,
    required this.origen,
    required this.motivo,
    required this.estatus,
    required this.total,
  });

  factory _DevolucionFila.cliente(DevolucionClienteResumen item) {
    return _DevolucionFila(
      id: item.idDevolucionCliente,
      folio: item.folio,
      fecha: item.fecha,
      esCliente: true,
      origen: item.folioVenta,
      motivo: item.motivo,
      estatus: item.estatus,
      total: item.totalDevuelto,
    );
  }

  factory _DevolucionFila.proveedor(DevolucionProveedorResumen item) {
    return _DevolucionFila(
      id: item.idDevolucionProveedor,
      folio: item.folio,
      fecha: item.fecha,
      esCliente: false,
      origen: item.proveedor,
      motivo: item.motivo,
      estatus: item.estatus,
      total: item.totalDevolucion,
    );
  }

  bool get esProveedor => !esCliente;
}

String _formatoFecha(DateTime? fecha) {
  if (fecha == null) return 'Sin fecha';

  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');

  return '$dia/$mes/${fecha.year}';
}

String _textoEnum(String value) {
  if (value.isEmpty) return 'Sin dato';

  return value.replaceAll('_', ' ').toLowerCase();
}