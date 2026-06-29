import 'package:flutter/material.dart';

import 'models/medicamento.dart';
import 'models/usuario.dart';
import 'services/api_client.dart';
import 'services/inventario_api_service.dart';
import 'ui/interfaces/barra_lateral_izquierda.dart';
import 'ui/interfaces/contenido_cajero.dart';
import 'ui/interfaces/contenido_catalogo_inventario.dart';
import 'ui/interfaces/contenido_catalogo_producto.dart';
import 'ui/interfaces/contenido_historial.dart';
import 'ui/interfaces/contenido_pedidos.dart';
import 'ui/interfaces/contenido_perfil.dart';
import 'ui/interfaces/contenido_venta.dart';
import 'ui/interfaces/menu_carta_carrito.dart';
import 'ui/interfaces/menu_superior_catalogo.dart';
import 'ui/login/login_screen.dart';

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
  Usuario? _usuario;

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
      home: _usuario == null
          ? LoginScreen(
              onLogin: (usuario) {
                setState(() {
                  _usuario = usuario;
                });
              },
            )
          : VentaPrincipalScreen(usuario: _usuario!),
    );
  }
}

class VentaPrincipalScreen extends StatefulWidget {
  final Usuario usuario;

  const VentaPrincipalScreen({
    super.key,
    required this.usuario,
  });

  @override
  State<VentaPrincipalScreen> createState() => _VentaPrincipalScreenState();
}

class _VentaPrincipalScreenState extends State<VentaPrincipalScreen> {
  final InventarioApiService _inventarioApiService = InventarioApiService();
  final TextEditingController _busquedaController = TextEditingController();

  int _menuSeleccionado = 1;
  int _submenuCatalogoSeleccionado = 0;
  bool _cargandoInventario = true;
  String? _errorInventario;

  List<Medicamento> _medicamentos = [];
  final Map<int, int> _carrito = {};

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

  List<Medicamento> get _itemsCarrito {
    return _medicamentos
        .where((medicamento) => _carrito.containsKey(medicamento.id))
        .toList();
  }

  double get _subtotal {
    double total = 0;

    for (final item in _carrito.entries) {
      final medicamento = _medicamentos.firstWhere(
        (medicamento) => medicamento.id == item.key,
      );

      total += medicamento.precio * item.value;
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
          return !medicamentos.any((medicamento) => medicamento.id == id);
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

  void _agregarAlCarrito(Medicamento medicamento) {
    final cantidadActual = _carrito[medicamento.id] ?? 0;

    if (cantidadActual >= medicamento.stock) {
      return;
    }

    setState(() {
      _carrito[medicamento.id] = cantidadActual + 1;
    });
  }

  void _incrementarCantidad(int medicamentoId) {
    final medicamento = _medicamentos.firstWhere(
      (medicamento) => medicamento.id == medicamentoId,
    );
    final cantidadActual = _carrito[medicamentoId] ?? 0;

    if (cantidadActual >= medicamento.stock) {
      return;
    }

    setState(() {
      _carrito[medicamentoId] = cantidadActual + 1;
    });
  }

  void _disminuirCantidad(int medicamentoId) {
    setState(() {
      final cantidadActual = _carrito[medicamentoId] ?? 0;

      if (cantidadActual <= 1) {
        _carrito.remove(medicamentoId);
      } else {
        _carrito[medicamentoId] = cantidadActual - 1;
      }
    });
  }

  void _eliminarDelCarrito(int medicamentoId) {
    setState(() {
      _carrito.remove(medicamentoId);
    });
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
        ),
      ],
    );
  }

  Widget _construirContenidoSeleccionado() {
    switch (_menuSeleccionado) {
      case 0:
        return EditarPerfilScreen();

      case 1:
        return _construirContenidoVenta();

      case 2:
        return ContenidoHistorial();

      case 3:
        return ContenidoPedidos();

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
        return ContenidoCajero();

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
