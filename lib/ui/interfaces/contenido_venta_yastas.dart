import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/servicios_yastas_api_service.dart';
import '../../utils/config_moneda.dart';

const Color _blanco = Color(0xFFFFFFFF);
const Color _verde = Color(0xFF6FD000);
const Color _verdeOscuro = Color(0xFF417A00);
const Color _texto = Color(0xFF101010);

class ContenidoVentaYastas extends StatefulWidget {
  final TextEditingController busquedaController;
  final ValueChanged<TarifaServicioYastas> onAgregar;

  const ContenidoVentaYastas({
    super.key,
    required this.busquedaController,
    required this.onAgregar,
  });

  @override
  State<ContenidoVentaYastas> createState() => _ContenidoVentaYastasState();
}

class _ContenidoVentaYastasState extends State<ContenidoVentaYastas> {
  final ServiciosYastasApiService _apiService = ServiciosYastasApiService();

  bool _cargando = true;
  String? _error;
  List<TarifaServicioYastas> _tarifas = [];

  @override
  void initState() {
    super.initState();
    _cargarTarifas();
  }

  List<TarifaServicioYastas> get _tarifasFiltradas {
    final texto = widget.busquedaController.text.trim().toLowerCase();

    if (texto.isEmpty) {
      return _tarifas;
    }

    return _tarifas.where((tarifa) {
      return tarifa.nombreServicio.toLowerCase().contains(texto) ||
          tarifa.tipoVisible.toLowerCase().contains(texto) ||
          tarifa.tipoServicio.toLowerCase().contains(texto);
    }).toList();
  }

  Future<void> _cargarTarifas() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final tarifas = await _apiService.listarTarifas();

      if (!mounted) return;

      setState(() {
        _tarifas = tarifas;
        _cargando = false;
      });
    } on ApiException catch (error) {
      _mostrarError(error.message);
    } catch (_) {
      _mostrarError('No se pudieron cargar los servicios Yastas');
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;

    setState(() {
      _error = mensaje;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                fontSize: 14,
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
            child: tarifas.isEmpty
                ? const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Text(
                      'No hay servicios Yastas para mostrar',
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
                    children: tarifas.map((tarifa) {
                      return _TarjetaServicioYastas(
                        tarifa: tarifa,
                        onAgregar: () => widget.onAgregar(tarifa),
                      );
                    }).toList(),
                  ),
          ),
        ),
      ),
    );
  }
}

class _TarjetaServicioYastas extends StatelessWidget {
  final TarifaServicioYastas tarifa;
  final VoidCallback onAgregar;

  const _TarjetaServicioYastas({
    required this.tarifa,
    required this.onAgregar,
  });

  @override
  Widget build(BuildContext context) {
    final monto = tarifa.montoBase > 0
        ? ConfigMoneda.formato(tarifa.montoBase)
        : 'Capturar';

    return Container(
      width: 150,
      height: 242,
      decoration: BoxDecoration(
        color: _blanco,
        borderRadius: BorderRadius.circular(7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(15, 16, 15, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ImagenServicioYastas(tipoServicio: tarifa.tipoServicio),
          const SizedBox(height: 16),
          Text(
            tarifa.nombreServicio,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _texto,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            tarifa.tipoVisible.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF333A42),
              fontSize: 6.8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          _DatoTarifa(
            etiqueta: 'Comision',
            valor: ConfigMoneda.formato(tarifa.comisionCliente),
          ),
          _DatoTarifa(
            etiqueta: 'Ganancia',
            valor: ConfigMoneda.formato(tarifa.gananciaFarmacia),
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  monto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _verdeOscuro,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              _BotonAgregar(onTap: onAgregar),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Servicio Yastas',
            style: TextStyle(
              color: _texto,
              fontSize: 6.6,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DatoTarifa extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _DatoTarifa({
    required this.etiqueta,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              etiqueta,
              style: const TextStyle(
                color: Color(0xFF707A83),
                fontSize: 7.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            valor,
            style: const TextStyle(
              color: _texto,
              fontSize: 7.2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagenServicioYastas extends StatelessWidget {
  final String tipoServicio;

  const _ImagenServicioYastas({
    required this.tipoServicio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 95,
      height: 95,
      decoration: BoxDecoration(
        color: _colorFondo(tipoServicio),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: Icon(
          _iconoServicio(tipoServicio),
          color: _colorIcono(tipoServicio),
          size: 45,
        ),
      ),
    );
  }

  Color _colorFondo(String tipo) {
    switch (tipo) {
      case 'RECARGA':
        return const Color(0xFFE8F1FF);
      case 'CFE':
        return const Color(0xFFFFF3D8);
      case 'TELMEX':
      case 'INTERNET':
      case 'IZZI':
        return const Color(0xFFEAF7DF);
      case 'RETIRO':
        return const Color(0xFFFFECE8);
      default:
        return const Color(0xFFF3F5F5);
    }
  }

  Color _colorIcono(String tipo) {
    switch (tipo) {
      case 'RECARGA':
        return const Color(0xFF0B63CE);
      case 'CFE':
        return const Color(0xFFB97900);
      case 'TELMEX':
      case 'INTERNET':
      case 'IZZI':
        return _verdeOscuro;
      case 'RETIRO':
        return const Color(0xFFB23B28);
      default:
        return const Color(0xFF6A7B84);
    }
  }

  IconData _iconoServicio(String tipo) {
    switch (tipo) {
      case 'RECARGA':
        return Icons.phone_android_outlined;
      case 'CFE':
        return Icons.flash_on_outlined;
      case 'TELMEX':
        return Icons.wifi_calling_3_outlined;
      case 'INTERNET':
        return Icons.router_outlined;
      case 'IZZI':
        return Icons.connected_tv_outlined;
      case 'RETIRO':
        return Icons.payments_outlined;
      case 'DEPOSITO':
        return Icons.account_balance_outlined;
      default:
        return Icons.point_of_sale_outlined;
    }
  }
}

class _BotonAgregar extends StatelessWidget {
  final VoidCallback onTap;

  const _BotonAgregar({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 4,
          shadowColor: _verde.withOpacity(.45),
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
