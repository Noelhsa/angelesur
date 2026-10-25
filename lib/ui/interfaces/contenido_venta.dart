import 'package:flutter/material.dart';

import '../../models/medicamento.dart';
import '../../services/inventario_api_service.dart';
import '../../services/productos_api_service.dart';
import '../../services/servicios_yastas_api_service.dart';
import '../../utils/config_moneda.dart';
import 'contenido_venta_yastas.dart';

const Color _blanco = Color(0xFFFFFFFF);
const Color _verde = Color(0xFF6FD000);
const Color _verdeOscuro = Color(0xFF417A00);
const Color _texto = Color(0xFF101010);

// ============================================================
// CONTENIDO PRINCIPAL DE VENTA
// ============================================================

class ContenidoVenta extends StatefulWidget {
  final TextEditingController busquedaController;
  final List<Medicamento> medicamentos;
  final ValueChanged<Medicamento> onAgregar;
  final ValueChanged<TarifaServicioYastas> onAgregarYastas;

  final Future<void> Function(String codigoBarras) onEscanearCodigoBarras;

  final Future<void> Function() onActualizar;
  final Future<void> Function() onNuevoMovimiento;

  const ContenidoVenta({
    super.key,
    required this.busquedaController,
    required this.medicamentos,
    required this.onAgregar,
    required this.onAgregarYastas,
    required this.onEscanearCodigoBarras,
    required this.onActualizar,
    required this.onNuevoMovimiento,
  });

  @override
  State<ContenidoVenta> createState() => _ContenidoVentaState();
}

class _ContenidoVentaState extends State<ContenidoVenta> {
  String _seccionSeleccionada = 'Medicamentos';

  final ProductosApiService _productosApiService = ProductosApiService();

  final InventarioApiService _inventarioApiService = InventarioApiService();

  Map<int, ProductoCatalogoApi> _fichasPorProducto = {};
  Map<int, String> _ubicacionesPorInventario = {};

  bool _consultandoFichas = false;
  bool _consultandoUbicaciones = false;
  bool _actualizando = false;
  bool _registrandoMovimiento = false;

  @override
  void initState() {
    super.initState();

    _cargarFichasMedicamentos();
    _cargarUbicacionesMedicamentos();
  }

  // ==========================================================
  // CARGAR FICHAS TÉCNICAS DE PRODUCTOS
  // ==========================================================

  Future<void> _cargarFichasMedicamentos() async {
    if (_consultandoFichas) return;

    _consultandoFichas = true;

    try {
      final fichas = <int, ProductoCatalogoApi>{};

      final idsVisibles = widget.medicamentos
          .map((medicamento) => medicamento.idProducto)
          .whereType<int>()
          .toSet();

      var pagina = 1;

      while (true) {
        final resultado = await _productosApiService.listarProductosPaginados(
          tipo: 'MEDICAMENTO',
          activo: true,
          pagina: pagina,
          limite: 100,
        );

        for (final producto in resultado.items) {
          fichas[producto.idProducto] = producto;
        }

        final todasEncontradas =
            idsVisibles.isNotEmpty && idsVisibles.every(fichas.containsKey);

        if (todasEncontradas ||
            !resultado.haySiguiente ||
            pagina >= resultado.totalPaginas) {
          break;
        }

        pagina++;
      }

      if (!mounted) return;

      setState(() {
        _fichasPorProducto = fichas;
      });
    } catch (_) {
      // Si falla la consulta de fichas técnicas,
      // la venta continúa con información disponible.
    } finally {
      _consultandoFichas = false;
    }
  }

  // ==========================================================
  // CARGAR UBICACIONES REALES DESDE INVENTARIO
  // ==========================================================

  Future<void> _cargarUbicacionesMedicamentos() async {
    if (_consultandoUbicaciones) return;

    _consultandoUbicaciones = true;

    try {
      final ubicaciones = <int, String>{};

      // Utilizamos el ID del registro de inventario
      // para identificar la ubicación exacta del lote.
      final idsVisibles =
          widget.medicamentos.map((medicamento) => medicamento.id).toSet();

      var pagina = 1;

      while (true) {
        final resultado = await _inventarioApiService.listarActualPaginado(
          busqueda: '',
          pagina: pagina,
          limite: 100,
        );

        for (final item in resultado.items) {
          final letra = item.ubicacionLetra.trim().toUpperCase();

          final numero = item.ubicacionNumero;

          final ubicacion = letra.isNotEmpty && numero != null
              ? '$letra$numero'
              : 'Sin asignar';

          ubicaciones[item.idInventario] = ubicacion;
        }

        final todasEncontradas = idsVisibles.isNotEmpty &&
            idsVisibles.every(ubicaciones.containsKey);

        if (todasEncontradas ||
            !resultado.haySiguiente ||
            pagina >= resultado.totalPaginas) {
          break;
        }

        pagina++;
      }

      if (!mounted) return;

      setState(() {
        _ubicacionesPorInventario = ubicaciones;
      });
    } catch (_) {
      // Si falla la consulta, no se bloquean
      // las operaciones de venta.
    } finally {
      _consultandoUbicaciones = false;
    }
  }

  // ==========================================================
  // ACTUALIZAR CONTENIDO
  // ==========================================================

  Future<void> _actualizarContenido() async {
    if (_actualizando) return;

    setState(() {
      _actualizando = true;
    });

    try {
      await widget.onActualizar();

      await _cargarFichasMedicamentos();
      await _cargarUbicacionesMedicamentos();
    } finally {
      if (mounted) {
        setState(() {
          _actualizando = false;
        });
      }
    }
  }

  // ==========================================================
  // NUEVO MOVIMIENTO
  // ==========================================================

  Future<void> _abrirNuevoMovimiento() async {
    if (_registrandoMovimiento) return;

    setState(() {
      _registrandoMovimiento = true;
    });

    try {
      await widget.onNuevoMovimiento();
    } finally {
      if (mounted) {
        setState(() {
          _registrandoMovimiento = false;
        });
      }
    }
  }

  // ==========================================================
  // INTERFAZ PRINCIPAL
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BarraSuperiorVenta(
          busquedaController: widget.busquedaController,
          seccionSeleccionada: _seccionSeleccionada,
          actualizando: _actualizando,
          registrandoMovimiento: _registrandoMovimiento,
          onActualizar: _actualizarContenido,
          onNuevoMovimiento: _abrirNuevoMovimiento,
          onEscanearCodigoBarras: widget.onEscanearCodigoBarras,
          onSeleccionarSeccion: (seccion) {
            setState(() {
              _seccionSeleccionada = seccion;
            });
          },
        ),
        Expanded(
          child: _seccionSeleccionada == 'Yastas'
              ? ContenidoVentaYastas(
                  busquedaController: widget.busquedaController,
                  onAgregar: widget.onAgregarYastas,
                )
              : _CatalogoMedicamentos(
                  medicamentos: widget.medicamentos,
                  fichasPorProducto: _fichasPorProducto,
                  ubicacionesPorInventario: _ubicacionesPorInventario,
                  onAgregar: widget.onAgregar,
                ),
        ),
      ],
    );
  }
}

// ============================================================
// BARRA SUPERIOR DE VENTA
// ============================================================

class _BarraSuperiorVenta extends StatelessWidget {
  final TextEditingController busquedaController;
  final String seccionSeleccionada;

  final bool actualizando;
  final bool registrandoMovimiento;

  final Future<void> Function(String codigoBarras) onEscanearCodigoBarras;

  final ValueChanged<String> onSeleccionarSeccion;
  final VoidCallback onActualizar;
  final VoidCallback onNuevoMovimiento;

  const _BarraSuperiorVenta({
    required this.busquedaController,
    required this.seccionSeleccionada,
    required this.actualizando,
    required this.registrandoMovimiento,
    required this.onEscanearCodigoBarras,
    required this.onSeleccionarSeccion,
    required this.onActualizar,
    required this.onNuevoMovimiento,
  });

  @override
  Widget build(BuildContext context) {
    final esYastas = seccionSeleccionada == 'Yastas';

    return Container(
      constraints: const BoxConstraints(
        minHeight: 78,
      ),
      padding: const EdgeInsets.only(
        left: 28,
        top: 20,
        right: 18,
        bottom: 10,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final anchoBuscador = constraints.maxWidth < 780 ? 250.0 : 310.0;

          if (constraints.maxWidth < 735) {
            return Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _BuscadorVenta(
                  ancho: anchoBuscador,
                  busquedaController: busquedaController,
                  esYastas: esYastas,
                  onEscanearCodigoBarras: onEscanearCodigoBarras,
                ),
                _ChipCategoria(
                  texto: 'Medicamentos',
                  activo: seccionSeleccionada == 'Medicamentos',
                  onTap: () {
                    onSeleccionarSeccion('Medicamentos');
                  },
                  ancho: 98,
                ),
                _ChipCategoria(
                  texto: 'Yastas',
                  activo: seccionSeleccionada == 'Yastas',
                  onTap: () {
                    onSeleccionarSeccion('Yastas');
                  },
                  ancho: 72,
                ),
                _BotonNuevoMovimientoVenta(
                  registrandoMovimiento: registrandoMovimiento,
                  onNuevoMovimiento: onNuevoMovimiento,
                ),
                _BotonActualizarVenta(
                  actualizando: actualizando,
                  onActualizar: onActualizar,
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BuscadorVenta(
                ancho: anchoBuscador,
                busquedaController: busquedaController,
                esYastas: esYastas,
                onEscanearCodigoBarras: onEscanearCodigoBarras,
              ),
              const SizedBox(width: 18),
              _ChipCategoria(
                texto: 'Medicamentos',
                activo: seccionSeleccionada == 'Medicamentos',
                onTap: () {
                  onSeleccionarSeccion('Medicamentos');
                },
                ancho: 98,
              ),
              const SizedBox(width: 13),
              _ChipCategoria(
                texto: 'Yastas',
                activo: seccionSeleccionada == 'Yastas',
                onTap: () {
                  onSeleccionarSeccion('Yastas');
                },
                ancho: 72,
              ),
              const Spacer(),
              _BotonNuevoMovimientoVenta(
                registrandoMovimiento: registrandoMovimiento,
                onNuevoMovimiento: onNuevoMovimiento,
              ),
              const SizedBox(width: 8),
              _BotonActualizarVenta(
                actualizando: actualizando,
                onActualizar: onActualizar,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================
// BUSCADOR DE MEDICAMENTOS
// ============================================================

class _BuscadorVenta extends StatelessWidget {
  final double ancho;
  final TextEditingController busquedaController;
  final bool esYastas;

  final Future<void> Function(String codigoBarras) onEscanearCodigoBarras;

  const _BuscadorVenta({
    required this.ancho,
    required this.busquedaController,
    required this.esYastas,
    required this.onEscanearCodigoBarras,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ancho,
      height: 40,
      decoration: BoxDecoration(
        color: _blanco,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: const Color(0xFFD6D6D6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.04,
            ),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(
            Icons.search,
            size: 17,
            color: Color(0xFF52687C),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -2),
              child: TextField(
                controller: busquedaController,
                onSubmitted: onEscanearCodigoBarras,
                cursorColor: _verdeOscuro,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  color: _texto,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText:
                      esYastas ? 'Buscar servicio...' : 'Buscar medicamento...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF9A9A9A),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: const EdgeInsets.only(
                    left: 8,
                    right: 8,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

// ============================================================
// BOTÓN NUEVO MOVIMIENTO
// ============================================================

class _BotonNuevoMovimientoVenta extends StatelessWidget {
  final bool registrandoMovimiento;
  final VoidCallback onNuevoMovimiento;

  const _BotonNuevoMovimientoVenta({
    required this.registrandoMovimiento,
    required this.onNuevoMovimiento,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 138,
      height: 32,
      child: ElevatedButton.icon(
        onPressed: registrandoMovimiento ? null : onNuevoMovimiento,
        icon: registrandoMovimiento
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.add,
                size: 14,
                color: Colors.white,
              ),
        label: Text(
          registrandoMovimiento ? 'Guardando...' : 'Nuevo movimiento',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 2,
          backgroundColor: _verdeOscuro,
          disabledBackgroundColor: _verdeOscuro.withValues(alpha: 0.65),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
          ),
          shadowColor: _verdeOscuro.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// BOTÓN ACTUALIZAR
// ============================================================

class _BotonActualizarVenta extends StatelessWidget {
  final bool actualizando;
  final VoidCallback onActualizar;

  const _BotonActualizarVenta({
    required this.actualizando,
    required this.onActualizar,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 138,
      height: 32,
      child: ElevatedButton.icon(
        onPressed: actualizando ? null : onActualizar,
        icon: actualizando
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.refresh,
                size: 14,
                color: Colors.white,
              ),
        label: Text(
          actualizando ? 'Actualizando' : 'Actualizar',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 2,
          backgroundColor: _verdeOscuro,
          disabledBackgroundColor: _verdeOscuro.withValues(alpha: 0.65),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
          ),
          shadowColor: _verdeOscuro.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SELECTOR MEDICAMENTOS / YASTAS
// ============================================================

class _ChipCategoria extends StatelessWidget {
  final String texto;
  final bool activo;
  final VoidCallback onTap;
  final double ancho;

  const _ChipCategoria({
    required this.texto,
    required this.activo,
    required this.onTap,
    required this.ancho,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ancho,
      height: 28,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: activo ? _verdeOscuro : const Color(0xFFE3E3E3),
          foregroundColor: activo ? _blanco : _texto,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          texto,
          style: TextStyle(
            color: activo ? _blanco : _texto,
            fontSize: 10,
            fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// CATÁLOGO DE MEDICAMENTOS
// ============================================================

class _CatalogoMedicamentos extends StatelessWidget {
  final List<Medicamento> medicamentos;

  final Map<int, ProductoCatalogoApi> fichasPorProducto;

  final Map<int, String> ubicacionesPorInventario;

  final ValueChanged<Medicamento> onAgregar;

  const _CatalogoMedicamentos({
    required this.medicamentos,
    required this.fichasPorProducto,
    required this.ubicacionesPorInventario,
    required this.onAgregar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 28,
        right: 24,
        bottom: 28,
        top: 6,
      ),
      child: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: Align(
            alignment: Alignment.topLeft,
            child: medicamentos.isEmpty
                ? const Padding(
                    padding: EdgeInsets.only(
                      top: 24,
                    ),
                    child: Text(
                      'No hay medicamentos para mostrar',
                      style: TextStyle(
                        color: _texto,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                : Wrap(
                    alignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.start,
                    spacing: 14,
                    runSpacing: 15,
                    children: medicamentos.map(
                      (medicamento) {
                        return _TarjetaMedicamento(
                          medicamento: medicamento,

                          // Ficha técnica.
                          ficha: medicamento.idProducto == null
                              ? null
                              : fichasPorProducto[medicamento.idProducto],

                          // Ubicación exacta del lote.
                          ubicacion: ubicacionesPorInventario[medicamento.id],

                          onAgregar: () {
                            onAgregar(medicamento);
                          },
                        );
                      },
                    ).toList(),
                  ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TARJETA DEL MEDICAMENTO
// ============================================================

class _TarjetaMedicamento extends StatelessWidget {
  final Medicamento medicamento;
  final ProductoCatalogoApi? ficha;
  final String? ubicacion;
  final VoidCallback onAgregar;

  const _TarjetaMedicamento({
    required this.medicamento,
    required this.ficha,
    required this.ubicacion,
    required this.onAgregar,
  });

  @override
  Widget build(BuildContext context) {
    final sustancia = ficha?.sustanciaActiva?.trim();

    final sustanciaVisible =
        sustancia == null || sustancia.isEmpty ? 'Sin registrar' : sustancia;

    return Container(
      width: 170,
      height: 292,
      padding: const EdgeInsets.fromLTRB(
        12,
        12,
        12,
        12,
      ),
      decoration: BoxDecoration(
        color: _blanco,
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.07,
            ),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================================================
          // ÍCONO SEGÚN PRESENTACIÓN
          // ==================================================

          _IconoPresentacionMedicamento(
            presentacion: ficha?.presentacion,
          ),

          const SizedBox(height: 10),

          // ==================================================
          // NOMBRE DEL MEDICAMENTO
          // ==================================================

          SizedBox(
            height: 44,
            child: Text(
              medicamento.nombre,
              maxLines: 3,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _texto,
                fontSize: 12,
                height: 1.20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          const SizedBox(height: 5),

          // ==================================================
          // PRINCIPIO ACTIVO
          // ==================================================

          SizedBox(
            height: 30,
            child: Text(
              sustanciaVisible,
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: sustancia == null || sustancia.isEmpty
                    ? const Color(0xFF89939D)
                    : const Color(0xFF57636D),
                fontSize: 10,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 7),

          // ==================================================
          // UBICACIÓN DEL MEDICAMENTO
          // ==================================================

          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: _verdeOscuro,
                size: 13,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  ubicacion == null
                      ? 'Ubicación: No disponible'
                      : 'Ubicación: $ubicacion',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF57636D),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          // ==================================================
          // PRECIO Y BOTÓN AGREGAR
          // ==================================================

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  ConfigMoneda.formato(
                    medicamento.precio,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _verdeOscuro,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _BotonAgregar(
                onTap: onAgregar,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ==================================================
          // STOCK
          // ==================================================

          _IndicadorStock(
            stock: medicamento.stock,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ÍCONOS SEGÚN PRESENTACIÓN REGISTRADA
// ============================================================

class _IconoPresentacionMedicamento extends StatelessWidget {
  final String? presentacion;

  const _IconoPresentacionMedicamento({
    required this.presentacion,
  });

  @override
  Widget build(BuildContext context) {
    final tipo = (presentacion ?? '').trim().toUpperCase();

    final icono = _iconoSegunPresentacion(tipo);
    final etiqueta = _nombrePresentacion(tipo);

    return Container(
      width: double.infinity,
      height: 82,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6EB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icono,
            color: _verdeOscuro,
            size: 38,
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 5,
            ),
            child: Text(
              etiqueta,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _verdeOscuro,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SELECCIONAR ÍCONO
  // ==========================================================

  IconData _iconoSegunPresentacion(
    String tipo,
  ) {
    // Tabletas y cápsulas.
    if (tipo.contains('TABLETA') ||
        tipo.contains('CAPSULA') ||
        tipo.contains('CÁPSULA') ||
        tipo.contains('PASTILLA') ||
        tipo.contains('COMPRIMIDO')) {
      return Icons.medication_outlined;
    }

    // Medicamentos líquidos.
    if (tipo.contains('JARABE') ||
        tipo.contains('SUSPENSION') ||
        tipo.contains('SUSPENSIÓN') ||
        tipo.contains('SOLUCION') ||
        tipo.contains('SOLUCIÓN') ||
        tipo.contains('GOTAS')) {
      return Icons.medication_liquid_outlined;
    }

    // Medicamentos inyectables.
    if (tipo.contains('INYECT') ||
        tipo.contains('INYECC') ||
        tipo.contains('AMPOLLA')) {
      return Icons.vaccines_outlined;
    }

    // Cremas y pomadas.
    if (tipo.contains('CREMA') ||
        tipo.contains('POMADA') ||
        tipo.contains('GEL') ||
        tipo.contains('UNGUENTO')) {
      return Icons.sanitizer_outlined;
    }

    // Aerosoles y sprays.
    if (tipo.contains('SPRAY') || tipo.contains('AEROSOL')) {
      return Icons.air_outlined;
    }

    // Presentación no identificada.
    return Icons.medication_outlined;
  }

  // ==========================================================
  // NOMBRE DE LA PRESENTACIÓN
  // ==========================================================

  String _nombrePresentacion(String tipo) {
    if (tipo.isEmpty) {
      return 'Sin presentación';
    }

    final nombre = tipo.replaceAll('_', ' ').toLowerCase();

    return '${nombre[0].toUpperCase()}${nombre.substring(1)}';
  }
}

// ============================================================
// INDICADOR DE STOCK
// ============================================================

class _IndicadorStock extends StatelessWidget {
  final int stock;

  const _IndicadorStock({
    required this.stock,
  });

  @override
  Widget build(BuildContext context) {
    // Stock de 1 a 5 = naranja.
    // Stock mayor a 5 = verde.
    final pocoStock = stock <= 5;

    final color = pocoStock ? const Color(0xFFA56600) : const Color(0xFF3A7704);

    final fondo = pocoStock ? const Color(0xFFFFF2DA) : const Color(0xFFEAF7DF);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'Stock: $stock ${stock == 1 ? 'unidad' : 'unidades'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// BOTÓN AGREGAR AL CARRITO
// ============================================================

class _BotonAgregar extends StatelessWidget {
  final VoidCallback onTap;

  const _BotonAgregar({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      height: 26,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 4,
          shadowColor: _verde.withValues(alpha: 0.45),
          backgroundColor: _verde,
          foregroundColor: _texto,
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
        ),
        child: const Icon(
          Icons.add,
          size: 18,
          color: _texto,
        ),
      ),
    );
  }
}
