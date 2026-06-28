import 'package:flutter/material.dart';

import 'models/medicamento.dart';
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

const Color _fondoApp = Color(0xFF181A20);
const Color _fondoContenido = Color(0xFFE2E2E2);
const Color _verde = Color(0xFF58D000);

void main() {
  runApp(const AngelesurApp());
}

class AngelesurApp extends StatelessWidget {
  const AngelesurApp({super.key});

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
      home: const VentaPrincipalScreen(),
    );
  }
}

class VentaPrincipalScreen extends StatefulWidget {
  const VentaPrincipalScreen({super.key});

  @override
  State<VentaPrincipalScreen> createState() => _VentaPrincipalScreenState();
}

class _VentaPrincipalScreenState extends State<VentaPrincipalScreen> {
  final TextEditingController _busquedaController = TextEditingController();

  int _menuSeleccionado = 1;
  int _submenuCatalogoSeleccionado = 0;

  final List<Medicamento> _medicamentos = const [
    Medicamento(
      id: 1,
      nombre: 'Paracetamol 500mg',
      detalle: 'TEMPRA - 20 TAB.',
      categoria: 'Analgésico',
      precio: 45.00,
      stock: 124,
    ),
    Medicamento(
      id: 2,
      nombre: 'Amoxicilina 250mg',
      detalle: 'SUSPENSIÓN 60ML',
      categoria: 'Antibiótico',
      precio: 182.50,
      stock: 42,
    ),
    Medicamento(
      id: 3,
      nombre: 'Ibuprofeno 400mg',
      detalle: 'ADVIL - 10 CAPS.',
      categoria: 'Analgésico',
      precio: 68.00,
      stock: 89,
    ),
    Medicamento(
      id: 4,
      nombre: 'Omeprazol 20mg',
      detalle: 'ESTOMAGAL - 7 CAPS.',
      categoria: 'Gástrico',
      precio: 115.00,
      stock: 215,
    ),
    Medicamento(
      id: 5,
      nombre: 'Termómetro Digital',
      detalle: 'PRECISION X1',
      categoria: 'Dispositivo',
      precio: 145.00,
      stock: 18,
    ),
  ];

  final Map<int, int> _carrito = {
    2: 1,
    4: 1,
    5: 1,
  };

  @override
  void initState() {
    super.initState();

    _busquedaController.addListener(() {
      setState(() {});
    });
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

  double get _descuento {
    if (_subtotal <= 0) {
      return 0;
    }

    return 27.25;
  }

  double get _total {
    final total = _subtotal - _descuento;
    return total < 0 ? 0 : total;
  }

  void _agregarAlCarrito(Medicamento medicamento) {
    setState(() {
      _carrito[medicamento.id] = (_carrito[medicamento.id] ?? 0) + 1;
    });
  }

  void _incrementarCantidad(int medicamentoId) {
    setState(() {
      _carrito[medicamentoId] = (_carrito[medicamentoId] ?? 0) + 1;
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

  Widget _construirContenidoSeleccionado() {
    switch (_menuSeleccionado) {
      case 0:
        return EditarPerfilScreen();

      case 1:
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