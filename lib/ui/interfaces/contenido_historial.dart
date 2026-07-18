import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/servicios_yastas_api_service.dart';
import '../../services/ventas_api_service.dart';
import '../../utils/config_moneda.dart';

const Color _fondoExterior = Color(0xFFE2E2E2);
const Color _fondoPagina = Color(0xFFE2E2E2);
const Color _verdeOscuro = Color(0xFF397800);
const Color _verdeTexto = Color(0xFF4E8A33);
const Color _azul = Color(0xFF0B63CE);
const Color _textoPrincipal = Color(0xFF101828);
const Color _bordeSuave = Color(0xFFD9E6D3);
const Color _grisCabeceraTabla = Color(0xFFE7E3E3);
const Color _rojo = Color(0xFFE02020);

class _TicketHistorial {
  final VentaResumen? venta;
  final List<ServicioYastasRegistrado> serviciosYastas;

  const _TicketHistorial({
    this.venta,
    this.serviciosYastas = const [],
  });

  String get folio {
    if (venta != null) {
      return venta!.folio;
    }

    final id = serviciosYastas.isEmpty
        ? 'SIN-ID'
        : serviciosYastas.first.idServicioOperacion.toString();
    return 'YASTAS-$id';
  }

  String get usuario {
    if (venta != null && venta!.usuario.isNotEmpty) {
      return venta!.usuario;
    }

    if (serviciosYastas.isNotEmpty) {
      return serviciosYastas.first.usuario;
    }

    return '';
  }

  DateTime? get fecha {
    return venta?.fecha ??
        (serviciosYastas.isEmpty ? null : serviciosYastas.first.fecha);
  }

  String get estatus {
    if (venta != null) {
      return venta!.estatus;
    }

    if (serviciosYastas.isEmpty) {
      return '';
    }

    final estatusServicios =
        serviciosYastas.map((item) => item.estatus).toSet();
    if (estatusServicios.length == 1) {
      return estatusServicios.first;
    }

    return 'MIXTO';
  }

  bool get esMixto => venta != null && serviciosYastas.isNotEmpty;

  String get titulo {
    if (venta != null && serviciosYastas.isNotEmpty) {
      return 'Venta + Yastas';
    }

    if (serviciosYastas.isNotEmpty) {
      return 'Servicio Yastas';
    }

    return 'Venta de mostrador';
  }

  double get total {
    return totalProductos + totalYastas;
  }

  double get totalProductos => venta?.total ?? 0;

  double get totalYastas {
    return serviciosYastas.fold<double>(
      0,
      (total, servicio) => total + servicio.totalCobradoCliente,
    );
  }
}

class _DetalleTicketHistorial {
  final _TicketHistorial ticket;
  final VentaDetalleCompleta venta;

  const _DetalleTicketHistorial({
    required this.ticket,
    required this.venta,
  });
}

class ContenidoHistorial extends StatefulWidget {
  const ContenidoHistorial({super.key});

  @override
  State<ContenidoHistorial> createState() => _ContenidoHistorialState();
}

class _ContenidoHistorialState extends State<ContenidoHistorial> {
  final VentasApiService _ventasApiService = VentasApiService();
  final ServiciosYastasApiService _serviciosYastasApiService =
      ServiciosYastasApiService();
  final TextEditingController _busquedaController = TextEditingController();

  String _periodoSeleccionado = 'Hoy';
  String _estatusSeleccionado = 'Todos';
  bool _cargando = true;
  String? _error;
  List<_TicketHistorial> _tickets = [];

  @override
  void initState() {
    super.initState();
    _cargarVentas();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  List<_TicketHistorial> get _ventasFiltradas {
    final texto = _busquedaController.text.trim().toLowerCase();
    final ahora = DateTime.now();

    return _tickets.where((ticket) {
      final fecha = ticket.fecha;

      final coincidePeriodo = switch (_periodoSeleccionado) {
        'Hoy' => fecha != null &&
            fecha.year == ahora.year &&
            fecha.month == ahora.month &&
            fecha.day == ahora.day,
        'Semana' => fecha != null &&
            fecha.isAfter(ahora.subtract(const Duration(days: 7))),
        'Mes' => fecha != null &&
            fecha.year == ahora.year &&
            fecha.month == ahora.month,
        _ => true,
      };

      final coincideEstatus = _estatusSeleccionado == 'Todos' ||
          (_estatusSeleccionado == 'MIXTO' && ticket.esMixto) ||
          ticket.estatus == _estatusSeleccionado;

      final coincideTexto = texto.isEmpty ||
          ticket.folio.toLowerCase().contains(texto) ||
          ticket.usuario.toLowerCase().contains(texto) ||
          ticket.estatus.toLowerCase().contains(texto) ||
          ticket.titulo.toLowerCase().contains(texto);

      return coincidePeriodo && coincideEstatus && coincideTexto;
    }).toList();
  }

  double get _totalFiltrado {
    return _ventasFiltradas.fold<double>(
      0,
      (total, venta) => total + venta.total,
    );
  }

  Future<void> _cargarVentas() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final ventasFuture = _ventasApiService.listarVentas(limite: 300);
      final yastasFuture = _serviciosYastasApiService.listarServicios(
        limite: 300,
      );
      final ventas = await ventasFuture;
      final serviciosYastas = await yastasFuture;
      final tickets = _construirTickets(ventas, serviciosYastas);

      if (!mounted) {
        return;
      }

      setState(() {
        _tickets = tickets;
        _cargando = false;
      });
    } on ApiException catch (error) {
      _mostrarError(error.message);
    } catch (_) {
      _mostrarError('No se pudo cargar el historial');
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

  List<_TicketHistorial> _construirTickets(
    List<VentaResumen> ventas,
    List<ServicioYastasRegistrado> serviciosYastas,
  ) {
    final serviciosPorFolio = <String, List<ServicioYastasRegistrado>>{};
    final serviciosSinFolio = <ServicioYastasRegistrado>[];

    for (final servicio in serviciosYastas) {
      final folio = _folioVentaDesdeObservaciones(servicio.observaciones);

      if (folio == null) {
        serviciosSinFolio.add(servicio);
        continue;
      }

      serviciosPorFolio.putIfAbsent(folio, () => []).add(servicio);
    }

    final consumidosSinFolio = <int>{};
    final tickets = <_TicketHistorial>[];

    for (final venta in ventas) {
      final servicios = <ServicioYastasRegistrado>[
        ...serviciosPorFolio.remove(venta.folio) ?? [],
        ..._serviciosCercanosAVenta(
          venta,
          serviciosSinFolio,
          consumidosSinFolio,
        ),
      ];

      tickets.add(_TicketHistorial(venta: venta, serviciosYastas: servicios));
    }

    for (final servicios in serviciosPorFolio.values) {
      for (final servicio in servicios) {
        tickets.add(_TicketHistorial(serviciosYastas: [servicio]));
      }
    }

    for (final servicio in serviciosSinFolio) {
      if (!consumidosSinFolio.contains(servicio.idServicioOperacion)) {
        tickets.add(_TicketHistorial(serviciosYastas: [servicio]));
      }
    }

    tickets.sort((a, b) {
      final fechaA = a.fecha;
      final fechaB = b.fecha;

      if (fechaA == null && fechaB == null) return 0;
      if (fechaA == null) return 1;
      if (fechaB == null) return -1;

      return fechaB.compareTo(fechaA);
    });

    return tickets;
  }

  String? _folioVentaDesdeObservaciones(String observaciones) {
    final match = RegExp(r'\[VENTA_FOLIO:([^\]]+)\]').firstMatch(
      observaciones,
    );

    return match?.group(1);
  }

  List<ServicioYastasRegistrado> _serviciosCercanosAVenta(
    VentaResumen venta,
    List<ServicioYastasRegistrado> servicios,
    Set<int> consumidos,
  ) {
    final fechaVenta = venta.fecha;

    if (fechaVenta == null) {
      return [];
    }

    final encontrados = <ServicioYastasRegistrado>[];

    for (final servicio in servicios) {
      if (consumidos.contains(servicio.idServicioOperacion)) {
        continue;
      }

      final fechaServicio = servicio.fecha;

      if (fechaServicio == null) {
        continue;
      }

      final mismoUsuario = venta.usuario.trim().toLowerCase() ==
          servicio.usuario.trim().toLowerCase();
      final diferencia = fechaServicio.difference(fechaVenta).inSeconds.abs();

      if (mismoUsuario && diferencia <= 120) {
        consumidos.add(servicio.idServicioOperacion);
        encontrados.add(servicio);
      }
    }

    return encontrados;
  }

  Future<_DetalleTicketHistorial> _cargarDetalleTicket(
    _TicketHistorial ticket,
  ) async {
    final venta = await _ventasApiService.obtenerVenta(ticket.venta!.idVenta);
    final serviciosYastas = await _serviciosYastasApiService.listarServicios(
      limite: 500,
    );
    final ventaActualizada = VentaResumen(
      idVenta: venta.idVenta,
      folio: venta.folio,
      usuario: venta.usuario,
      fecha: venta.fecha,
      total: venta.total,
      estatus: venta.estatus,
    );
    final tickets = _construirTickets([ventaActualizada], serviciosYastas);
    final ticketActualizado = tickets.firstWhere(
      (item) => item.venta?.idVenta == venta.idVenta,
      orElse: () => _TicketHistorial(
        venta: ventaActualizada,
        serviciosYastas: ticket.serviciosYastas,
      ),
    );

    return _DetalleTicketHistorial(
      ticket: ticketActualizado,
      venta: venta,
    );
  }

  void _mostrarDetalle(_TicketHistorial venta) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return _DialogoDetalleVenta(
          ticket: venta,
          future: venta.venta == null ? null : _cargarDetalleTicket(venta),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _fondoExterior,
      child: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            color: _fondoPagina,
            padding: const EdgeInsets.fromLTRB(26, 38, 26, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _EncabezadoHistorial(
                  periodoSeleccionado: _periodoSeleccionado,
                  onPeriodoSeleccionado: (periodo) {
                    setState(() {
                      _periodoSeleccionado = periodo;
                    });
                  },
                  onRefrescar: _cargarVentas,
                ),
                const SizedBox(height: 34),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _PanelFiltros(
                        estatusSeleccionado: _estatusSeleccionado,
                        busquedaController: _busquedaController,
                        onEstatusChanged: (valor) {
                          if (valor == null) return;

                          setState(() {
                            _estatusSeleccionado = valor;
                          });
                        },
                        onAplicarFiltros: () {
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    _TarjetaTotalTurno(
                      total: _totalFiltrado,
                      cantidadVentas: _ventasFiltradas.length,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                if (_cargando)
                  const _EstadoHistorial(mensaje: 'Cargando historial...')
                else if (_error != null)
                  _EstadoHistorial(
                    mensaje: _error!,
                    onReintentar: _cargarVentas,
                  )
                else if (_ventasFiltradas.isEmpty)
                  const _EstadoHistorial(mensaje: 'No hay ventas para mostrar')
                else
                  _TablaHistorialVentas(
                    ventas: _ventasFiltradas,
                    onVerDetalle: _mostrarDetalle,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EncabezadoHistorial extends StatelessWidget {
  final String periodoSeleccionado;
  final ValueChanged<String> onPeriodoSeleccionado;
  final VoidCallback onRefrescar;

  const _EncabezadoHistorial({
    required this.periodoSeleccionado,
    required this.onPeriodoSeleccionado,
    required this.onRefrescar,
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
                'Historial de Ventas',
                style: TextStyle(
                  color: _textoPrincipal,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Visualiza y gestiona el registro de transacciones recientes.',
                style: TextStyle(
                  color: Color(0xFF214025),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        _SelectorPeriodo(
          periodoSeleccionado: periodoSeleccionado,
          onPeriodoSeleccionado: onPeriodoSeleccionado,
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 32,
          child: ElevatedButton.icon(
            onPressed: onRefrescar,
            icon: const Icon(
              Icons.refresh,
              size: 15,
              color: Colors.white,
            ),
            label: const Text(
              'Actualizar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _verdeOscuro,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectorPeriodo extends StatelessWidget {
  final String periodoSeleccionado;
  final ValueChanged<String> onPeriodoSeleccionado;

  const _SelectorPeriodo({
    required this.periodoSeleccionado,
    required this.onPeriodoSeleccionado,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFECEAEA),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _BotonPeriodo(
            texto: 'Hoy',
            activo: periodoSeleccionado == 'Hoy',
            onTap: () => onPeriodoSeleccionado('Hoy'),
          ),
          _BotonPeriodo(
            texto: 'Semana',
            activo: periodoSeleccionado == 'Semana',
            onTap: () => onPeriodoSeleccionado('Semana'),
          ),
          _BotonPeriodo(
            texto: 'Mes',
            activo: periodoSeleccionado == 'Mes',
            onTap: () => onPeriodoSeleccionado('Mes'),
          ),
        ],
      ),
    );
  }
}

class _BotonPeriodo extends StatelessWidget {
  final String texto;
  final bool activo;
  final VoidCallback onTap;

  const _BotonPeriodo({
    required this.texto,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      width: texto == 'Semana' ? 70 : 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: activo ? 2 : 0,
          backgroundColor: activo ? _azul : Colors.transparent,
          foregroundColor: activo ? Colors.white : Colors.black,
          padding: EdgeInsets.zero,
          shadowColor: Colors.black.withValues(alpha: 0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: Text(
          texto,
          style: TextStyle(
            fontSize: 11,
            fontWeight: activo ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PanelFiltros extends StatelessWidget {
  final String estatusSeleccionado;
  final TextEditingController busquedaController;
  final ValueChanged<String?> onEstatusChanged;
  final VoidCallback onAplicarFiltros;

  const _PanelFiltros({
    required this.estatusSeleccionado,
    required this.busquedaController,
    required this.onEstatusChanged,
    required this.onAplicarFiltros,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _bordeSuave),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 190,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _LabelFiltro(texto: 'ESTATUS'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 37,
                  child: DropdownButtonFormField<String>(
                    initialValue: estatusSeleccionado,
                    isExpanded: true,
                    decoration: _decoracionCampo(),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                    ),
                    style: const TextStyle(
                      color: _textoPrincipal,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                      DropdownMenuItem(value: 'PAGADA', child: Text('Pagada')),
                      DropdownMenuItem(
                        value: 'CANCELADA',
                        child: Text('Cancelada'),
                      ),
                      DropdownMenuItem(
                        value: 'REALIZADA',
                        child: Text('Realizada'),
                      ),
                      DropdownMenuItem(
                        value: 'FALLIDA',
                        child: Text('Fallida'),
                      ),
                      DropdownMenuItem(value: 'MIXTO', child: Text('Mixto')),
                    ],
                    onChanged: onEstatusChanged,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          SizedBox(
            width: 230,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _LabelFiltro(texto: 'BUSCAR'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 37,
                  child: TextField(
                    controller: busquedaController,
                    onChanged: (_) => onAplicarFiltros(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: _textoPrincipal,
                    ),
                    decoration: _decoracionCampo(
                      hintText: 'Folio, usuario o estatus',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Padding(
            padding: const EdgeInsets.only(top: 22),
            child: SizedBox(
              width: 170,
              height: 37,
              child: ElevatedButton.icon(
                onPressed: onAplicarFiltros,
                icon: const Icon(
                  Icons.filter_list,
                  size: 17,
                  color: Colors.white,
                ),
                label: const Text(
                  'Aplicar Filtros',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _azul,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoracionCampo({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF7E8790),
        fontSize: 12,
      ),
      filled: true,
      fillColor: const Color(0xFFF6F4F1),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFC6CFC0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFC6CFC0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: _verdeOscuro, width: 1.2),
      ),
    );
  }
}

class _LabelFiltro extends StatelessWidget {
  final String texto;

  const _LabelFiltro({
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        color: Color(0xFF203624),
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _TarjetaTotalTurno extends StatelessWidget {
  final double total;
  final int cantidadVentas;

  const _TarjetaTotalTurno({
    required this.total,
    required this.cantidadVentas,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 310,
      height: 122,
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FAEE),
        border: Border.all(color: _bordeSuave),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL DEL PERIODO',
            style: TextStyle(
              color: _verdeOscuro,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  ConfigMoneda.formato(total),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textoPrincipal,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '$cantidadVentas ventas',
                  style: const TextStyle(
                    color: _verdeOscuro,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Ventas del periodo seleccionado',
            style: TextStyle(
              color: Color(0xFF667085),
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _TablaHistorialVentas extends StatelessWidget {
  final List<_TicketHistorial> ventas;
  final ValueChanged<_TicketHistorial> onVerDetalle;

  const _TablaHistorialVentas({
    required this.ventas,
    required this.onVerDetalle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE1E6DA)),
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const _FilaTablaHeader(),
          for (final venta in ventas)
            _FilaVenta(
              venta: venta,
              onVerDetalle: () => onVerDetalle(venta),
            ),
        ],
      ),
    );
  }
}

class _FilaTablaHeader extends StatelessWidget {
  const _FilaTablaHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: const BoxDecoration(
        color: _grisCabeceraTabla,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(9),
        ),
      ),
      child: const Row(
        children: [
          SizedBox(width: 20),
          Expanded(flex: 30, child: _HeaderTexto('VENTA')),
          Expanded(flex: 20, child: _HeaderTexto('USUARIO')),
          Expanded(flex: 18, child: _HeaderTexto('ESTATUS')),
          Expanded(flex: 19, child: _HeaderTexto('FECHA')),
          Expanded(flex: 18, child: _HeaderTexto('TOTAL')),
          Expanded(flex: 18, child: _HeaderTexto('ACCION')),
          SizedBox(width: 12),
        ],
      ),
    );
  }
}

class _HeaderTexto extends StatelessWidget {
  final String texto;

  const _HeaderTexto(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        color: Color(0xFF747B65),
        fontSize: 13,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _FilaVenta extends StatelessWidget {
  final _TicketHistorial venta;
  final VoidCallback onVerDetalle;

  const _FilaVenta({
    required this.venta,
    required this.onVerDetalle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(0xFFE6EADC),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 20),
          Expanded(
            flex: 30,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _colorVenta(venta.estatus),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        venta.titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF56605A),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'FOLIO: ${venta.folio}',
                        style: const TextStyle(
                          color: Color(0xFF9BA0A0),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 20,
            child: Text(
              venta.usuario.isEmpty ? 'Sin usuario' : venta.usuario,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF6A736C),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 18,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _BadgeEstatus(estatus: venta.estatus),
            ),
          ),
          Expanded(
            flex: 19,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatoFecha(venta.fecha),
                  style: const TextStyle(
                    color: Color(0xFF56605A),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatoHora(venta.fecha),
                  style: const TextStyle(
                    color: Color(0xFF7A8180),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              ConfigMoneda.formato(venta.total),
              style: const TextStyle(
                color: _verdeTexto,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            flex: 18,
            child: InkWell(
              onTap: onVerDetalle,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Detalles',
                    style: TextStyle(
                      color: _azul,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.open_in_new,
                    size: 13,
                    color: _azul,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Color _colorVenta(String estatus) {
    if (estatus == 'CANCELADA') {
      return _rojo;
    }

    return _verdeTexto;
  }

  String _formatoFecha(DateTime? fecha) {
    if (fecha == null) {
      return 'Sin fecha';
    }

    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }

  String _formatoHora(DateTime? fecha) {
    if (fecha == null) {
      return '';
    }

    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$hora:$minuto';
  }
}

class _BadgeEstatus extends StatelessWidget {
  final String estatus;

  const _BadgeEstatus({
    required this.estatus,
  });

  @override
  Widget build(BuildContext context) {
    final cancelada = estatus == 'CANCELADA';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cancelada ? const Color(0xFFFFE8E8) : const Color(0xFFE8F5DD),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        estatus.isEmpty ? 'SIN ESTATUS' : estatus,
        style: TextStyle(
          color: cancelada ? _rojo : _verdeOscuro,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EstadoHistorial extends StatelessWidget {
  final String mensaje;
  final VoidCallback? onReintentar;

  const _EstadoHistorial({
    required this.mensaje,
    this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 42, bottom: 42),
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

class _DialogoDetalleVenta extends StatelessWidget {
  final _TicketHistorial ticket;
  final Future<_DetalleTicketHistorial>? future;

  const _DialogoDetalleVenta({
    required this.ticket,
    required this.future,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Detalle ${ticket.folio}'),
      content: SizedBox(
        width: 760,
        child: future == null
            ? _ContenidoDetalleTicket(ticket: ticket)
            : FutureBuilder<_DetalleTicketHistorial>(
                future: future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const SizedBox(
                      height: 180,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return SizedBox(
                      height: 180,
                      child: Center(
                        child: Text(
                          'No se pudo cargar el detalle: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _rojo,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    );
                  }

                  final detalle = snapshot.data!;
                  final venta = detalle.venta;
                  final ticketActualizado = detalle.ticket;

                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ResumenDetalleVenta(
                          venta: venta,
                          totalTicket: ticketActualizado.total,
                          totalYastas: ticketActualizado.totalYastas,
                        ),
                        const SizedBox(height: 18),
                        const _SubtituloDetalle('Productos'),
                        const SizedBox(height: 8),
                        _TablaDetalleProductos(detalles: venta.detalles),
                        const SizedBox(height: 18),
                        const _SubtituloDetalle('Pagos'),
                        const SizedBox(height: 8),
                        _TablaDetallePagos(pagos: venta.pagos),
                        if (ticketActualizado.serviciosYastas.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          const _SubtituloDetalle('Servicios Yastas'),
                          const SizedBox(height: 8),
                          _TablaDetalleYastas(
                            servicios: ticketActualizado.serviciosYastas,
                          ),
                        ],
                        if ((venta.observaciones ?? '').isNotEmpty) ...[
                          const SizedBox(height: 18),
                          const _SubtituloDetalle('Observaciones'),
                          const SizedBox(height: 6),
                          Text(
                            venta.observaciones!,
                            style: const TextStyle(
                              color: _textoPrincipal,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
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

class _ResumenDetalleVenta extends StatelessWidget {
  final VentaDetalleCompleta venta;
  final double totalTicket;
  final double totalYastas;

  const _ResumenDetalleVenta({
    required this.venta,
    required this.totalTicket,
    required this.totalYastas,
  });

  @override
  Widget build(BuildContext context) {
    final tieneYastas = totalYastas > 0.005;
    final recibidoTicket = venta.montoRecibido + totalYastas;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _DatoDetalle(label: 'Folio', value: venta.folio),
        _DatoDetalle(label: 'Usuario', value: venta.usuario),
        _DatoDetalle(label: 'Fecha', value: _formatoFechaHora(venta.fecha)),
        _DatoDetalle(label: 'Estatus', value: venta.estatus),
        _DatoDetalle(
          label: 'Total venta',
          value: ConfigMoneda.formato(totalTicket),
        ),
        _DatoDetalle(
          label: tieneYastas ? 'Productos' : 'Subtotal',
          value: ConfigMoneda.formato(venta.subtotal),
        ),
        if (tieneYastas)
          _DatoDetalle(
            label: 'Yastas',
            value: ConfigMoneda.formato(totalYastas),
          ),
        _DatoDetalle(
          label: 'Descuento',
          value: ConfigMoneda.formato(venta.descuento),
        ),
        _DatoDetalle(
          label: 'Recibido',
          value: ConfigMoneda.formato(recibidoTicket),
        ),
        _DatoDetalle(
          label: 'Cambio',
          value: ConfigMoneda.formato(venta.cambio),
        ),
      ],
    );
  }

  String _formatoFechaHora(DateTime? fecha) {
    if (fecha == null) {
      return 'Sin fecha';
    }

    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year} $hora:$minuto';
  }
}

class _ContenidoDetalleTicket extends StatelessWidget {
  final _TicketHistorial ticket;

  const _ContenidoDetalleTicket({
    required this.ticket,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _DatoDetalle(label: 'Folio', value: ticket.folio),
              _DatoDetalle(label: 'Usuario', value: ticket.usuario),
              _DatoDetalle(
                label: 'Fecha',
                value: _formatoFechaHoraTicket(ticket.fecha),
              ),
              _DatoDetalle(label: 'Estatus', value: ticket.estatus),
              _DatoDetalle(
                label: 'Total ticket',
                value: ConfigMoneda.formato(ticket.total),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _SubtituloDetalle('Servicios Yastas'),
          const SizedBox(height: 8),
          _TablaDetalleYastas(servicios: ticket.serviciosYastas),
        ],
      ),
    );
  }

  String _formatoFechaHoraTicket(DateTime? fecha) {
    if (fecha == null) {
      return 'Sin fecha';
    }

    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year} $hora:$minuto';
  }
}

class _DatoDetalle extends StatelessWidget {
  final String label;
  final String value;

  const _DatoDetalle({
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
              color: Color(0xFF667085),
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

class _SubtituloDetalle extends StatelessWidget {
  final String text;

  const _SubtituloDetalle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _textoPrincipal,
        fontSize: 15,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _TablaDetalleProductos extends StatelessWidget {
  final List<VentaProductoDetalle> detalles;

  const _TablaDetalleProductos({
    required this.detalles,
  });

  @override
  Widget build(BuildContext context) {
    if (detalles.isEmpty) {
      return const _TextoDetalleVacio('Sin productos registrados');
    }

    return Column(
      children: [
        const _FilaDetalleProductoHeader(),
        for (final detalle in detalles) _FilaDetalleProducto(detalle: detalle),
      ],
    );
  }
}

class _FilaDetalleProductoHeader extends StatelessWidget {
  const _FilaDetalleProductoHeader();

  @override
  Widget build(BuildContext context) {
    return const _FilaDetalleBase(
      color: _grisCabeceraTabla,
      children: [
        Expanded(flex: 34, child: _TextoHeaderDetalle('PRODUCTO')),
        Expanded(flex: 13, child: _TextoHeaderDetalle('LOTE')),
        Expanded(flex: 10, child: _TextoHeaderDetalle('CANT.')),
        Expanded(flex: 14, child: _TextoHeaderDetalle('PRECIO')),
        Expanded(flex: 14, child: _TextoHeaderDetalle('DESC.')),
        Expanded(flex: 15, child: _TextoHeaderDetalle('SUBTOTAL')),
      ],
    );
  }
}

class _FilaDetalleProducto extends StatelessWidget {
  final VentaProductoDetalle detalle;

  const _FilaDetalleProducto({
    required this.detalle,
  });

  @override
  Widget build(BuildContext context) {
    return _FilaDetalleBase(
      children: [
        Expanded(
          flex: 34,
          child: Text(
            detalle.producto.isEmpty ? 'Producto sin nombre' : detalle.producto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _textoFilaDetalle,
          ),
        ),
        Expanded(
          flex: 13,
          child: Text(
            detalle.codigoLote.isEmpty ? '-' : detalle.codigoLote,
            style: _textoFilaDetalle,
          ),
        ),
        Expanded(
          flex: 10,
          child: Text('${detalle.cantidad}', style: _textoFilaDetalle),
        ),
        Expanded(
          flex: 14,
          child: Text(
            ConfigMoneda.formato(detalle.precioUnitario),
            style: _textoFilaDetalle,
          ),
        ),
        Expanded(
          flex: 14,
          child: Text(
            ConfigMoneda.formato(detalle.descuento),
            style: _textoFilaDetalle,
          ),
        ),
        Expanded(
          flex: 15,
          child: Text(
            ConfigMoneda.formato(detalle.subtotal),
            style: _textoFilaDetalle,
          ),
        ),
      ],
    );
  }
}

class _TablaDetallePagos extends StatelessWidget {
  final List<VentaPagoDetalle> pagos;

  const _TablaDetallePagos({
    required this.pagos,
  });

  @override
  Widget build(BuildContext context) {
    if (pagos.isEmpty) {
      return const _TextoDetalleVacio('Sin pagos registrados');
    }

    return Column(
      children: [
        const _FilaDetalleBase(
          color: _grisCabeceraTabla,
          children: [
            Expanded(flex: 25, child: _TextoHeaderDetalle('MEDIO')),
            Expanded(flex: 25, child: _TextoHeaderDetalle('MONTO')),
            Expanded(flex: 50, child: _TextoHeaderDetalle('REFERENCIA')),
          ],
        ),
        for (final pago in pagos)
          _FilaDetalleBase(
            children: [
              Expanded(
                flex: 25,
                child: Text(pago.medio, style: _textoFilaDetalle),
              ),
              Expanded(
                flex: 25,
                child: Text(
                  ConfigMoneda.formato(pago.monto),
                  style: _textoFilaDetalle,
                ),
              ),
              Expanded(
                flex: 50,
                child: Text(
                  pago.referencia.isEmpty ? '-' : pago.referencia,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _textoFilaDetalle,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _TablaDetalleYastas extends StatelessWidget {
  final List<ServicioYastasRegistrado> servicios;

  const _TablaDetalleYastas({
    required this.servicios,
  });

  @override
  Widget build(BuildContext context) {
    if (servicios.isEmpty) {
      return const _TextoDetalleVacio('Sin servicios Yastas registrados');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ResumenYastas(servicios: servicios),
        const SizedBox(height: 10),
        for (final servicio in servicios) ...[
          _DetalleOperacionYastas(servicio: servicio),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ResumenYastas extends StatelessWidget {
  final List<ServicioYastasRegistrado> servicios;

  const _ResumenYastas({
    required this.servicios,
  });

  @override
  Widget build(BuildContext context) {
    final totalCobrado = servicios.fold<double>(
      0,
      (total, servicio) => total + servicio.totalCobradoCliente,
    );
    final totalOperado = servicios.fold<double>(
      0,
      (total, servicio) => total + servicio.montoServicio,
    );
    final comisionCliente = servicios.fold<double>(
      0,
      (total, servicio) => total + servicio.comisionCliente,
    );
    final comisionYastas = servicios.fold<double>(
      0,
      (total, servicio) => total + servicio.comisionYastas,
    );
    final regaliaYastas = servicios.fold<double>(
      0,
      (total, servicio) => total + servicio.regaliaYastas,
    );
    final gananciaFarmacia = servicios.fold<double>(
      0,
      (total, servicio) => total + servicio.gananciaFarmacia,
    );

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _DatoDetalle(
          label: 'Total cobrado',
          value: ConfigMoneda.formato(totalCobrado),
        ),
        _DatoDetalle(
          label: 'Operado',
          value: ConfigMoneda.formato(totalOperado),
        ),
        _DatoDetalle(
          label: 'Comision cliente',
          value: ConfigMoneda.formato(comisionCliente),
        ),
        _DatoDetalle(
          label: 'Comision Yastas',
          value: ConfigMoneda.formato(comisionYastas),
        ),
        _DatoDetalle(
          label: 'Regalia Yastas',
          value: ConfigMoneda.formato(regaliaYastas),
        ),
        _DatoDetalle(
          label: 'Ganancia farmacia',
          value: ConfigMoneda.formato(gananciaFarmacia),
        ),
      ],
    );
  }
}

class _DetalleOperacionYastas extends StatelessWidget {
  final ServicioYastasRegistrado servicio;

  const _DetalleOperacionYastas({
    required this.servicio,
  });

  @override
  Widget build(BuildContext context) {
    final distribuido = servicio.montoServicio +
        servicio.comisionYastas +
        servicio.regaliaYastas +
        servicio.gananciaFarmacia;
    final diferencia = servicio.totalCobradoCliente - distribuido;
    final observaciones = _observacionesLimpias(servicio.observaciones);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _bordeSuave),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _nombreServicio,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textoPrincipal,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _BadgeEstatus(estatus: servicio.estatus),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DatoDetalle(
                label: 'Referencia',
                value: servicio.referenciaOperacion.isEmpty
                    ? '-'
                    : servicio.referenciaOperacion,
              ),
              _DatoDetalle(
                label: 'Fecha',
                value: _formatoFechaHora(servicio.fecha),
              ),
              _DatoDetalle(
                label: 'Total cobrado',
                value: ConfigMoneda.formato(servicio.totalCobradoCliente),
              ),
              _DatoDetalle(
                label: 'Operacion',
                value: ConfigMoneda.formato(servicio.montoServicio),
              ),
              _DatoDetalle(
                label: 'Comision cliente',
                value: ConfigMoneda.formato(servicio.comisionCliente),
              ),
              _DatoDetalle(
                label: 'Comision Yastas',
                value: ConfigMoneda.formato(servicio.comisionYastas),
              ),
              _DatoDetalle(
                label: 'Regalia Yastas',
                value: ConfigMoneda.formato(servicio.regaliaYastas),
              ),
              _DatoDetalle(
                label: 'Ganancia farmacia',
                value: ConfigMoneda.formato(servicio.gananciaFarmacia),
              ),
              if (diferencia.abs() > 0.005)
                _DatoDetalle(
                  label: 'No clasificado',
                  value: ConfigMoneda.formato(diferencia),
                ),
            ],
          ),
          if (observaciones.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Observaciones: $observaciones',
              style: const TextStyle(
                color: Color(0xFF667085),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String get _nombreServicio {
    if (servicio.nombreServicio.isNotEmpty) {
      return servicio.nombreServicio;
    }

    if (servicio.tipoServicio.isNotEmpty) {
      return servicio.tipoServicio;
    }

    return 'Servicio Yastas';
  }

  String _formatoFechaHora(DateTime? fecha) {
    if (fecha == null) {
      return 'Sin fecha';
    }

    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year} $hora:$minuto';
  }

  String _observacionesLimpias(String observaciones) {
    return observaciones
        .replaceAll(RegExp(r'\[VENTA_FOLIO:[^\]]+\]\s*'), '')
        .trim();
  }
}

class _FilaDetalleBase extends StatelessWidget {
  final Color? color;
  final List<Widget> children;

  const _FilaDetalleBase({
    this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 38),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE6EADC)),
        ),
      ),
      child: Row(children: children),
    );
  }
}

class _TextoHeaderDetalle extends StatelessWidget {
  final String text;

  const _TextoHeaderDetalle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF747B65),
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _TextoDetalleVacio extends StatelessWidget {
  final String text;

  const _TextoDetalleVacio(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F4F1),
        border: Border.all(color: _bordeSuave),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF667085),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

const TextStyle _textoFilaDetalle = TextStyle(
  color: _textoPrincipal,
  fontSize: 12,
  fontWeight: FontWeight.w700,
);
