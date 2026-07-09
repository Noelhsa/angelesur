import 'package:flutter/material.dart';

import '../../models/usuario.dart';
import '../../services/api_client.dart';
import '../../services/compras_api_service.dart';
import '../../utils/config_moneda.dart';
import 'menu_carta_pedidos.dart';

const Color _fondoPagina = Color(0xFFF8F6F5);
const Color _verdeOscuro = Color(0xFF397800);
const Color _azul = Color(0xFF0B63CE);
const Color _textoPrincipal = Color(0xFF101828);
const Color _textoSecundario = Color(0xFF526171);
const Color _bordeSuave = Color(0xFFD9E6D3);
const Color _rojo = Color(0xFFE02020);

class ContenidoPedidos extends StatefulWidget {
  final Usuario usuario;

  const ContenidoPedidos({
    super.key,
    required this.usuario,
  });

  @override
  State<ContenidoPedidos> createState() => _ContenidoPedidosState();
}

class _ContenidoPedidosState extends State<ContenidoPedidos> {
  final ComprasApiService _comprasApiService = ComprasApiService();
  final TextEditingController _busquedaController = TextEditingController();

  bool _mostrarMenuNuevaOrden = false;
  bool _cargando = true;
  bool _procesando = false;
  String _filtroSeleccionado = 'Todos';
  String? _error;
  List<CompraResumen> _compras = [];

  @override
  void initState() {
    super.initState();
    _cargarCompras();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  List<CompraResumen> get _comprasFiltradas {
    final texto = _busquedaController.text.trim().toLowerCase();

    return _compras.where((compra) {
      final folio = compra.folioProveedor ?? '';
      final coincideBusqueda = texto.isEmpty ||
          'cmp-${compra.idCompra}'.contains(texto) ||
          folio.toLowerCase().contains(texto) ||
          compra.proveedor.toLowerCase().contains(texto) ||
          compra.usuario.toLowerCase().contains(texto);

      final coincideFiltro = switch (_filtroSeleccionado) {
        'Pendientes' => compra.estatus == 'REGISTRADA',
        'Completados' => compra.estatus == 'REGISTRADA',
        'Cancelados' => compra.estatus == 'CANCELADA',
        _ => true,
      };

      return coincideBusqueda && coincideFiltro;
    }).toList();
  }

  Future<void> _cargarCompras() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final compras = await _comprasApiService.listarCompras();
      if (!mounted) return;
      setState(() {
        _compras = compras;
        _cargando = false;
      });
    } on ApiException catch (error) {
      _mostrarError(error.message);
    } catch (_) {
      _mostrarError('No se pudieron cargar las compras');
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

  Future<void> _mostrarDetalle(CompraResumen compra) async {
    showDialog<void>(
      context: context,
      builder: (context) => _DialogoDetalleCompra(
        future: _comprasApiService.obtenerCompra(compra.idCompra),
      ),
    );
  }

  Future<void> _cancelarCompra(CompraResumen compra) async {
    if (compra.estatus == 'CANCELADA' || _procesando) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar compra'),
        content: Text('Se cancelara la compra CMP-${compra.idCompra}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Volver'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancelar compra'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() {
      _procesando = true;
    });

    try {
      await _comprasApiService.cancelarCompra(
        idCompra: compra.idCompra,
        idUsuario: widget.usuario.id,
        observaciones: 'Cancelada desde interfaz de pedidos',
      );
      _mostrarMensaje('Compra cancelada');
      await _cargarCompras();
    } on ApiException catch (error) {
      _mostrarMensaje(error.message);
    } catch (_) {
      _mostrarMensaje('No se pudo cancelar la compra');
    } finally {
      if (mounted) {
        setState(() {
          _procesando = false;
        });
      }
    }
  }

  Future<void> _registrarCompra(CompraPayload compra) async {
    if (_procesando) return;

    setState(() {
      _procesando = true;
    });

    try {
      final registrada = await _comprasApiService.registrarCompra(compra);
      if (!mounted) return;
      setState(() {
        _mostrarMenuNuevaOrden = false;
      });
      _mostrarMensaje('Compra CMP-${registrada.idCompra} registrada');
      await _cargarCompras();
    } on ApiException catch (error) {
      _mostrarMensaje(error.message);
    } catch (_) {
      _mostrarMensaje('No se pudo registrar la compra');
    } finally {
      if (mounted) {
        setState(() {
          _procesando = false;
        });
      }
    }
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
                  _ResumenPedidos(compras: _compras),
                  const SizedBox(height: 28),
                  if (_cargando)
                    const _EstadoPedidos(mensaje: 'Cargando compras...')
                  else if (_error != null)
                    _EstadoPedidos(
                      mensaje: _error!,
                      onReintentar: _cargarCompras,
                    )
                  else
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
                      compras: _comprasFiltradas,
                      procesando: _procesando,
                      onDetalle: _mostrarDetalle,
                      onCancelar: _cancelarCompra,
                    ),
                ],
              ),
            ),
          ),
          if (_mostrarMenuNuevaOrden)
            MenuCartaPedidos(
              idUsuario: widget.usuario.id,
              guardando: _procesando,
              onCerrar: () {
                setState(() {
                  _mostrarMenuNuevaOrden = false;
                });
              },
              onGuardarOrden: _registrarCompra,
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
                'Compras registradas y seguimiento de ordenes a proveedores.',
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
            icon: const Icon(Icons.add, size: 18, color: Colors.white),
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
              shadowColor: _verdeOscuro.withValues(alpha: 0.35),
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
  final List<CompraResumen> compras;

  const _ResumenPedidos({
    required this.compras,
  });

  @override
  Widget build(BuildContext context) {
    final registradas =
        compras.where((compra) => compra.estatus == 'REGISTRADA').length;
    final canceladas =
        compras.where((compra) => compra.estatus == 'CANCELADA').length;
    final total = compras.fold<double>(0, (sum, compra) => sum + compra.total);

    return Row(
      children: [
        Expanded(
          child: _TarjetaResumenPedido(
            titulo: 'TOTAL',
            valor: '${compras.length}',
            icono: Icons.shopping_cart_outlined,
            fondoIcono: const Color(0xFFEAF7DF),
            colorIcono: _verdeOscuro,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _TarjetaResumenPedido(
            titulo: 'REGISTRADAS',
            valor: '$registradas',
            icono: Icons.assignment_outlined,
            fondoIcono: const Color(0xFFE8F1FF),
            colorIcono: _azul,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _TarjetaResumenPedido(
            titulo: 'MONTO',
            valor: ConfigMoneda.formato(total),
            icono: Icons.payments_outlined,
            fondoIcono: const Color(0xFFEAF7DF),
            colorIcono: _verdeOscuro,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _TarjetaResumenPedido(
            titulo: 'CANCELADAS',
            valor: '$canceladas',
            icono: Icons.cancel_outlined,
            fondoIcono: const Color(0xFFFFE8E8),
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
            child: Icon(icono, color: colorIcono, size: 23),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textoPrincipal,
                    fontSize: 20,
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

class _PanelPedidos extends StatelessWidget {
  final TextEditingController busquedaController;
  final String filtroSeleccionado;
  final ValueChanged<String> onFiltroSeleccionado;
  final VoidCallback onBuscar;
  final List<CompraResumen> compras;
  final bool procesando;
  final ValueChanged<CompraResumen> onDetalle;
  final ValueChanged<CompraResumen> onCancelar;

  const _PanelPedidos({
    required this.busquedaController,
    required this.filtroSeleccionado,
    required this.onFiltroSeleccionado,
    required this.onBuscar,
    required this.compras,
    required this.procesando,
    required this.onDetalle,
    required this.onCancelar,
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
                      hintText: 'Buscar por compra, folio o proveedor...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF7E8790),
                        fontSize: 12,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 18,
                        color: Color(0xFF34423B),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 36),
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
                const Spacer(),
                _FiltroEstadoPedidos(
                  seleccionado: filtroSeleccionado,
                  onSeleccionar: onFiltroSeleccionado,
                ),
              ],
            ),
          ),
          if (compras.isEmpty)
            const _EstadoPedidos(mensaje: 'No hay compras para mostrar')
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final anchoTabla =
                    constraints.maxWidth < 940 ? 940.0 : constraints.maxWidth;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: anchoTabla,
                    child: _TablaPedidos(
                      compras: compras,
                      procesando: procesando,
                      onDetalle: onDetalle,
                      onCancelar: onCancelar,
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
      width: 390,
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
            texto: 'Registradas',
            activo: seleccionado == 'Pendientes',
            onTap: () => onSeleccionar('Pendientes'),
          ),
          _BotonFiltroPedido(
            texto: 'Completadas',
            activo: seleccionado == 'Completados',
            onTap: () => onSeleccionar('Completados'),
          ),
          _BotonFiltroPedido(
            texto: 'Canceladas',
            activo: seleccionado == 'Cancelados',
            onTap: () => onSeleccionar('Cancelados'),
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
              fontSize: 10,
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
  final List<CompraResumen> compras;
  final bool procesando;
  final ValueChanged<CompraResumen> onDetalle;
  final ValueChanged<CompraResumen> onCancelar;

  const _TablaPedidos({
    required this.compras,
    required this.procesando,
    required this.onDetalle,
    required this.onCancelar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _HeaderTablaPedidos(),
        for (final compra in compras)
          _FilaPedido(
            compra: compra,
            procesando: procesando,
            onDetalle: onDetalle,
            onCancelar: onCancelar,
          ),
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
          Expanded(flex: 12, child: _TextoHeaderTabla('COMPRA')),
          Expanded(flex: 16, child: _TextoHeaderTabla('FECHA')),
          Expanded(flex: 22, child: _TextoHeaderTabla('PROVEEDOR')),
          Expanded(flex: 16, child: _TextoHeaderTabla('FOLIO')),
          Expanded(flex: 12, child: _TextoHeaderTabla('TOTAL')),
          Expanded(flex: 16, child: _TextoHeaderTabla('ESTADO')),
          Expanded(flex: 14, child: _TextoHeaderTabla('ACCIONES')),
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
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _FilaPedido extends StatelessWidget {
  final CompraResumen compra;
  final bool procesando;
  final ValueChanged<CompraResumen> onDetalle;
  final ValueChanged<CompraResumen> onCancelar;

  const _FilaPedido({
    required this.compra,
    required this.procesando,
    required this.onDetalle,
    required this.onCancelar,
  });

  @override
  Widget build(BuildContext context) {
    final cancelada = compra.estatus == 'CANCELADA';

    return Container(
      height: 88,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0E8D8), width: 1),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 20),
          Expanded(
            flex: 12,
            child: Text(
              'CMP-\n${compra.idCompra}',
              style: const TextStyle(
                color: _verdeOscuro,
                fontSize: 12,
                height: 1.1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            flex: 16,
            child: Text(
              _formatoFechaHora(compra.fecha).replaceFirst(' ', '\n'),
              style: const TextStyle(
                color: _textoPrincipal,
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 22,
            child: Text(
              compra.proveedor,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _textoPrincipal,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 16,
            child: Text(
              compra.folioProveedor ?? 'Sin folio',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _textoPrincipal,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 12,
            child: Text(
              ConfigMoneda.formato(compra.total),
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
              child: _BadgeEstadoPedido(estatus: compra.estatus),
            ),
          ),
          Expanded(
            flex: 14,
            child: Row(
              children: [
                IconButton(
                  onPressed: procesando ? null : () => onDetalle(compra),
                  tooltip: 'Ver detalle',
                  icon: const Icon(Icons.remove_red_eye_outlined),
                  color: _verdeOscuro,
                  iconSize: 20,
                ),
                IconButton(
                  onPressed:
                      procesando || cancelada ? null : () => onCancelar(compra),
                  tooltip: 'Cancelar',
                  icon: const Icon(Icons.cancel_outlined),
                  color: cancelada ? _textoSecundario : _rojo,
                  iconSize: 20,
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
        ],
      ),
    );
  }
}

class _BadgeEstadoPedido extends StatelessWidget {
  final String estatus;

  const _BadgeEstadoPedido({
    required this.estatus,
  });

  @override
  Widget build(BuildContext context) {
    final cancelada = estatus == 'CANCELADA';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: cancelada ? const Color(0xFFFFE8E8) : const Color(0xFFE8F5DD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        cancelada ? 'Cancelada' : 'Registrada',
        style: TextStyle(
          color: cancelada ? _rojo : _verdeOscuro,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EstadoPedidos extends StatelessWidget {
  final String mensaje;
  final VoidCallback? onReintentar;

  const _EstadoPedidos({
    required this.mensaje,
    this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mensaje,
              textAlign: TextAlign.center,
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

class _DialogoDetalleCompra extends StatelessWidget {
  final Future<CompraDetalle> future;

  const _DialogoDetalleCompra({
    required this.future,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Detalle de compra'),
      content: SizedBox(
        width: 680,
        child: FutureBuilder<CompraDetalle>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 140,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return const _EstadoPedidos(
                mensaje: 'No se pudo cargar el detalle',
              );
            }

            final compra = snapshot.data!;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _DatoDetalle('Compra', 'CMP-${compra.idCompra}'),
                      _DatoDetalle('Fecha', _formatoFechaHora(compra.fecha)),
                      _DatoDetalle('Proveedor', compra.proveedor),
                      _DatoDetalle(
                        'Folio proveedor',
                        compra.folioProveedor ?? 'Sin folio',
                      ),
                      _DatoDetalle(
                          'Subtotal', ConfigMoneda.formato(compra.subtotal)),
                      _DatoDetalle(
                        'Descuento',
                        ConfigMoneda.formato(compra.descuento),
                      ),
                      _DatoDetalle('Total', ConfigMoneda.formato(compra.total)),
                      _DatoDetalle('Estado', compra.estatus),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Productos',
                    style: TextStyle(
                      color: _textoPrincipal,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _TablaDetalleCompra(detalles: compra.detalles),
                  if (compra.observaciones.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      compra.observaciones,
                      style: const TextStyle(
                        color: _textoSecundario,
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

class _TablaDetalleCompra extends StatelessWidget {
  final List<CompraProductoDetalle> detalles;

  const _TablaDetalleCompra({
    required this.detalles,
  });

  @override
  Widget build(BuildContext context) {
    if (detalles.isEmpty) {
      return const Text(
        'Sin productos registrados',
        style: TextStyle(color: _textoSecundario),
      );
    }

    return Column(
      children: [
        for (final detalle in detalles)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE0E8D8))),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    detalle.producto,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Expanded(child: Text('Cant. ${detalle.cantidad}')),
                Expanded(child: Text(detalle.codigoLote)),
                Expanded(
                  child: Text(ConfigMoneda.formato(detalle.costoUnitario)),
                ),
                Expanded(
                  child: Text(ConfigMoneda.formato(detalle.subtotal)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DatoDetalle extends StatelessWidget {
  final String label;
  final String value;

  const _DatoDetalle(this.label, this.value);

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
          const SizedBox(height: 4),
          Text(
            value,
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

String _formatoFechaHora(DateTime? fecha) {
  if (fecha == null) return 'Sin fecha';

  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  final hora = fecha.hour.toString().padLeft(2, '0');
  final minuto = fecha.minute.toString().padLeft(2, '0');
  return '$dia/$mes/${fecha.year} $hora:$minuto';
}
