import 'package:flutter/material.dart';

import '../../models/usuario.dart';
import '../../services/api_client.dart';
import '../../services/caja_api_service.dart';
import '../../services/cortes_api_service.dart';
import '../../utils/config_moneda.dart';

const Color _fondoPagina = Color(0xFFE2E2E2);
const Color _blanco = Color(0xFFFFFFFF);
const Color _verde = Color(0xFF64D20A);
const Color _verdeOscuro = Color(0xFF397800);
const Color _azul = Color(0xFF3478F6);
const Color _rojo = Color(0xFFD71919);
const Color _textoPrincipal = Color(0xFF101828);
const Color _textoSecundario = Color(0xFF526171);
const Color _bordeSuave = Color(0xFFD9E6D3);

class ContenidoCajero extends StatefulWidget {
  final Usuario usuario;

  const ContenidoCajero({
    super.key,
    required this.usuario,
  });

  @override
  State<ContenidoCajero> createState() => _ContenidoCajeroState();
}

class _ContenidoCajeroState extends State<ContenidoCajero> {
  final CortesApiService _cortesApiService = CortesApiService();
  final CajaApiService _cajaApiService = CajaApiService();

  bool _cargando = true;
  bool _cargandoMovimientos = false;
  bool _procesando = false;
  String? _error;
  String? _errorMovimientos;
  CorteResumen? _corte;
  List<MovimientoCaja> _movimientos = [];

  @override
  void initState() {
    super.initState();
    _cargarCorte();
  }

  Future<void> _cargarCorte() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final corte = await _cortesApiService.obtenerActual();
      if (!mounted) return;

      setState(() {
        _corte = corte;
        _cargando = false;
      });
      await _cargarMovimientos(corte?.idCorte);
    } on ApiException catch (error) {
      _mostrarError(error.message);
    } catch (_) {
      _mostrarError('No se pudo cargar el corte de caja');
    }
  }

  Future<void> _cargarMovimientos(int? idCorte) async {
    if (idCorte == null) {
      if (!mounted) return;
      setState(() {
        _movimientos = [];
        _errorMovimientos = null;
        _cargandoMovimientos = false;
      });
      return;
    }

    setState(() {
      _cargandoMovimientos = true;
      _errorMovimientos = null;
    });

    try {
      final movimientos = await _cajaApiService.listarMovimientos(
        idCorte: idCorte,
        limite: 80,
      );
      if (!mounted) return;

      setState(() {
        _movimientos = movimientos;
        _cargandoMovimientos = false;
      });
    } on ApiException catch (error) {
      _mostrarErrorMovimientos(error.message);
    } catch (_) {
      _mostrarErrorMovimientos('No se pudieron cargar los movimientos');
    }
  }

  void _mostrarErrorMovimientos(String mensaje) {
    if (!mounted) return;

    setState(() {
      _errorMovimientos = mensaje;
      _cargandoMovimientos = false;
    });
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;

    setState(() {
      _error = mensaje;
      _cargando = false;
      _procesando = false;
    });
  }

  Future<void> _abrirCorte() async {
    final datos = await showDialog<_DatosAbrirCorte>(
      context: context,
      builder: (context) => const _DialogoAbrirCorte(),
    );

    if (datos == null) return;

    setState(() {
      _procesando = true;
    });

    try {
      await _cortesApiService.abrirCorte(
        idUsuario: widget.usuario.id,
        efectivoInicial: datos.efectivoInicial,
        electronicoInicial: datos.electronicoInicial,
        observaciones: datos.observaciones,
      );
      await _cargarCorte();
    } on ApiException catch (error) {
      _mostrarError(error.message);
    } catch (_) {
      _mostrarError('No se pudo abrir el corte');
    } finally {
      if (mounted) {
        setState(() {
          _procesando = false;
        });
      }
    }
  }

  Future<void> _cerrarCorte() async {
    final corte = _corte;
    if (corte == null) return;

    final datos = await showDialog<_DatosCerrarCorte>(
      context: context,
      builder: (context) => _DialogoCerrarCorte(corte: corte),
    );

    if (datos == null) return;

    setState(() {
      _procesando = true;
    });

    try {
      await _cortesApiService.cerrarCorte(
        idUsuario: widget.usuario.id,
        efectivoContado: datos.efectivoContado,
        electronicoContado: datos.electronicoContado,
        observaciones: datos.observaciones,
      );
      await _cargarCorte();
    } on ApiException catch (error) {
      _mostrarError(error.message);
    } catch (_) {
      _mostrarError('No se pudo cerrar el corte');
    } finally {
      if (mounted) {
        setState(() {
          _procesando = false;
        });
      }
    }
  }

  Future<void> _registrarMovimiento() async {
    if (_corte == null) return;

    final datos = await showDialog<_DatosMovimientoCaja>(
      context: context,
      builder: (context) => const _DialogoMovimientoCaja(),
    );

    if (datos == null) return;

    setState(() {
      _procesando = true;
    });

    try {
      await _cajaApiService.registrarMovimiento(
        idUsuario: widget.usuario.id,
        medio: datos.medio,
        tipo: datos.tipo,
        concepto: datos.concepto,
        monto: datos.monto,
        observaciones: datos.observaciones,
      );
      await _cargarCorte();
    } on ApiException catch (error) {
      _mostrarErrorMovimientos(error.message);
    } catch (_) {
      _mostrarErrorMovimientos('No se pudo registrar el movimiento');
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 22),
        child: _cargando
            ? const _EstadoCaja(mensaje: 'Cargando corte...')
            : _error != null
                ? _EstadoCaja(mensaje: _error!, onReintentar: _cargarCorte)
                : Column(
                    children: [
                      _EncabezadoCaja(
                        corte: _corte,
                        onRefrescar: _cargarCorte,
                      ),
                      const SizedBox(height: 18),
                      _ResumenSuperiorCajero(corte: _corte),
                      const SizedBox(height: 18),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final acciones = _CorteCajaCard(
                            corte: _corte,
                            procesando: _procesando,
                            onAbrir: _abrirCorte,
                            onCerrar: _cerrarCorte,
                          );
                          final resumen = _DetalleCorteCard(corte: _corte);

                          if (constraints.maxWidth < 850) {
                            return Column(
                              children: [
                                resumen,
                                const SizedBox(height: 18),
                                acciones,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 7, child: resumen),
                              const SizedBox(width: 18),
                              Expanded(flex: 3, child: acciones),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      _MovimientosCajaCard(
                        corte: _corte,
                        movimientos: _movimientos,
                        cargando: _cargandoMovimientos,
                        procesando: _procesando,
                        error: _errorMovimientos,
                        onNuevoMovimiento: _registrarMovimiento,
                        onRefrescar: () => _cargarMovimientos(_corte?.idCorte),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _MovimientosCajaCard extends StatelessWidget {
  final CorteResumen? corte;
  final List<MovimientoCaja> movimientos;
  final bool cargando;
  final bool procesando;
  final String? error;
  final VoidCallback onNuevoMovimiento;
  final VoidCallback onRefrescar;

  const _MovimientosCajaCard({
    required this.corte,
    required this.movimientos,
    required this.cargando,
    required this.procesando,
    required this.error,
    required this.onNuevoMovimiento,
    required this.onRefrescar,
  });

  @override
  Widget build(BuildContext context) {
    final abierto = corte != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Movimientos de Caja',
                  style: TextStyle(
                    color: _textoPrincipal,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: abierto ? onRefrescar : null,
                tooltip: 'Actualizar',
                icon: const Icon(Icons.refresh, color: _textoSecundario),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: abierto && !procesando ? onNuevoMovimiento : null,
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: Text(
                  procesando ? 'Guardando...' : 'Nuevo movimiento',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _verdeOscuro,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (!abierto)
            const _MensajeMovimientos(
              icono: Icons.lock_outline,
              titulo: 'Abre un corte para ver movimientos',
              subtitulo:
                  'Los movimientos manuales se registran en el corte abierto.',
            )
          else if (cargando)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (error != null)
            _MensajeMovimientos(
              icono: Icons.error_outline,
              titulo: error!,
              subtitulo: 'Revisa que la API este encendida e intenta de nuevo.',
            )
          else if (movimientos.isEmpty)
            const _MensajeMovimientos(
              icono: Icons.receipt_long_outlined,
              titulo: 'Sin movimientos registrados',
              subtitulo: 'Las ventas, compras y ajustes apareceran aqui.',
            )
          else
            _ListaMovimientosCaja(movimientos: movimientos),
        ],
      ),
    );
  }
}

class _ListaMovimientosCaja extends StatelessWidget {
  final List<MovimientoCaja> movimientos;

  const _ListaMovimientosCaja({
    required this.movimientos,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: movimientos
          .map((movimiento) => _FilaMovimientoCaja(movimiento: movimiento))
          .toList(),
    );
  }
}

class _FilaMovimientoCaja extends StatelessWidget {
  final MovimientoCaja movimiento;

  const _FilaMovimientoCaja({
    required this.movimiento,
  });

  @override
  Widget build(BuildContext context) {
    final entrada = movimiento.esEntrada;
    final monto =
        '${entrada ? '+' : '-'}${ConfigMoneda.formato(movimiento.monto)}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE9EEF3))),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color:
                  entrada ? const Color(0xFFEAF8DD) : const Color(0xFFFFE8E8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              entrada ? Icons.arrow_downward : Icons.arrow_upward,
              color: entrada ? _verdeOscuro : _rojo,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _etiquetaConcepto(movimiento.concepto),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textoPrincipal,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatoFechaHora(movimiento.fecha)}  |  ${movimiento.medio}  |  ${movimiento.usuario.isEmpty ? 'Usuario #${movimiento.idUsuario}' : movimiento.usuario}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textoSecundario,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (movimiento.observaciones.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    movimiento.observaciones,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _textoSecundario,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            monto,
            style: TextStyle(
              color: entrada ? _verdeOscuro : _rojo,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MensajeMovimientos extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;

  const _MensajeMovimientos({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Column(
          children: [
            Icon(icono, color: _textoSecundario, size: 42),
            const SizedBox(height: 10),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textoPrincipal,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textoSecundario,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EncabezadoCaja extends StatelessWidget {
  final CorteResumen? corte;
  final VoidCallback onRefrescar;

  const _EncabezadoCaja({
    required this.corte,
    required this.onRefrescar,
  });

  @override
  Widget build(BuildContext context) {
    final abierto = corte != null;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Caja',
                style: TextStyle(
                  color: _textoPrincipal,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                abierto
                    ? 'Corte #${corte!.idCorte} abierto desde ${_formatoFechaHora(corte!.fechaApertura)}'
                    : 'No hay corte abierto. Abre uno para comenzar a vender.',
                style: TextStyle(
                  color: abierto ? _verdeOscuro : _rojo,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onRefrescar,
          icon: const Icon(Icons.refresh, color: _textoSecundario),
        ),
      ],
    );
  }
}

class _ResumenSuperiorCajero extends StatelessWidget {
  final CorteResumen? corte;

  const _ResumenSuperiorCajero({
    required this.corte,
  });

  @override
  Widget build(BuildContext context) {
    final actual = corte;

    final cards = [
      _TarjetaResumenCaja(
        titulo: 'Fondo Inicial',
        valor: ConfigMoneda.formato(actual?.efectivoInicial ?? 0),
        subtitulo: actual == null ? 'Sin corte abierto' : 'Efectivo inicial',
        icono: Icons.account_balance_wallet_outlined,
        colorIcono: _azul,
        fondoIcono: const Color(0xFFE8F1FF),
      ),
      _TarjetaResumenCaja(
        titulo: 'Ventas Efectivo',
        valor: ConfigMoneda.formato(actual?.ventasEfectivo ?? 0),
        subtitulo: 'Ingresos en efectivo',
        subtituloVerde: true,
        icono: Icons.payments_outlined,
        colorIcono: _verdeOscuro,
        fondoIcono: const Color(0xFFEAF8DD),
      ),
      _TarjetaResumenCaja(
        titulo: 'Otros Metodos',
        valor: ConfigMoneda.formato(actual?.ventasElectronico ?? 0),
        subtitulo: 'Electronico / tarjeta / transferencia',
        icono: Icons.credit_card,
        colorIcono: _azul,
        fondoIcono: const Color(0xFFE8F1FF),
      ),
      _TarjetaBalanceEfectivo(
        valor: ConfigMoneda.formato(actual?.efectivoEsperado ?? 0),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: cards,
          );
        }

        return Row(
          children: [
            for (final card in cards) ...[
              Expanded(child: card),
              if (card != cards.last) const SizedBox(width: 16),
            ],
          ],
        );
      },
    );
  }
}

class _TarjetaResumenCaja extends StatelessWidget {
  final String titulo;
  final String valor;
  final String subtitulo;
  final IconData icono;
  final Color colorIcono;
  final Color fondoIcono;
  final bool subtituloVerde;

  const _TarjetaResumenCaja({
    required this.titulo,
    required this.valor,
    required this.subtitulo,
    required this.icono,
    required this.colorIcono,
    required this.fondoIcono,
    this.subtituloVerde = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 128,
      constraints: const BoxConstraints(minWidth: 155),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: fondoIcono,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icono, size: 20, color: colorIcono),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textoPrincipal,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
          const SizedBox(height: 7),
          Text(
            subtitulo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: subtituloVerde ? _verdeOscuro : _textoSecundario,
              fontSize: 10,
              fontWeight: subtituloVerde ? FontWeight.w800 : FontWeight.w500,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaBalanceEfectivo extends StatelessWidget {
  final String valor;

  const _TarjetaBalanceEfectivo({
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 128,
      constraints: const BoxConstraints(minWidth: 155),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: _verde,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _blanco, width: 2),
        boxShadow: [
          BoxShadow(
            color: _verde.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _IconoBalance(),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Balance Efectivo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _verdeOscuro,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _verdeOscuro,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Dinero esperado en caja fisica',
            style: TextStyle(
              color: _verdeOscuro,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconoBalance extends StatelessWidget {
  const _IconoBalance();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFA8EC52),
        borderRadius: BorderRadius.circular(7),
      ),
      child: const Icon(Icons.payments_outlined, size: 20, color: _blanco),
    );
  }
}

class _DetalleCorteCard extends StatelessWidget {
  final CorteResumen? corte;

  const _DetalleCorteCard({
    required this.corte,
  });

  @override
  Widget build(BuildContext context) {
    final actual = corte;

    return Container(
      constraints: const BoxConstraints(minHeight: 310),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
      decoration: _cardDecoration(),
      child: actual == null
          ? const _SinCorteAbierto()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Resumen del Corte',
                        style: TextStyle(
                          color: _textoPrincipal,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _BadgeEstadoCorte(estado: actual.estado),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _DatoCorte(
                      label: 'Apertura',
                      value: _formatoFechaHora(actual.fechaApertura),
                    ),
                    _DatoCorte(
                      label: 'Efectivo inicial',
                      value: ConfigMoneda.formato(actual.efectivoInicial),
                    ),
                    _DatoCorte(
                      label: 'Electronico inicial',
                      value: ConfigMoneda.formato(actual.electronicoInicial),
                    ),
                    _DatoCorte(
                      label: 'Ventas efectivo',
                      value: ConfigMoneda.formato(actual.ventasEfectivo),
                    ),
                    _DatoCorte(
                      label: 'Ventas electronico',
                      value: ConfigMoneda.formato(actual.ventasElectronico),
                    ),
                    _DatoCorte(
                      label: 'Otros ingresos',
                      value: ConfigMoneda.formato(actual.otrosIngresos),
                    ),
                    _DatoCorte(
                      label: 'Salidas',
                      value: ConfigMoneda.formato(actual.salidas),
                      valueColor: _rojo,
                    ),
                    _DatoCorte(
                      label: 'Total esperado',
                      value: ConfigMoneda.formato(actual.totalEsperado),
                      valueColor: _verdeOscuro,
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _SinCorteAbierto extends StatelessWidget {
  const _SinCorteAbierto();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_open_outlined, size: 56, color: _textoSecundario),
          SizedBox(height: 14),
          Text(
            'No hay corte abierto',
            style: TextStyle(
              color: _textoPrincipal,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Abre un corte para comenzar a registrar ventas y movimientos.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textoSecundario, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _CorteCajaCard extends StatelessWidget {
  final CorteResumen? corte;
  final bool procesando;
  final VoidCallback onAbrir;
  final VoidCallback onCerrar;

  const _CorteCajaCard({
    required this.corte,
    required this.procesando,
    required this.onAbrir,
    required this.onCerrar,
  });

  @override
  Widget build(BuildContext context) {
    final abierto = corte != null;

    return Container(
      height: 310,
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: abierto ? _verde : const Color(0xFFFFE8E8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              abierto ? Icons.lock_outline : Icons.lock_open_outlined,
              size: 34,
              color: abierto ? _verdeOscuro : _rojo,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            abierto ? 'Corte Abierto' : 'Abrir Caja',
            style: const TextStyle(
              color: _textoPrincipal,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            abierto
                ? 'Cuenta el efectivo fisico antes de cerrar el corte. El sistema comparara contra el balance esperado.'
                : 'Registra el fondo inicial para empezar el turno de caja.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textoPrincipal,
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: procesando
                  ? null
                  : abierto
                      ? onCerrar
                      : onAbrir,
              icon: Icon(
                abierto ? Icons.receipt_long_outlined : Icons.add,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                procesando
                    ? 'Procesando...'
                    : abierto
                        ? 'Cerrar Corte'
                        : 'Abrir Corte',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: abierto ? _verdeOscuro : _azul,
                elevation: 8,
                shadowColor: _verdeOscuro.withValues(alpha: 0.25),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeEstadoCorte extends StatelessWidget {
  final String estado;

  const _BadgeEstadoCorte({
    required this.estado,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5DD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        estado.isEmpty ? 'ABIERTO' : estado,
        style: const TextStyle(
          color: _verdeOscuro,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DatoCorte extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DatoCorte({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7F4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _bordeSuave),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _textoSecundario,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor ?? _textoPrincipal,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoCaja extends StatelessWidget {
  final String mensaje;
  final VoidCallback? onReintentar;

  const _EstadoCaja({
    required this.mensaje,
    this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 42),
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

class _DatosAbrirCorte {
  final double efectivoInicial;
  final double electronicoInicial;
  final String? observaciones;

  const _DatosAbrirCorte({
    required this.efectivoInicial,
    required this.electronicoInicial,
    required this.observaciones,
  });
}

class _DialogoAbrirCorte extends StatefulWidget {
  const _DialogoAbrirCorte();

  @override
  State<_DialogoAbrirCorte> createState() => _DialogoAbrirCorteState();
}

class _DialogoAbrirCorteState extends State<_DialogoAbrirCorte> {
  final TextEditingController _efectivoController =
      TextEditingController(text: '0');
  final TextEditingController _electronicoController =
      TextEditingController(text: '0');
  final TextEditingController _observacionesController =
      TextEditingController();
  String? _error;

  @override
  void dispose() {
    _efectivoController.dispose();
    _electronicoController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  void _confirmar() {
    final efectivo = double.tryParse(_efectivoController.text.trim());
    final electronico = double.tryParse(_electronicoController.text.trim());

    if (efectivo == null ||
        electronico == null ||
        efectivo < 0 ||
        electronico < 0) {
      setState(() {
        _error = 'Ingresa montos validos';
      });
      return;
    }

    Navigator.of(context).pop(
      _DatosAbrirCorte(
        efectivoInicial: efectivo,
        electronicoInicial: electronico,
        observaciones: _observacionesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _DialogoCorteBase(
      titulo: 'Abrir corte',
      error: _error,
      onConfirmar: _confirmar,
      children: [
        _CampoMonto(label: 'Efectivo inicial', controller: _efectivoController),
        const SizedBox(height: 12),
        _CampoMonto(
          label: 'Electronico inicial',
          controller: _electronicoController,
        ),
        const SizedBox(height: 12),
        _CampoObservaciones(controller: _observacionesController),
      ],
    );
  }
}

class _DatosCerrarCorte {
  final double efectivoContado;
  final double electronicoContado;
  final String? observaciones;

  const _DatosCerrarCorte({
    required this.efectivoContado,
    required this.electronicoContado,
    required this.observaciones,
  });
}

class _DatosMovimientoCaja {
  final String medio;
  final String tipo;
  final String concepto;
  final double monto;
  final String? observaciones;

  const _DatosMovimientoCaja({
    required this.medio,
    required this.tipo,
    required this.concepto,
    required this.monto,
    required this.observaciones,
  });
}

class _DialogoMovimientoCaja extends StatefulWidget {
  const _DialogoMovimientoCaja();

  @override
  State<_DialogoMovimientoCaja> createState() => _DialogoMovimientoCajaState();
}

class _DialogoMovimientoCajaState extends State<_DialogoMovimientoCaja> {
  static const List<String> _medios = ['EFECTIVO', 'ELECTRONICO'];
  static const List<String> _tipos = ['ENTRADA', 'SALIDA'];
  static const List<String> _conceptos = [
    'RETIRO_CAJA',
    'AJUSTE',
    'DEPOSITO_YASTAS',
    'CANCELACION',
    'OTRO',
  ];

  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _observacionesController =
      TextEditingController();
  String _medio = _medios.first;
  String _tipo = _tipos.first;
  String _concepto = _conceptos.first;
  String? _error;

  @override
  void dispose() {
    _montoController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  void _confirmar() {
    final monto = double.tryParse(_montoController.text.trim());

    if (monto == null || monto <= 0) {
      setState(() {
        _error = 'Ingresa un monto mayor a cero';
      });
      return;
    }

    Navigator.of(context).pop(
      _DatosMovimientoCaja(
        medio: _medio,
        tipo: _tipo,
        concepto: _concepto,
        monto: monto,
        observaciones: _observacionesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _DialogoCorteBase(
      titulo: 'Nuevo movimiento',
      error: _error,
      onConfirmar: _confirmar,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _medio,
          decoration: const InputDecoration(
            labelText: 'Medio',
            border: OutlineInputBorder(),
          ),
          items: _medios
              .map((medio) => DropdownMenuItem(
                    value: medio,
                    child: Text(_etiquetaConcepto(medio)),
                  ))
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _medio = value;
            });
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _tipo,
          decoration: const InputDecoration(
            labelText: 'Tipo',
            border: OutlineInputBorder(),
          ),
          items: _tipos
              .map((tipo) => DropdownMenuItem(
                    value: tipo,
                    child: Text(_etiquetaConcepto(tipo)),
                  ))
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _tipo = value;
            });
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _concepto,
          decoration: const InputDecoration(
            labelText: 'Concepto',
            border: OutlineInputBorder(),
          ),
          items: _conceptos
              .map((concepto) => DropdownMenuItem(
                    value: concepto,
                    child: Text(_etiquetaConcepto(concepto)),
                  ))
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _concepto = value;
            });
          },
        ),
        const SizedBox(height: 12),
        _CampoMonto(label: 'Monto', controller: _montoController),
        const SizedBox(height: 12),
        _CampoObservaciones(controller: _observacionesController),
      ],
    );
  }
}

class _DialogoCerrarCorte extends StatefulWidget {
  final CorteResumen corte;

  const _DialogoCerrarCorte({
    required this.corte,
  });

  @override
  State<_DialogoCerrarCorte> createState() => _DialogoCerrarCorteState();
}

class _DialogoCerrarCorteState extends State<_DialogoCerrarCorte> {
  late final TextEditingController _efectivoController;
  late final TextEditingController _electronicoController;
  final TextEditingController _observacionesController =
      TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _efectivoController = TextEditingController(
      text: widget.corte.efectivoEsperado.toStringAsFixed(2),
    );
    _electronicoController = TextEditingController(
      text: widget.corte.electronicoEsperado.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _efectivoController.dispose();
    _electronicoController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  void _confirmar() {
    final efectivo = double.tryParse(_efectivoController.text.trim());
    final electronico = double.tryParse(_electronicoController.text.trim());

    if (efectivo == null ||
        electronico == null ||
        efectivo < 0 ||
        electronico < 0) {
      setState(() {
        _error = 'Ingresa montos validos';
      });
      return;
    }

    Navigator.of(context).pop(
      _DatosCerrarCorte(
        efectivoContado: efectivo,
        electronicoContado: electronico,
        observaciones: _observacionesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _DialogoCorteBase(
      titulo: 'Cerrar corte',
      error: _error,
      onConfirmar: _confirmar,
      children: [
        Text(
          'Esperado en efectivo: ${ConfigMoneda.formato(widget.corte.efectivoEsperado)}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        _CampoMonto(label: 'Efectivo contado', controller: _efectivoController),
        const SizedBox(height: 12),
        _CampoMonto(
          label: 'Electronico contado',
          controller: _electronicoController,
        ),
        const SizedBox(height: 12),
        _CampoObservaciones(controller: _observacionesController),
      ],
    );
  }
}

class _DialogoCorteBase extends StatelessWidget {
  final String titulo;
  final String? error;
  final List<Widget> children;
  final VoidCallback onConfirmar;

  const _DialogoCorteBase({
    required this.titulo,
    required this.error,
    required this.children,
    required this.onConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(titulo),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...children,
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(
                error!,
                style:
                    const TextStyle(color: _rojo, fontWeight: FontWeight.w800),
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
          onPressed: onConfirmar,
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}

class _CampoMonto extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _CampoMonto({
    required this.label,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _CampoObservaciones extends StatelessWidget {
  final TextEditingController controller;

  const _CampoObservaciones({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 2,
      decoration: const InputDecoration(
        labelText: 'Observaciones',
        border: OutlineInputBorder(),
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: _blanco,
    borderRadius: BorderRadius.circular(8),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

String _formatoFechaHora(DateTime? fecha) {
  if (fecha == null) return 'Sin fecha';

  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  final hora = fecha.hour.toString().padLeft(2, '0');
  final minuto = fecha.minute.toString().padLeft(2, '0');
  return '$dia/$mes/${fecha.year} $hora:$minuto';
}

String _etiquetaConcepto(String valor) {
  if (valor.isEmpty) return 'Sin concepto';

  return valor
      .toLowerCase()
      .split('_')
      .where((parte) => parte.isNotEmpty)
      .map((parte) => '${parte[0].toUpperCase()}${parte.substring(1)}')
      .join(' ');
}
