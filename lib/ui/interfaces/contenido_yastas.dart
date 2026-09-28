import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/servicios_yastas_api_service.dart';
import '../../utils/config_moneda.dart';
import 'menu_carta_yastas.dart';

const Color _blanco = Color(0xFFFFFFFF);
const Color _verdeOscuro = Color(0xFF2F6E00);
const Color _azul = Color(0xFF0B63CE);
const Color _texto = Color(0xFF101010);
const Color _textoSuave = Color(0xFF707A83);
const Color _grisLinea = Color(0xFFE0E0E0);

class ContenidoYastas extends StatefulWidget {
  const ContenidoYastas({super.key});

  @override
  State<ContenidoYastas> createState() => _ContenidoYastasState();
}

class _ContenidoYastasState extends State<ContenidoYastas> {
  final ServiciosYastasApiService _apiService = ServiciosYastasApiService();
  final TextEditingController _busquedaController = TextEditingController();

  bool _cargando = true;
  bool _guardandoTarifa = false;
  bool _mostrarMenuNuevaTarifa = false;

  String? _error;
  String _estadoTarifas = 'Activas';

  List<TarifaServicioYastas> _tarifas = [];

  @override
  void initState() {
    super.initState();

    _busquedaController.addListener(() {
      setState(() {});
    });

    _cargarTarifas();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  List<TarifaServicioYastas> get _tarifasFiltradas {
    final texto = _busquedaController.text.trim().toLowerCase();

    return _tarifas.where((tarifa) {
      final coincideEstado = switch (_estadoTarifas) {
        'Activas' => tarifa.activo,
        'Inactivas' => !tarifa.activo,
        _ => true,
      };

      if (!coincideEstado) {
        return false;
      }

      if (texto.isEmpty) {
        return true;
      }

      return tarifa.nombreServicio.toLowerCase().contains(texto) ||
          tarifa.tipoServicio.toLowerCase().contains(texto) ||
          tarifa.tipoVisible.toLowerCase().contains(texto);
    }).toList();
  }

  Future<void> _cargarTarifas() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final tarifas = await _apiService.listarTarifas(
        incluirInactivas: true,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _tarifas = tarifas;
        _cargando = false;
      });
    } on ApiException catch (error) {
      _mostrarError(error.message);
    } catch (_) {
      _mostrarError(
        'No se pudieron cargar las tarifas Yastas',
      );
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

  void _abrirMenuNuevaTarifa() {
    setState(() {
      _mostrarMenuNuevaTarifa = true;
    });
  }

  void _cerrarMenuNuevaTarifa() {
    setState(() {
      _mostrarMenuNuevaTarifa = false;
    });
  }

  Future<void> _guardarNuevaTarifa(
    DatosMenuTarifaYastas datos,
  ) async {
    setState(() {
      _guardandoTarifa = true;
    });

    try {
      await _apiService.crearTarifa(
        tipoServicio: datos.tipoServicio,
        nombreServicio: datos.nombreServicio,
        montoBase: 0,
        comisionCliente: datos.comisionCliente,
        comisionYastas: datos.comisionYastas,
        regaliaYastas: datos.regaliaYastas,
        gananciaFarmacia: datos.gananciaFarmacia,
      );

      await _cargarTarifas();

      if (!mounted) {
        return;
      }

      setState(() {
        _mostrarMenuNuevaTarifa = false;
        _guardandoTarifa = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tarifa creada.'),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _guardandoTarifa = false;
      });

      _mostrarSnack(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _guardandoTarifa = false;
      });

      _mostrarSnack(
        'No se pudo guardar la tarifa',
      );
    }
  }

  Future<void> _abrirFormularioEditar(
    TarifaServicioYastas tarifa,
  ) async {
    final datos = await showDialog<_DatosTarifaYastas>(
      context: context,
      builder: (context) {
        return _DialogoTarifaYastas(
          tarifa: tarifa,
        );
      },
    );

    if (datos == null) {
      return;
    }

    try {
      await _apiService.actualizarTarifa(
        idTarifa: tarifa.idTarifa,
        tipoServicio: datos.tipoServicio,
        nombreServicio: datos.nombreServicio,
        montoBase: 0,
        comisionCliente: datos.comisionCliente,
        comisionYastas: datos.comisionYastas,
        regaliaYastas: datos.regaliaYastas,
        gananciaFarmacia: datos.gananciaFarmacia,
      );

      await _cargarTarifas();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tarifa actualizada.'),
        ),
      );
    } on ApiException catch (error) {
      _mostrarSnack(error.message);
    } catch (_) {
      _mostrarSnack(
        'No se pudo guardar la tarifa',
      );
    }
  }

  Future<void> _cambiarEstado(
    TarifaServicioYastas tarifa,
  ) async {
    try {
      await _apiService.cambiarEstadoTarifa(
        idTarifa: tarifa.idTarifa,
        activo: !tarifa.activo,
      );

      await _cargarTarifas();
    } on ApiException catch (error) {
      _mostrarSnack(error.message);
    } catch (_) {
      _mostrarSnack(
        'No se pudo cambiar el estado de la tarifa',
      );
    }
  }

  void _mostrarSnack(String mensaje) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              28,
              24,
              28,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _EncabezadoYastas(
                  busquedaController: _busquedaController,
                  estadoSeleccionado: _estadoTarifas,
                  onEstadoChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _estadoTarifas = value;
                    });
                  },
                  onNuevo: _abrirMenuNuevaTarifa,
                  onActualizar: _cargarTarifas,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _construirContenido(),
                ),
              ],
            ),
          ),
        ),
        if (_mostrarMenuNuevaTarifa)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              0,
              20,
              14,
              20,
            ),
            child: MenuCartaYastas(
              guardando: _guardandoTarifa,
              onCerrar: _cerrarMenuNuevaTarifa,
              onGuardarTarifa: _guardarNuevaTarifa,
            ),
          ),
      ],
    );
  }

  Widget _construirContenido() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              style: const TextStyle(
                color: _texto,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _cargarTarifas,
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

    final tarifas = _tarifasFiltradas;

    if (tarifas.isEmpty) {
      return const Center(
        child: Text(
          'No hay tarifas Yastas para mostrar',
          style: TextStyle(
            color: _textoSuave,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: tarifas.length,
      separatorBuilder: (_, __) {
        return const SizedBox(
          height: 10,
        );
      },
      itemBuilder: (context, index) {
        final tarifa = tarifas[index];

        return _TarjetaTarifaYastas(
          tarifa: tarifa,
          onEditar: () {
            _abrirFormularioEditar(
              tarifa,
            );
          },
          onCambiarEstado: () {
            _cambiarEstado(
              tarifa,
            );
          },
        );
      },
    );
  }
}

class _EncabezadoYastas extends StatelessWidget {
  final TextEditingController busquedaController;
  final String estadoSeleccionado;
  final ValueChanged<String?> onEstadoChanged;
  final VoidCallback onNuevo;
  final VoidCallback onActualizar;

  const _EncabezadoYastas({
    required this.busquedaController,
    required this.estadoSeleccionado,
    required this.onEstadoChanged,
    required this.onNuevo,
    required this.onActualizar,
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
                'Yastas',
                style: TextStyle(
                  color: _texto,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Tarifas, comisiones, regalias y ganancias',
                style: TextStyle(
                  color: _textoSuave,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 260,
          height: 40,
          child: TextField(
            controller: busquedaController,
            decoration: const InputDecoration(
              prefixIcon: Icon(
                Icons.search,
                size: 18,
              ),
              hintText: 'Buscar tarifa',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 135,
          height: 40,
          child: DropdownButtonFormField<String>(
            initialValue: estadoSeleccionado,
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 9,
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'Activas',
                child: Text('Activas'),
              ),
              DropdownMenuItem(
                value: 'Inactivas',
                child: Text('Inactivas'),
              ),
              DropdownMenuItem(
                value: 'Todas',
                child: Text('Todas'),
              ),
            ],
            onChanged: onEstadoChanged,
          ),
        ),
        const SizedBox(width: 10),
        IconButton.filledTonal(
          onPressed: onActualizar,
          icon: const Icon(
            Icons.refresh,
          ),
          tooltip: 'Actualizar',
        ),
        const SizedBox(width: 10),
        FilledButton.icon(
          onPressed: onNuevo,
          icon: const Icon(
            Icons.add,
          ),
          label: const Text(
            'Nueva tarifa',
          ),
        ),
      ],
    );
  }
}

class _TarjetaTarifaYastas extends StatelessWidget {
  final TarifaServicioYastas tarifa;
  final VoidCallback onEditar;
  final VoidCallback onCambiarEstado;

  const _TarjetaTarifaYastas({
    required this.tarifa,
    required this.onEditar,
    required this.onCambiarEstado,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        16,
        14,
        16,
      ),
      decoration: BoxDecoration(
        color: _blanco,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _grisLinea,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              0.05,
            ),
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
              color: tarifa.activo
                  ? const Color(
                      0xFFEAF7DF,
                    )
                  : const Color(
                      0xFFECECEC,
                    ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _iconoServicio(
                tarifa.tipoServicio,
              ),
              color: tarifa.activo ? _verdeOscuro : _textoSuave,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tarifa.nombreServicio,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _texto,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${tarifa.tipoVisible} · '
                  '${tarifa.activo ? 'Activa' : 'Inactiva'}',
                  style: const TextStyle(
                    color: _textoSuave,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _MetricaTarifa(
            titulo: 'Com. cliente',
            valor: ConfigMoneda.formato(
              tarifa.comisionCliente,
            ),
          ),
          _MetricaTarifa(
            titulo: 'Com. Yastas',
            valor: ConfigMoneda.formato(
              tarifa.comisionYastas,
            ),
          ),
          _MetricaTarifa(
            titulo: 'Regalia',
            valor: ConfigMoneda.formato(
              tarifa.regaliaYastas,
            ),
          ),
          _MetricaTarifa(
            titulo: 'Ganancia',
            valor: ConfigMoneda.formato(
              tarifa.gananciaFarmacia,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onEditar,
            icon: const Icon(
              Icons.edit_outlined,
            ),
            iconSize: 18,
            color: _azul,
            tooltip: 'Editar',
          ),
          IconButton(
            onPressed: onCambiarEstado,
            icon: Icon(
              tarifa.activo
                  ? Icons.toggle_on_outlined
                  : Icons.toggle_off_outlined,
            ),
            iconSize: 26,
            color: tarifa.activo ? _verdeOscuro : const Color(0xFFE02020),
            tooltip: tarifa.activo ? 'Desactivar' : 'Activar',
          ),
        ],
      ),
    );
  }

  IconData _iconoServicio(String tipo) {
    switch (tipo) {
      case 'RECARGA':
        return Icons.phone_android_outlined;
      case 'RETIRO':
        return Icons.payments_outlined;
      case 'DEPOSITO':
        return Icons.account_balance_outlined;
      case 'CFE':
        return Icons.flash_on_outlined;
      case 'TELMEX':
      case 'INTERNET':
        return Icons.router_outlined;
      default:
        return Icons.point_of_sale_outlined;
    }
  }
}

class _MetricaTarifa extends StatelessWidget {
  final String titulo;
  final String valor;

  const _MetricaTarifa({
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 94,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: _textoSuave,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _texto,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DatosTarifaYastas {
  final String tipoServicio;
  final String nombreServicio;
  final double comisionCliente;
  final double comisionYastas;
  final double regaliaYastas;
  final double gananciaFarmacia;

  const _DatosTarifaYastas({
    required this.tipoServicio,
    required this.nombreServicio,
    required this.comisionCliente,
    required this.comisionYastas,
    required this.regaliaYastas,
    required this.gananciaFarmacia,
  });
}

class _DialogoTarifaYastas extends StatefulWidget {
  final TarifaServicioYastas tarifa;

  const _DialogoTarifaYastas({
    required this.tarifa,
  });

  @override
  State<_DialogoTarifaYastas> createState() => _DialogoTarifaYastasState();
}

class _DialogoTarifaYastasState extends State<_DialogoTarifaYastas> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _comisionClienteController =
      TextEditingController();
  final TextEditingController _comisionYastasController =
      TextEditingController();
  final TextEditingController _regaliaController = TextEditingController();

  late String _tipoServicio;
  String? _error;

  @override
  void initState() {
    super.initState();

    final tarifa = widget.tarifa;

    _tipoServicio = tarifa.tipoServicio;
    _nombreController.text = tarifa.nombreServicio;
    _comisionClienteController.text = tarifa.comisionCliente.toStringAsFixed(2);
    _comisionYastasController.text = tarifa.comisionYastas.toStringAsFixed(2);
    _regaliaController.text = tarifa.regaliaYastas.toStringAsFixed(2);

    _comisionClienteController.addListener(_actualizarVista);
    _comisionYastasController.addListener(_actualizarVista);
    _regaliaController.addListener(_actualizarVista);
  }

  @override
  void dispose() {
    _comisionClienteController.removeListener(_actualizarVista);
    _comisionYastasController.removeListener(_actualizarVista);
    _regaliaController.removeListener(_actualizarVista);

    _nombreController.dispose();
    _comisionClienteController.dispose();
    _comisionYastasController.dispose();
    _regaliaController.dispose();

    super.dispose();
  }

  void _actualizarVista() {
    if (!mounted) return;

    setState(() {});
  }

  double? _leerMonto(TextEditingController controller) {
    final texto = controller.text
        .trim()
        .replaceAll('\$', '')
        .replaceAll(' ', '')
        .replaceAll(',', '.');

    if (texto.isEmpty) {
      return 0;
    }

    return double.tryParse(texto);
  }

  double get _comisionCliente {
    return _leerMonto(_comisionClienteController) ?? 0;
  }

  double get _comisionYastas {
    return _leerMonto(_comisionYastasController) ?? 0;
  }

  double get _regaliaYastas {
    return _leerMonto(_regaliaController) ?? 0;
  }

  double get _gananciaFarmacia {
    final ganancia = _comisionCliente - _comisionYastas - _regaliaYastas;

    return ganancia < 0 ? 0 : ganancia;
  }

  void _guardar() {
    final nombre = _nombreController.text.trim();

    final comisionCliente = _leerMonto(
      _comisionClienteController,
    );

    final comisionYastas = _leerMonto(
      _comisionYastasController,
    );

    final regalia = _leerMonto(
      _regaliaController,
    );

    final ganancia = _gananciaFarmacia;

    if (nombre.isEmpty) {
      setState(() {
        _error = 'El nombre del servicio es obligatorio';
      });

      return;
    }

    if ([
      comisionCliente,
      comisionYastas,
      regalia,
    ].any(
      (value) => value == null || value < 0,
    )) {
      setState(() {
        _error = 'Los importes deben ser numeros mayores o iguales a cero';
      });

      return;
    }

    final reparto = comisionYastas! + regalia!;

    if (reparto > comisionCliente! + 0.005) {
      setState(() {
        _error =
            'La comisión Yastas y la regalía no pueden superar la comisión cobrada al cliente';
      });

      return;
    }

    Navigator.of(context).pop(
      _DatosTarifaYastas(
        tipoServicio: _tipoServicio,
        nombreServicio: nombre,
        comisionCliente: comisionCliente,
        comisionYastas: comisionYastas,
        regaliaYastas: regalia,
        gananciaFarmacia: ganancia,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 460,
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: _blanco,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _EncabezadoEditarTarifa(
                onCerrar: () {
                  Navigator.of(context).pop();
                },
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    18,
                    18,
                    16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CampoDropdownEditarTarifa(
                        etiqueta: 'TIPO DE SERVICIO',
                        requerido: true,
                        valor: _tipoServicio,
                        opciones: const [
                          DropdownMenuItem(
                            value: 'RECARGA',
                            child: Text('Recarga telefónica / Tiempo Aire'),
                          ),
                          DropdownMenuItem(
                            value: 'DEPOSITO',
                            child: Text('Depósito'),
                          ),
                          DropdownMenuItem(
                            value: 'RETIRO',
                            child: Text('Retiro'),
                          ),
                          DropdownMenuItem(
                            value: 'PAGO_SERVICIO',
                            child: Text('Pago de servicio'),
                          ),
                          DropdownMenuItem(
                            value: 'CFE',
                            child: Text('CFE'),
                          ),
                          DropdownMenuItem(
                            value: 'TELMEX',
                            child: Text('Telmex'),
                          ),
                          DropdownMenuItem(
                            value: 'IZZI',
                            child: Text('Izzi'),
                          ),
                          DropdownMenuItem(
                            value: 'INTERNET',
                            child: Text('Internet'),
                          ),
                          DropdownMenuItem(
                            value: 'OTRO',
                            child: Text('Otro'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setState(() {
                            _tipoServicio = value;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      _CampoTextoEditarTarifa(
                        etiqueta: 'NOMBRE DEL SERVICIO',
                        requerido: true,
                        controller: _nombreController,
                        hintText: 'Ej: Recarga Telcel',
                      ),
                      const SizedBox(height: 14),
                      _CampoDineroEditarTarifa(
                        etiqueta: 'COMISIÓN COBRADA AL CLIENTE',
                        requerido: true,
                        controller: _comisionClienteController,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _CampoDineroEditarTarifa(
                              etiqueta: 'COMISIÓN YASTÁS',
                              controller: _comisionYastasController,
                              mostrarInfo: true,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _CampoDineroEditarTarifa(
                              etiqueta: 'REGALÍA YASTÁS',
                              controller: _regaliaController,
                              mostrarInfo: true,
                            ),
                          ),
                        ],
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        _MensajeErrorEditarTarifa(
                          mensaje: _error!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              _AccionesEditarTarifa(
                onGuardar: _guardar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EncabezadoEditarTarifa extends StatelessWidget {
  final VoidCallback onCerrar;

  const _EncabezadoEditarTarifa({
    required this.onCerrar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        16,
        12,
        15,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFBFAF9),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE9EEF3),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE6FFF0),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFC3F1D4),
              ),
            ),
            child: const Icon(
              Icons.monetization_on_outlined,
              color: _verdeOscuro,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editar Tarifa de Servicio',
                  style: TextStyle(
                    color: _texto,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Configuración de cobro, regalías Yastás y margen de farmacia',
                  style: TextStyle(
                    color: _textoSuave,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCerrar,
            icon: const Icon(
              Icons.close,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }
}

class _CampoTextoEditarTarifa extends StatelessWidget {
  final String etiqueta;
  final bool requerido;
  final TextEditingController controller;
  final String? hintText;

  const _CampoTextoEditarTarifa({
    required this.etiqueta,
    required this.controller,
    this.requerido = false,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return _ContenedorCampoEditarTarifa(
      etiqueta: etiqueta,
      requerido: requerido,
      child: TextField(
        controller: controller,
        cursorColor: _verdeOscuro,
        style: const TextStyle(
          color: _texto,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        decoration: _decoracionEditarTarifa(
          hintText: hintText,
        ),
      ),
    );
  }
}

class _CampoDineroEditarTarifa extends StatelessWidget {
  final String etiqueta;
  final bool requerido;
  final bool mostrarInfo;
  final TextEditingController controller;

  const _CampoDineroEditarTarifa({
    required this.etiqueta,
    required this.controller,
    this.requerido = false,
    this.mostrarInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    return _ContenedorCampoEditarTarifa(
      etiqueta: etiqueta,
      requerido: requerido,
      mostrarInfo: mostrarInfo,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
        ),
        cursorColor: _verdeOscuro,
        style: const TextStyle(
          color: _texto,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
        decoration: _decoracionEditarTarifa(
          prefixIcon: const Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 8,
            ),
            child: Text(
              '\$',
              style: TextStyle(
                color: _textoSuave,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          suffixText: 'MXN',
        ),
      ),
    );
  }
}

class _CampoDropdownEditarTarifa extends StatelessWidget {
  final String etiqueta;
  final bool requerido;
  final String valor;
  final List<DropdownMenuItem<String>> opciones;
  final ValueChanged<String?> onChanged;

  const _CampoDropdownEditarTarifa({
    required this.etiqueta,
    required this.valor,
    required this.opciones,
    required this.onChanged,
    this.requerido = false,
  });

  @override
  Widget build(BuildContext context) {
    return _ContenedorCampoEditarTarifa(
      etiqueta: etiqueta,
      requerido: requerido,
      child: DropdownButtonFormField<String>(
        initialValue: valor,
        isExpanded: true,
        icon: const Icon(
          Icons.keyboard_arrow_down,
          color: _textoSuave,
          size: 18,
        ),
        decoration: _decoracionEditarTarifa(),
        style: const TextStyle(
          color: _texto,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        items: opciones,
        onChanged: onChanged,
      ),
    );
  }
}

class _ContenedorCampoEditarTarifa extends StatelessWidget {
  final String etiqueta;
  final bool requerido;
  final bool mostrarInfo;
  final Widget child;

  const _ContenedorCampoEditarTarifa({
    required this.etiqueta,
    required this.child,
    this.requerido = false,
    this.mostrarInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              etiqueta,
              style: const TextStyle(
                color: _textoSuave,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
            if (requerido) ...[
              const SizedBox(width: 3),
              const Text(
                '*',
                style: TextStyle(
                  color: Color(0xFFE21F1F),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
            if (mostrarInfo) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.info_outline,
                color: _textoSuave,
                size: 12,
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _MensajeErrorEditarTarifa extends StatelessWidget {
  final String mensaje;

  const _MensajeErrorEditarTarifa({
    required this.mensaje,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEAEA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFFC9C9),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFE21F1F),
            size: 16,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(
                color: Color(0xFFE21F1F),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccionesEditarTarifa extends StatelessWidget {
  final VoidCallback onGuardar;

  const _AccionesEditarTarifa({
    required this.onGuardar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.fromLTRB(
        18,
        11,
        18,
        12,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFBFAF9),
        border: Border(
          top: BorderSide(
            color: Color(0xFFE9EEF3),
          ),
        ),
      ),
      child: Row(
        children: [
          const Spacer(),
          SizedBox(
            width: 190,
            height: 42,
            child: ElevatedButton(
              onPressed: onGuardar,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3A7608),
                foregroundColor: Colors.white,
                elevation: 6,
                shadowColor: const Color(0xFF3A7608).withOpacity(0.28),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Guardar Cambios',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _decoracionEditarTarifa({
  String? hintText,
  Widget? prefixIcon,
  String? suffixText,
}) {
  return InputDecoration(
    filled: true,
    fillColor: _blanco,
    hintText: hintText,
    hintStyle: const TextStyle(
      color: _textoSuave,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    ),
    prefixIcon: prefixIcon,
    prefixIconConstraints: const BoxConstraints(
      minWidth: 32,
      minHeight: 0,
    ),
    suffixText: suffixText,
    suffixStyle: const TextStyle(
      color: _textoSuave,
      fontSize: 10,
      fontWeight: FontWeight.w900,
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 11,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(
        color: Color(0xFFD8E0E8),
        width: 1,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(
        color: Color(0xFFD8E0E8),
        width: 1,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(
        color: _verdeOscuro,
        width: 1.2,
      ),
    ),
  );
}
