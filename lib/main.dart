import 'package:flutter/material.dart';

import 'models/medicamento.dart';
import 'models/usuario.dart';
import 'services/api_client.dart';
import 'services/inventario_api_service.dart';
import 'services/session_service.dart';
import 'services/servicios_yastas_api_service.dart';
import 'services/ventas_api_service.dart';
import 'ui/interfaces/barra_lateral_izquierda.dart';
import 'ui/interfaces/contenido_cajero.dart';
import 'ui/interfaces/contenido_catalogo_inventario.dart';
import 'ui/interfaces/contenido_catalogo_producto.dart';
import 'ui/interfaces/contenido_historial.dart';
import 'ui/interfaces/contenido_pedidos.dart';
import 'ui/interfaces/contenido_perfil.dart';
import 'ui/interfaces/contenido_proveedores.dart';
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
  State<VentaPrincipalScreen> createState() => _VentaPrincipalScreenState();
}

class _VentaPrincipalScreenState extends State<VentaPrincipalScreen> {
  final InventarioApiService _inventarioApiService = InventarioApiService();
  final VentasApiService _ventasApiService = VentasApiService();
  final ServiciosYastasApiService _serviciosYastasApiService =
      ServiciosYastasApiService();
  final TextEditingController _busquedaController = TextEditingController();

  int _menuSeleccionado = 1;
  int _submenuCatalogoSeleccionado = 0;
  bool _cargandoInventario = true;
  bool _procesandoVenta = false;
  String? _errorInventario;

  List<Medicamento> _medicamentos = [];
  final Map<int, int> _carrito = {};
  final Map<int, ServicioYastasCarrito> _serviciosYastasCarrito = {};
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
    final texto = _busquedaController.text.trim().toLowerCase();

    if (texto.isEmpty) {
      return _medicamentos;
    }

    return _medicamentos.where((medicamento) {
      return medicamento.nombre.toLowerCase().contains(texto) ||
          medicamento.detalle.toLowerCase().contains(texto) ||
          medicamento.categoria.toLowerCase().contains(texto);
    }).toList();
  }

  List<Medicamento> get _productosDisponiblesParaCarrito {
    return [
      ..._medicamentos,
      ..._serviciosYastasCarrito.values.map((item) => item.medicamento),
    ];
  }

  Medicamento? _productoCarritoPorId(int id) {
    for (final producto in _productosDisponiblesParaCarrito) {
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

  bool get _carritoTieneYastas => _serviciosYastasCarrito.isNotEmpty;

  bool get _carritoTieneProductos {
    return _carrito.keys.any((id) => !_serviciosYastasCarrito.containsKey(id));
  }

  double get _subtotal {
    double total = 0;

    for (final item in _carrito.entries) {
      final producto = _productoCarritoPorId(item.key);

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
      final medicamentos = await _inventarioApiService.listarDisponibles();

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
      _mostrarErrorInventario('No se pudo conectar con la API local');
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
    if (_carritoTieneYastas) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Termina o elimina los servicios Yastas antes de agregar productos.',
          ),
        ),
      );
      return;
    }

    final cantidadActual = _carrito[producto.id] ?? 0;

    if (cantidadActual >= producto.stock) {
      return;
    }

    setState(() {
      _carrito[producto.id] = cantidadActual + 1;
    });
  }

  Future<void> _agregarServicioYastas(TarifaServicioYastas tarifa) async {
    if (_carritoTieneProductos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Termina o elimina los productos antes de agregar servicios Yastas.',
          ),
        ),
      );
      return;
    }

    final datos = await showDialog<DatosServicioYastas>(
      context: context,
      builder: (context) => DialogoServicioYastas(tarifa: tarifa),
    );

    if (datos == null) {
      return;
    }

    final idCarrito = _siguienteIdYastasCarrito--;
    final servicio = ServicioYastasCarrito(
      idCarrito: idCarrito,
      tarifa: tarifa,
      montoServicio: datos.montoServicio,
      referenciaOperacion: datos.referenciaOperacion,
      observaciones: datos.observaciones,
    );

    setState(() {
      _serviciosYastasCarrito[idCarrito] = servicio;
      _carrito[idCarrito] = 1;
    });
  }

  void _incrementarCantidad(int productoId) {
    final producto = _productoCarritoPorId(productoId);

    if (producto == null) {
      return;
    }

    final cantidadActual = _carrito[productoId] ?? 0;

    if (cantidadActual >= producto.stock) {
      return;
    }

    setState(() {
      _carrito[productoId] = cantidadActual + 1;
    });
  }

  void _disminuirCantidad(int productoId) {
    setState(() {
      final cantidadActual = _carrito[productoId] ?? 0;

      if (cantidadActual <= 1) {
        _carrito.remove(productoId);
        _serviciosYastasCarrito.remove(productoId);
      } else {
        _carrito[productoId] = cantidadActual - 1;
      }
    });
  }

  void _eliminarDelCarrito(int productoId) {
    setState(() {
      _carrito.remove(productoId);
      _serviciosYastasCarrito.remove(productoId);
    });
  }

  Future<void> _pagarVenta() async {
    if (_carrito.isEmpty || _procesandoVenta) {
      return;
    }

    if (_carritoTieneYastas) {
      await _registrarServiciosYastas();
      return;
    }

    final datosPago = await showDialog<_DatosPagoVenta>(
      context: context,
      builder: (context) => _DialogoPagoVenta(total: _total),
    );

    if (datosPago == null) {
      return;
    }

    setState(() {
      _procesandoVenta = true;
    });

    try {
      final venta = await _ventasApiService.registrarVenta(
        idUsuario: widget.usuario.id,
        medicamentos: _itemsCarrito,
        cantidades: Map<int, int>.from(_carrito),
        descuentoGeneral: _descuento,
        medioPago: datosPago.medio,
        total: _total,
        montoRecibido: datosPago.montoRecibido ?? _total,
        referencia: datosPago.referencia,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _carrito.clear();
        _procesandoVenta = false;
      });

      await _cargarInventario();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Venta ${venta.folio} registrada. Cambio: \$${venta.cambio.toStringAsFixed(2)}',
          ),
        ),
      );
    } on ApiException catch (error) {
      _mostrarErrorVenta(error.message);
    } catch (_) {
      _mostrarErrorVenta('No se pudo registrar la venta');
    }
  }

  Future<void> _registrarServiciosYastas() async {
    setState(() {
      _procesandoVenta = true;
    });

    try {
      final servicios = _serviciosYastasCarrito.values.toList();

      for (final servicio in servicios) {
        await _serviciosYastasApiService.registrarServicio(
          idUsuario: widget.usuario.id,
          idTarifa: servicio.tarifa.idTarifa,
          montoServicio: servicio.montoServicio,
          referenciaOperacion: servicio.referenciaOperacion,
          observaciones: servicio.observaciones,
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _carrito.clear();
        _serviciosYastasCarrito.clear();
        _procesandoVenta = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            servicios.length == 1
                ? 'Servicio Yastas registrado.'
                : '${servicios.length} servicios Yastas registrados.',
          ),
        ),
      );
    } on ApiException catch (error) {
      _mostrarErrorVenta(error.message);
    } catch (_) {
      _mostrarErrorVenta('No se pudieron registrar los servicios Yastas');
    }
  }

  void _mostrarErrorVenta(String mensaje) {
    if (!mounted) {
      return;
    }

    setState(() {
      _procesandoVenta = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
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
    if (_cargandoInventario || _errorInventario != null) {
      return _EstadoInventario(
        cargando: _cargandoInventario,
        error: _errorInventario,
        onReintentar: _cargarInventario,
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ContenidoVenta(
            busquedaController: _busquedaController,
            medicamentos: _medicamentosFiltrados,
            onAgregar: _agregarAlCarrito,
            onAgregarYastas: _agregarServicioYastas,
          ),
        ),
        MenuCartaCarrito(
          medicamentos: _itemsCarrito,
          cantidades: _carrito,
          subtotal: _subtotal,
          descuento: _descuento,
          total: _total,
          onIncrementar: _incrementarCantidad,
          onDisminuir: _disminuirCantidad,
          onEliminar: _eliminarDelCarrito,
          onPagar: _pagarVenta,
          procesandoPago: _procesandoVenta,
        ),
      ],
    );
  }

  Widget _construirContenidoSeleccionado() {
    switch (_menuSeleccionado) {
      case 0:
        return EditarPerfilScreen(usuario: widget.usuario);

      case 1:
        return _construirContenidoVenta();

      case 2:
        return ContenidoHistorial();

      case 3:
        return ContenidoPedidos(usuario: widget.usuario);

      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MenuSuperiorCatalogo(
              indiceSeleccionado: _submenuCatalogoSeleccionado,
              onSeleccionar: (index) {
                setState(() {
                  _submenuCatalogoSeleccionado = index;
                });
              },
            ),
            Expanded(
              child: _construirContenidoCatalogo(),
            ),
          ],
        );

      case 5:
        return ContenidoCajero(usuario: widget.usuario);

      case 6:
        return const ContenidoProveedores();

      case 7:
        return ContenidoDevolucion(usuario: widget.usuario);

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
          borderRadius: BorderRadius.circular(8),
          child: Container(
            color: _fondoContenido,
            child: Row(
              children: [
                BarraLateralIzquierda(
                  seleccionado: _menuSeleccionado,
                  onLogout: widget.onLogout,
                  onSeleccionar: (index) {
                    setState(() {
                      _menuSeleccionado = index;
                    });
                  },
                ),
                Expanded(
                  child: _construirContenidoSeleccionado(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EstadoInventario extends StatelessWidget {
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            error ?? 'No hay inventario disponible',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onReintentar,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _DatosPagoVenta {
  final String medio;
  final double? montoRecibido;
  final String? referencia;

  const _DatosPagoVenta({
    required this.medio,
    required this.montoRecibido,
    required this.referencia,
  });
}

class _DialogoPagoVenta extends StatefulWidget {
  final double total;

  const _DialogoPagoVenta({
    required this.total,
  });

  @override
  State<_DialogoPagoVenta> createState() => _DialogoPagoVentaState();
}

class _DialogoPagoVentaState extends State<_DialogoPagoVenta> {
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();

  String _medio = 'EFECTIVO';
  String? _error;

  bool get _esEfectivo => _medio == 'EFECTIVO';

  @override
  void initState() {
    super.initState();
    _montoController.text = widget.total.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _montoController.dispose();
    _referenciaController.dispose();
    super.dispose();
  }

  void _confirmar() {
    final montoRecibido = double.tryParse(_montoController.text.trim());

    if (_esEfectivo &&
        (montoRecibido == null || montoRecibido < widget.total)) {
      setState(() {
        _error = 'El efectivo recibido debe cubrir el total';
      });
      return;
    }

    Navigator.of(context).pop(
      _DatosPagoVenta(
        medio: _medio,
        montoRecibido: _esEfectivo ? montoRecibido : null,
        referencia: _referenciaController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar pago'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total: \$${widget.total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _medio,
              decoration: const InputDecoration(
                labelText: 'Metodo de pago',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'EFECTIVO', child: Text('Efectivo')),
                DropdownMenuItem(value: 'TARJETA', child: Text('Tarjeta')),
                DropdownMenuItem(
                  value: 'TRANSFERENCIA',
                  child: Text('Transferencia'),
                ),
                DropdownMenuItem(
                  value: 'ELECTRONICO',
                  child: Text('Electronico'),
                ),
                DropdownMenuItem(value: 'OTRO', child: Text('Otro')),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _medio = value;
                  _error = null;
                });
              },
            ),
            const SizedBox(height: 12),
            if (_esEfectivo)
              TextField(
                controller: _montoController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Monto recibido',
                  border: OutlineInputBorder(),
                ),
              )
            else
              TextField(
                controller: _referenciaController,
                decoration: const InputDecoration(
                  labelText: 'Referencia',
                  border: OutlineInputBorder(),
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _confirmar,
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}

class _InterfazNoEncontrada extends StatelessWidget {
  const _InterfazNoEncontrada();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Interfaz no encontrada',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
