import 'package:flutter/material.dart';

import 'models/medicamento.dart';
import 'models/usuario.dart';
import 'services/api_client.dart';
import 'services/inventario_api_service.dart';
import 'services/session_service.dart';
import 'services/ticket_service.dart';
import 'services/servicios_yastas_api_service.dart';
import 'services/ventas_api_service.dart';
import 'ui/interfaces/barra_lateral_izquierda.dart';
import 'ui/interfaces/contenido_cajero.dart';
import 'ui/interfaces/contenido_catalogo_inventario.dart';
import 'ui/interfaces/contenido_catalogo_producto.dart';
import 'ui/interfaces/contenido_historial.dart';
import 'ui/interfaces/contenido_pedidos.dart';
import 'ui/interfaces/contenido_proveedores.dart';
import 'ui/interfaces/contenido_usuarios.dart';
import 'ui/interfaces/contenido_venta.dart';
import 'ui/interfaces/contenido_yastas.dart';
import 'ui/interfaces/menu_carta_carrito.dart';
import 'ui/interfaces/menu_carta_venta_yastas.dart';
import 'ui/interfaces/menu_superior_catalogo.dart';
import 'ui/login/login_screen.dart';
import 'ui/interfaces/contenido_devolucion.dart';

const Color _fondoApp = Color(0xFF181A20);
const Color _fondoContenido = Color(0xFFE2E2E2);
const Color _verde = Color(0xFF58D000);

void main() {
  runApp(const AngelesurApp());
}

class AngelesurApp extends StatefulWidget {
  const AngelesurApp({super.key});

  @override
  State<AngelesurApp> createState() => _AngelesurAppState();
}

class _AngelesurAppState extends State<AngelesurApp> {
  final SessionService _sessionService = SessionService();

  Usuario? _usuario;
  bool _cargandoSesion = true;

  @override
  void initState() {
    super.initState();
    _restaurarSesion();
  }

  Future<void> _restaurarSesion() async {
    final usuario = await _sessionService.cargarUsuario();

    if (!mounted) {
      return;
    }

    setState(() {
      _usuario = usuario;
      _cargandoSesion = false;
    });
  }

  Future<void> _iniciarSesion(Usuario usuario) async {
    await _sessionService.guardarUsuario(usuario);

    if (!mounted) {
      return;
    }

    setState(() {
      _usuario = usuario;
    });
  }

  Future<void> _cerrarSesion() async {
    await _sessionService.cerrarSesion();

    if (!mounted) {
      return;
    }

    setState(() {
      _usuario = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Angelesur',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(
          seedColor: _verde,
          brightness: Brightness.light,
        ),
      ),
      home: _cargandoSesion
          ? const _PantallaCargandoSesion()
          : _usuario == null
              ? LoginScreen(
                  onLogin: _iniciarSesion,
                )
              : VentaPrincipalScreen(
                  usuario: _usuario!,
                  onLogout: _cerrarSesion,
                ),
    );
  }
}

class _PantallaCargandoSesion extends StatelessWidget {
  const _PantallaCargandoSesion();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _fondoApp,
      body: Center(
        child: CircularProgressIndicator(color: _verde),
      ),
    );
  }
}

class VentaPrincipalScreen extends StatefulWidget {
  final Usuario usuario;
  final VoidCallback onLogout;

  const VentaPrincipalScreen({
    super.key,
    required this.usuario,
    required this.onLogout,
  });

  @override
  State<VentaPrincipalScreen> createState() =>
      _VentaPrincipalScreenState();
}

class _VentaPrincipalScreenState
    extends State<VentaPrincipalScreen> {
  final InventarioApiService _inventarioApiService =
      InventarioApiService();

  final VentasApiService _ventasApiService =
      VentasApiService();

  final TicketService _ticketService =
      const TicketService();

  final ServiciosYastasApiService _serviciosYastasApiService =
      ServiciosYastasApiService();

  final TextEditingController _busquedaController =
      TextEditingController();

  int _menuSeleccionado = 1;
  int _submenuCatalogoSeleccionado = 0;
  bool _cargandoInventario = true;
  bool _procesandoVenta = false;
  String? _errorInventario;

  List<Medicamento> _medicamentos = [];
  final Map<int, int> _carrito = {};
  final Map<int, ServicioYastasCarrito>
      _serviciosYastasCarrito = {};

  int _siguienteIdYastasCarrito = -100000;

  @override
  void initState() {
    super.initState();

    _busquedaController.addListener(() {
      setState(() {});
    });

    _cargarInventario();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  List<Medicamento> get _medicamentosFiltrados {
    final texto =
        _busquedaController.text.trim().toLowerCase();

    if (texto.isEmpty) {
      return _medicamentos;
    }

    return _medicamentos.where((medicamento) {
      return medicamento.nombre
              .toLowerCase()
              .contains(texto) ||
          medicamento.detalle
              .toLowerCase()
              .contains(texto) ||
          medicamento.categoria
              .toLowerCase()
              .contains(texto);
    }).toList();
  }

  List<Medicamento> get _productosDisponiblesParaCarrito {
    return [
      ..._medicamentos,
      ..._serviciosYastasCarrito.values.map(
        (item) => item.medicamento,
      ),
    ];
  }

  Medicamento? _productoCarritoPorId(int id) {
    for (final producto
        in _productosDisponiblesParaCarrito) {
      if (producto.id == id) {
        return producto;
      }
    }

    return null;
  }

  List<Medicamento> get _itemsCarrito {
    return _carrito.keys
        .map(_productoCarritoPorId)
        .whereType<Medicamento>()
        .toList();
  }

  bool get _carritoTieneYastas =>
      _serviciosYastasCarrito.isNotEmpty;

  List<Medicamento> get _itemsProductosCarrito {
    return _carrito.keys
        .where(
          (id) =>
              !_serviciosYastasCarrito.containsKey(id),
        )
        .map(_productoCarritoPorId)
        .whereType<Medicamento>()
        .toList();
  }

  double get _subtotalProductos {
    double total = 0;

    for (final item in _itemsProductosCarrito) {
      total +=
          item.precio * (_carrito[item.id] ?? 0);
    }

    return total;
  }

  double get _subtotal {
    double total = 0;

    for (final item in _carrito.entries) {
      final producto =
          _productoCarritoPorId(item.key);

      if (producto == null) {
        continue;
      }

      total += producto.precio * item.value;
    }

    return total;
  }

  double get _descuento => 0;

  double get _total {
    final total = _subtotal - _descuento;
    return total < 0 ? 0 : total;
  }

  Future<void> _cargarInventario() async {
    setState(() {
      _cargandoInventario = true;
      _errorInventario = null;
    });

    try {
      final medicamentos =
          await _inventarioApiService.listarDisponibles();

      if (!mounted) {
        return;
      }

      setState(() {
        _medicamentos = medicamentos;

        _carrito.removeWhere((id, _) {
          return _productoCarritoPorId(id) == null;
        });

        _cargandoInventario = false;
      });
    } on ApiException catch (error) {
      _mostrarErrorInventario(error.message);
    } catch (_) {
      _mostrarErrorInventario(
        'No se pudo conectar con la API local',
      );
    }
  }

  void _mostrarErrorInventario(String mensaje) {
    if (!mounted) {
      return;
    }

    setState(() {
      _errorInventario = mensaje;
      _cargandoInventario = false;
    });
  }

  void _agregarAlCarrito(Medicamento producto) {
    final cantidadActual =
        _carrito[producto.id] ?? 0;

    if (cantidadActual >= producto.stock) {
      return;
    }

    setState(() {
      _carrito[producto.id] =
          cantidadActual + 1;
    });
  }

  Future<void> _agregarServicioYastas(
    TarifaServicioYastas tarifa,
  ) async {
    final datos =
        await showDialog<DatosServicioYastas>(
      context: context,
      builder: (context) => DialogoServicioYastas(
        tarifa: tarifa,
      ),
    );

    if (datos == null) {
      return;
    }

    final idCarrito =
        _siguienteIdYastasCarrito--;

    final servicio = ServicioYastasCarrito(
      idCarrito: idCarrito,
      tarifa: tarifa,
      montoServicio: datos.montoServicio,
      referenciaOperacion:
          datos.referenciaOperacion,
      observaciones: datos.observaciones,
    );

    setState(() {
      _serviciosYastasCarrito[idCarrito] =
          servicio;

      _carrito[idCarrito] = 1;
    });
  }

  void _incrementarCantidad(int productoId) {
    final producto =
        _productoCarritoPorId(productoId);

    if (producto == null) {
      return;
    }

    final cantidadActual =
        _carrito[productoId] ?? 0;

    if (cantidadActual >= producto.stock) {
      return;
    }

    setState(() {
      _carrito[productoId] =
          cantidadActual + 1;
    });
  }

  void _disminuirCantidad(int productoId) {
    setState(() {
      final cantidadActual =
          _carrito[productoId] ?? 0;

      if (cantidadActual <= 1) {
        _carrito.remove(productoId);

        _serviciosYastasCarrito.remove(
          productoId,
        );
      } else {
        _carrito[productoId] =
            cantidadActual - 1;
      }
    });
  }

  void _eliminarDelCarrito(int productoId) {
    setState(() {
      _carrito.remove(productoId);

      _serviciosYastasCarrito.remove(
        productoId,
      );
    });
  }

  Future<void> _pagarVenta() async {
    if (_carrito.isEmpty || _procesandoVenta) {
      return;
    }

    if (_carritoTieneYastas &&
        widget.usuario.rol != 'JEFE') {
      _mostrarErrorVenta(
        'Solo un usuario JEFE puede registrar '
        'servicios Yastas.',
      );

      return;
    }

    final datosPago =
        await mostrarDialogoPagoVenta(
      context: context,
      total: _total,
    );

    if (datosPago == null) {
      return;
    }

    if (_carritoTieneYastas &&
        datosPago.medio != 'EFECTIVO') {
      _mostrarErrorVenta(
        'Los tickets con servicios Yastas '
        'deben cobrarse en efectivo.',
      );

      return;
    }

    /*
     * Se conservan los datos actuales antes de registrar
     * la venta. Estos datos se utilizarán para imprimir
     * después de que la API confirme la operación.
     */
    final productosParaTicket =
        List<Medicamento>.from(
      _itemsCarrito,
    );

    final cantidadesParaTicket =
        Map<int, int>.from(
      _carrito,
    );

    final subtotalParaTicket = _subtotal;
    final descuentoParaTicket = _descuento;
    final totalParaTicket = _total;

    final montoRecibidoParaTicket =
        datosPago.montoRecibido ??
            totalParaTicket;

    final fechaTicket = DateTime.now();

    setState(() {
      _procesandoVenta = true;
    });

    try {
      VentaRegistrada? venta;

      /*
       * Los productos normales se registran en la tabla
       * de ventas. Los servicios Yastas se registran
       * mediante su servicio correspondiente.
       */
      if (_itemsProductosCarrito.isNotEmpty) {
        final totalYastas =
            _total - _subtotalProductos;

        final montoRecibidoProductos =
            datosPago.montoRecibido == null
                ? null
                : datosPago.montoRecibido! -
                            totalYastas <
                        _subtotalProductos
                    ? _subtotalProductos
                    : datosPago.montoRecibido! -
                        totalYastas;

        venta =
            await _ventasApiService.registrarVenta(
          idUsuario: widget.usuario.id,
          medicamentos:
              _itemsProductosCarrito,
          cantidades:
              Map<int, int>.from(_carrito),
          descuentoGeneral: _descuento,
          medioPago: datosPago.medio,
          total: _subtotalProductos,
          montoRecibido:
              datosPago.medio == 'EFECTIVO'
                  ? montoRecibidoProductos
                  : null,
          referencia: datosPago.referencia,
          observaciones: _carritoTieneYastas
              ? 'Ticket mixto con servicios Yastas.'
              : null,
        );
      }

      final serviciosRegistrados =
          await _registrarServiciosYastasEnCarrito(
        folioVenta: venta?.folio,
      );

      String? errorImpresion;

      /*
       * La impresión se realiza después de que la venta
       * y los servicios Yastas quedaron registrados.
       */
      if (datosPago.imprimirTicket) {
        try {
          final cambioTicket =
              datosPago.medio == 'EFECTIVO'
                  ? montoRecibidoParaTicket -
                      totalParaTicket
                  : 0.0;

          final ticket = TicketVenta(
            folio:
                venta?.folio ??
                    'SERVICIO-YASTAS',
            fecha: fechaTicket,
            cajero: widget.usuario.nombre,
            productos:
                productosParaTicket.map(
              (producto) {
                final cantidad =
                    cantidadesParaTicket[
                            producto.id] ??
                        0;

                final esYastas =
                    producto.categoria
                            .trim()
                            .toLowerCase() ==
                        'yastas';

                final detalle =
                    producto.detalle.trim();

                return TicketProducto(
                  nombre:
                      esYastas &&
                              detalle.isNotEmpty
                          ? '${producto.nombre} - '
                              '$detalle'
                          : producto.nombre,
                  cantidad: cantidad,
                  precioUnitario:
                      producto.precio,
                  descuento: 0,
                  subtotal:
                      producto.precio *
                          cantidad,
                );
              },
            ).toList(),
            subtotal: subtotalParaTicket,
            descuento: descuentoParaTicket,
            total: totalParaTicket,
            montoRecibido:
                montoRecibidoParaTicket,
            cambio: cambioTicket > 0
                ? cambioTicket
                : 0,
            metodoPago: datosPago.medio,
            referencia:
                datosPago.referencia,
          );

          await _ticketService
              .imprimirTicketVenta(
            ticket,
          );
        } on TicketServiceException catch (error) {
          errorImpresion = error.mensaje;
        } catch (error) {
          errorImpresion =
              'Ocurrió un error inesperado '
              'al imprimir: $error';
        }
      }

      if (!mounted) {
        return;
      }

      /*
       * La operación ya quedó registrada.
       * El carrito se limpia incluso si la impresora falla.
       */
      setState(() {
        _carrito.clear();

        _serviciosYastasCarrito.clear();

        _procesandoVenta = false;
      });

      if (venta != null) {
        await _cargarInventario();
      }

      if (!mounted) {
        return;
      }

      final mensajeRegistro =
          _mensajeVentaRegistrada(
        venta,
        serviciosRegistrados,
      );

      final String mensajeFinal;

      if (errorImpresion != null) {
        mensajeFinal =
            '$mensajeRegistro '
            'No se pudo imprimir el ticket. '
            '$errorImpresion';
      } else if (datosPago.imprimirTicket) {
        mensajeFinal =
            '$mensajeRegistro '
            'Ticket impreso correctamente.';
      } else {
        mensajeFinal = mensajeRegistro;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensajeFinal),
          duration: Duration(
            seconds:
                errorImpresion == null
                    ? 4
                    : 7,
          ),
        ),
      );
    } on ApiException catch (error) {
      _mostrarErrorVenta(error.message);
    } catch (_) {
      _mostrarErrorVenta(
        'No se pudo registrar la venta',
      );
    }
  }

  Future<List<ServicioYastasRegistrado>>
      _registrarServiciosYastasEnCarrito({
    String? folioVenta,
  }) async {
    final registrados =
        <ServicioYastasRegistrado>[];

    for (final servicio
        in _serviciosYastasCarrito.values) {
      final registrado =
          await _serviciosYastasApiService
              .registrarServicio(
        idUsuario: widget.usuario.id,
        idTarifa:
            servicio.tarifa.idTarifa,
        montoServicio:
            servicio.montoServicio,
        referenciaOperacion:
            servicio.referenciaOperacion,
        observaciones:
            _observacionesYastas(
          servicio.observaciones,
          folioVenta,
        ),
      );

      registrados.add(registrado);
    }

    return registrados;
  }

  String? _observacionesYastas(
    String? observaciones,
    String? folioVenta,
  ) {
    final partes = <String>[
      if (folioVenta != null &&
          folioVenta.isNotEmpty)
        '[VENTA_FOLIO:$folioVenta]',
      if (observaciones != null &&
          observaciones.trim().isNotEmpty)
        observaciones.trim(),
    ];

    if (partes.isEmpty) {
      return null;
    }

    return partes.join(' ');
  }

  String _mensajeVentaRegistrada(
    VentaRegistrada? venta,
    List<ServicioYastasRegistrado> servicios,
  ) {
    if (venta != null &&
        servicios.isNotEmpty) {
      return 'Ticket registrado: '
          'venta ${venta.folio} y '
          '${servicios.length} '
          'servicio(s) Yastas.';
    }

    if (venta != null) {
      return 'Venta ${venta.folio} registrada.';
    }

    if (servicios.length == 1) {
      return 'Servicio Yastas registrado.';
    }

    return '${servicios.length} '
        'servicios Yastas registrados.';
  }

  void _mostrarErrorVenta(String mensaje) {
    if (!mounted) {
      return;
    }

    setState(() {
      _procesandoVenta = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
      ),
    );
  }

  Widget _construirContenidoCatalogo() {
    switch (_submenuCatalogoSeleccionado) {
      case 0:
        return ContenidoCatalogoInventario();

      case 1:
        return ContenidoCatalogoProducto();

      default:
        return ContenidoCatalogoInventario();
    }
  }

  Widget _construirContenidoVenta() {
    if (_cargandoInventario ||
        _errorInventario != null) {
      return _EstadoInventario(
        cargando: _cargandoInventario,
        error: _errorInventario,
        onReintentar: _cargarInventario,
      );
    }

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ContenidoVenta(
            busquedaController:
                _busquedaController,
            medicamentos:
                _medicamentosFiltrados,
            onAgregar:
                _agregarAlCarrito,
            onAgregarYastas:
                _agregarServicioYastas,
          ),
        ),
        MenuCartaCarrito(
          medicamentos: _itemsCarrito,
          cantidades: _carrito,
          subtotal: _subtotal,
          descuento: _descuento,
          total: _total,
          onIncrementar:
              _incrementarCantidad,
          onDisminuir:
              _disminuirCantidad,
          onEliminar:
              _eliminarDelCarrito,
          onPagar: _pagarVenta,
          procesandoPago:
              _procesandoVenta,
        ),
      ],
    );
  }

  Widget _construirContenidoSeleccionado() {
    switch (_menuSeleccionado) {
      case 0:
        return ContenidoUsuarios(
          usuario: widget.usuario,
        );

      case 1:
        return _construirContenidoVenta();

      case 2:
        return ContenidoHistorial();

      case 3:
        return ContenidoPedidos(
          usuario: widget.usuario,
        );

      case 4:
        return Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            MenuSuperiorCatalogo(
              indiceSeleccionado:
                  _submenuCatalogoSeleccionado,
              onSeleccionar: (index) {
                setState(() {
                  _submenuCatalogoSeleccionado =
                      index;
                });
              },
            ),
            Expanded(
              child:
                  _construirContenidoCatalogo(),
            ),
          ],
        );

      case 5:
        return ContenidoCajero(
          usuario: widget.usuario,
        );

      case 6:
        return const ContenidoProveedores();

      case 7:
        return ContenidoDevolucion(
          usuario: widget.usuario,
        );

      case 8:
        return const ContenidoYastas();

      default:
        return const _InterfazNoEncontrada();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondoApp,
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(8),
          child: Container(
            color: _fondoContenido,
            child: Row(
              children: [
                BarraLateralIzquierda(
                  seleccionado:
                      _menuSeleccionado,
                  onLogout:
                      widget.onLogout,
                  onSeleccionar: (index) {
                    setState(() {
                      _menuSeleccionado =
                          index;
                    });
                  },
                ),
                Expanded(
                  child:
                      _construirContenidoSeleccionado(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EstadoInventario
    extends StatelessWidget {
  final bool cargando;
  final String? error;
  final VoidCallback onReintentar;

  const _EstadoInventario({
    required this.cargando,
    required this.error,
    required this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Center(
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Text(
            error ??
                'No hay inventario disponible',
            style: const TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
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
      ),
    );
  }
}

class _InterfazNoEncontrada
    extends StatelessWidget {
  const _InterfazNoEncontrada();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Interfaz no encontrada',
        style: TextStyle(
          fontSize: 28,
          fontWeight:
              FontWeight.w700,
        ),
      ),
    );
  }
}