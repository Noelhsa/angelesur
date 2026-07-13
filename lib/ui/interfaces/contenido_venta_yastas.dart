import 'package:flutter/material.dart';

import '../../models/medicamento.dart';
import '../../utils/config_moneda.dart';

const Color _blanco = Color(0xFFFFFFFF);
const Color _verde = Color(0xFF6FD000);
const Color _verdeOscuro = Color(0xFF417A00);
const Color _texto = Color(0xFF101010);

const List<Medicamento> serviciosYastas = [
  Medicamento(
    id: -1001,
    nombre: 'Recarga \$50',
    detalle: 'YASTAS - TIEMPO AIRE',
    categoria: 'Yastas',
    precio: 50,
    stock: 9999,
  ),
  Medicamento(
    id: -1002,
    nombre: 'Recarga \$100',
    detalle: 'YASTAS - TIEMPO AIRE',
    categoria: 'Yastas',
    precio: 100,
    stock: 9999,
  ),
  Medicamento(
    id: -1003,
    nombre: 'Pago CFE',
    detalle: 'YASTAS - SERVICIO',
    categoria: 'Yastas',
    precio: 0,
    stock: 9999,
  ),
  Medicamento(
    id: -1004,
    nombre: 'Pago Telmex',
    detalle: 'YASTAS - SERVICIO',
    categoria: 'Yastas',
    precio: 0,
    stock: 9999,
  ),
  Medicamento(
    id: -1005,
    nombre: 'Pago de agua',
    detalle: 'YASTAS - SERVICIO',
    categoria: 'Yastas',
    precio: 0,
    stock: 9999,
  ),
  Medicamento(
    id: -1006,
    nombre: 'Pago internet',
    detalle: 'YASTAS - SERVICIO',
    categoria: 'Yastas',
    precio: 0,
    stock: 9999,
  ),
  Medicamento(
    id: -1007,
    nombre: 'Pago SKY',
    detalle: 'YASTAS - SERVICIO',
    categoria: 'Yastas',
    precio: 0,
    stock: 9999,
  ),
  Medicamento(
    id: -1008,
    nombre: 'Pago Megacable',
    detalle: 'YASTAS - SERVICIO',
    categoria: 'Yastas',
    precio: 0,
    stock: 9999,
  ),
];

class ContenidoVentaYastas extends StatelessWidget {
  final TextEditingController busquedaController;
  final ValueChanged<Medicamento> onAgregar;

  const ContenidoVentaYastas({
    super.key,
    required this.busquedaController,
    required this.onAgregar,
  });

  List<Medicamento> get _serviciosFiltrados {
    final texto = busquedaController.text.trim().toLowerCase();

    if (texto.isEmpty) {
      return serviciosYastas;
    }

    return serviciosYastas.where((servicio) {
      return servicio.nombre.toLowerCase().contains(texto) ||
          servicio.detalle.toLowerCase().contains(texto) ||
          servicio.categoria.toLowerCase().contains(texto);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final servicios = _serviciosFiltrados;

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
            child: servicios.isEmpty
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
                    children: servicios.map((servicio) {
                      return _TarjetaServicioYastas(
                        servicio: servicio,
                        onAgregar: () => onAgregar(servicio),
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
  final Medicamento servicio;
  final VoidCallback onAgregar;

  const _TarjetaServicioYastas({
    required this.servicio,
    required this.onAgregar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 136,
      height: 225,
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
          _ImagenServicioYastas(servicioId: servicio.id),
          const SizedBox(height: 20),
          Text(
            servicio.nombre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _texto,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            servicio.detalle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF333A42),
              fontSize: 6.8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  servicio.precio <= 0
                      ? 'Capturar'
                      : ConfigMoneda.formato(servicio.precio),
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

class _ImagenServicioYastas extends StatelessWidget {
  final int servicioId;

  const _ImagenServicioYastas({
    required this.servicioId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 95,
      height: 95,
      decoration: BoxDecoration(
        color: _colorFondo(servicioId),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: Icon(
          _iconoServicio(servicioId),
          color: _colorIcono(servicioId),
          size: 45,
        ),
      ),
    );
  }

  Color _colorFondo(int id) {
    switch (id) {
      case -1001:
      case -1002:
        return const Color(0xFFE8F1FF);
      case -1003:
        return const Color(0xFFFFF3D8);
      case -1004:
      case -1006:
        return const Color(0xFFEAF7DF);
      default:
        return const Color(0xFFF3F5F5);
    }
  }

  Color _colorIcono(int id) {
    switch (id) {
      case -1001:
      case -1002:
        return const Color(0xFF0B63CE);
      case -1003:
        return const Color(0xFFB97900);
      case -1004:
      case -1006:
        return _verdeOscuro;
      default:
        return const Color(0xFF6A7B84);
    }
  }

  IconData _iconoServicio(int id) {
    switch (id) {
      case -1001:
      case -1002:
        return Icons.phone_android_outlined;
      case -1003:
        return Icons.flash_on_outlined;
      case -1004:
        return Icons.wifi_calling_3_outlined;
      case -1005:
        return Icons.water_drop_outlined;
      case -1006:
        return Icons.router_outlined;
      case -1007:
        return Icons.tv_outlined;
      case -1008:
        return Icons.connected_tv_outlined;
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