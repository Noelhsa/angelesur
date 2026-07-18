import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/servicios_yastas_api_service.dart';
import '../../utils/config_moneda.dart';
import 'menu_carta_yastas.dart';

const Color _blanco = Color(0xFFFFFFFF);
const Color _verdeOscuro = Color(0xFF2F6E00);
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

    if (texto.isEmpty) {
      return _tarifas;
    }

    return _tarifas.where((tarifa) {
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

      if (!mounted) return;

      setState(() {
        _tarifas = tarifas;
        _cargando = false;
      });
    } on ApiException catch (error) {
      _mostrarError(error.message);
    } catch (_) {
      _mostrarError('No se pudieron cargar las tarifas Yastas');
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;

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

  Future<void> _guardarNuevaTarifa(DatosMenuTarifaYastas datos) async {
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

      if (!mounted) return;

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
      if (!mounted) return;

      setState(() {
        _guardandoTarifa = false;
      });

      _mostrarSnack(error.message);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _guardandoTarifa = false;
      });

      _mostrarSnack('No se pudo guardar la tarifa');
    }
  }

  Future<void> _abrirFormularioEditar(TarifaServicioYastas tarifa) async {
    final datos = await showDialog<_DatosTarifaYastas>(
      context: context,
      builder: (context) => _DialogoTarifaYastas(tarifa: tarifa),
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

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tarifa actualizada.'),
        ),
      );
    } on ApiException catch (error) {
      _mostrarSnack(error.message);
    } catch (_) {
      _mostrarSnack('No se pudo guardar la tarifa');
    }
  }

  Future<void> _cambiarEstado(TarifaServicioYastas tarifa) async {
    try {
      await _apiService.cambiarEstadoTarifa(
        idTarifa: tarifa.idTarifa,
        activo: !tarifa.activo,
      );
      await _cargarTarifas();
    } on ApiException catch (error) {
      _mostrarSnack(error.message);
    } catch (_) {
      _mostrarSnack('No se pudo cambiar el estado de la tarifa');
    }
  }

  void _mostrarSnack(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _EncabezadoYastas(
                  busquedaController: _busquedaController,
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
            padding: const EdgeInsets.fromLTRB(0, 20, 14, 20),
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
      return const Center(child: CircularProgressIndicator());
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
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
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
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final tarifa = tarifas[index];
        return _TarjetaTarifaYastas(
          tarifa: tarifa,
          onEditar: () => _abrirFormularioEditar(tarifa),
          onCambiarEstado: () => _cambiarEstado(tarifa),
        );
      },
    );
  }
}

class _EncabezadoYastas extends StatelessWidget {
  final TextEditingController busquedaController;
  final VoidCallback onNuevo;
  final VoidCallback onActualizar;

  const _EncabezadoYastas({
    required this.busquedaController,
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
              prefixIcon: Icon(Icons.search, size: 18),
              hintText: 'Buscar tarifa',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton.filledTonal(
          onPressed: onActualizar,
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualizar',
        ),
        const SizedBox(width: 10),
        FilledButton.icon(
          onPressed: onNuevo,
          icon: const Icon(Icons.add),
          label: const Text('Nueva tarifa'),
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
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
      decoration: BoxDecoration(
        color: _blanco,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _grisLinea),
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
              color: tarifa.activo
                  ? const Color(0xFFEAF7DF)
                  : const Color(0xFFECECEC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _iconoServicio(tarifa.tipoServicio),
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
                  '${tarifa.tipoVisible} · ${tarifa.activo ? 'Activa' : 'Inactiva'}',
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
            valor: ConfigMoneda.formato(tarifa.comisionCliente),
          ),
          _MetricaTarifa(
            titulo: 'Com. Yastas',
            valor: ConfigMoneda.formato(tarifa.comisionYastas),
          ),
          _MetricaTarifa(
            titulo: 'Regalia',
            valor: ConfigMoneda.formato(tarifa.regaliaYastas),
          ),
          _MetricaTarifa(
            titulo: 'Ganancia',
            valor: ConfigMoneda.formato(tarifa.gananciaFarmacia),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onEditar,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
          ),
          IconButton(
            onPressed: onCambiarEstado,
            icon: Icon(
              tarifa.activo
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
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
  final TextEditingController _gananciaController = TextEditingController();

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
    _gananciaController.text = tarifa.gananciaFarmacia.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _comisionClienteController.dispose();
    _comisionYastasController.dispose();
    _regaliaController.dispose();
    _gananciaController.dispose();
    super.dispose();
  }

  void _guardar() {
    final nombre = _nombreController.text.trim();
    final comisionCliente = _leerMonto(_comisionClienteController);
    final comisionYastas = _leerMonto(_comisionYastasController);
    final regalia = _leerMonto(_regaliaController);
    final ganancia = _leerMonto(_gananciaController);

    if (nombre.isEmpty) {
      setState(() {
        _error = 'El nombre del servicio es obligatorio';
      });
      return;
    }

    if ([comisionCliente, comisionYastas, regalia, ganancia]
        .any((value) => value == null || value < 0)) {
      setState(() {
        _error = 'Los importes deben ser numeros mayores o iguales a cero';
      });
      return;
    }

    final reparto = comisionYastas! + regalia! + ganancia!;
    if (reparto > comisionCliente! + 0.005) {
      setState(() {
        _error = 'El reparto no puede superar la comision cobrada al cliente';
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

  double? _leerMonto(TextEditingController controller) {
    return double.tryParse(controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar tarifa'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _tipoServicio,
                decoration: const InputDecoration(
                  labelText: 'Tipo de servicio',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'RECARGA', child: Text('Recarga')),
                  DropdownMenuItem(value: 'DEPOSITO', child: Text('Deposito')),
                  DropdownMenuItem(value: 'RETIRO', child: Text('Retiro')),
                  DropdownMenuItem(
                    value: 'PAGO_SERVICIO',
                    child: Text('Pago de servicio'),
                  ),
                  DropdownMenuItem(value: 'CFE', child: Text('CFE')),
                  DropdownMenuItem(value: 'TELMEX', child: Text('Telmex')),
                  DropdownMenuItem(value: 'IZZI', child: Text('Izzi')),
                  DropdownMenuItem(value: 'INTERNET', child: Text('Internet')),
                  DropdownMenuItem(value: 'OTRO', child: Text('Otro')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _tipoServicio = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del servicio',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              _CampoDinero(
                controller: _comisionClienteController,
                label: 'Comision cliente',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _CampoDinero(
                      controller: _comisionYastasController,
                      label: 'Comision Yastas',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CampoDinero(
                      controller: _regaliaController,
                      label: 'Regalia Yastas',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _CampoDinero(
                controller: _gananciaController,
                label: 'Ganancia farmacia',
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFFE21F1F),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardar,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _CampoDinero extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _CampoDinero({
    required this.controller,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixText: '\$',
      ),
    );
  }
}
