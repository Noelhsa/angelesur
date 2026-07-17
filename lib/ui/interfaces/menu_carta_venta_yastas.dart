import 'package:flutter/material.dart';

import '../../models/medicamento.dart';
import '../../services/servicios_yastas_api_service.dart';
import '../../utils/config_moneda.dart';

class ServicioYastasCarrito {
  final int idCarrito;
  final TarifaServicioYastas tarifa;
  final double montoServicio;
  final String? referenciaOperacion;
  final String? observaciones;

  const ServicioYastasCarrito({
    required this.idCarrito,
    required this.tarifa,
    required this.montoServicio,
    required this.referenciaOperacion,
    required this.observaciones,
  });

  double get totalCobrado => tarifa.totalCobrado(montoServicio);

  Medicamento get medicamento {
    return Medicamento(
      id: idCarrito,
      nombre: tarifa.nombreServicio,
      detalle: [
        tarifa.tipoVisible,
        if (referenciaOperacion != null && referenciaOperacion!.isNotEmpty)
          'Ref. $referenciaOperacion',
      ].join(' - '),
      categoria: 'Yastas',
      precio: totalCobrado,
      stock: 1,
    );
  }
}

class DatosServicioYastas {
  final double montoServicio;
  final String? referenciaOperacion;
  final String? observaciones;

  const DatosServicioYastas({
    required this.montoServicio,
    required this.referenciaOperacion,
    required this.observaciones,
  });
}

class DialogoServicioYastas extends StatefulWidget {
  final TarifaServicioYastas tarifa;

  const DialogoServicioYastas({
    super.key,
    required this.tarifa,
  });

  @override
  State<DialogoServicioYastas> createState() => _DialogoServicioYastasState();
}

class _DialogoServicioYastasState extends State<DialogoServicioYastas> {
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();
  final TextEditingController _observacionesController =
      TextEditingController();

  String? _error;

  double get _montoServicio {
    return double.tryParse(_montoController.text.trim()) ?? 0;
  }

  double get _totalCobrado {
    return widget.tarifa.totalCobrado(_montoServicio);
  }

  @override
  void initState() {
    super.initState();
    _montoController.text = widget.tarifa.montoBase > 0
        ? widget.tarifa.montoBase.toStringAsFixed(2)
        : '';
    _montoController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _montoController.dispose();
    _referenciaController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  void _confirmar() {
    final montoServicio = double.tryParse(_montoController.text.trim());

    if (montoServicio == null || montoServicio <= 0) {
      setState(() {
        _error = 'El monto del servicio debe ser mayor que cero';
      });
      return;
    }

    Navigator.of(context).pop(
      DatosServicioYastas(
        montoServicio: montoServicio,
        referenciaOperacion: _cleanOptional(_referenciaController.text),
        observaciones: _cleanOptional(_observacionesController.text),
      ),
    );
  }

  String? _cleanOptional(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.tarifa.nombreServicio),
      content: SizedBox(
        width: 390,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.tarifa.tipoVisible,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _montoController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Monto del servicio',
                border: OutlineInputBorder(),
                prefixText: '\$',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _referenciaController,
              decoration: const InputDecoration(
                labelText: 'Referencia / telefono / contrato',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _observacionesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Observaciones',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            _ResumenYastas(
              montoServicio: _montoServicio,
              comisionCliente: widget.tarifa.comisionCliente,
              comisionYastas: widget.tarifa.comisionYastas,
              regaliaYastas: widget.tarifa.regaliaYastas,
              gananciaFarmacia: widget.tarifa.gananciaFarmacia,
              totalCobrado: _totalCobrado,
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(
                  color: Color(0xFFE21F1F),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
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
        FilledButton(
          onPressed: _confirmar,
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}

class _ResumenYastas extends StatelessWidget {
  final double montoServicio;
  final double comisionCliente;
  final double comisionYastas;
  final double regaliaYastas;
  final double gananciaFarmacia;
  final double totalCobrado;

  const _ResumenYastas({
    required this.montoServicio,
    required this.comisionCliente,
    required this.comisionYastas,
    required this.regaliaYastas,
    required this.gananciaFarmacia,
    required this.totalCobrado,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F4),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFD9E3D0)),
      ),
      child: Column(
        children: [
          _FilaResumenYastas(
            etiqueta: 'Monto servicio',
            valor: ConfigMoneda.formato(montoServicio),
          ),
          _FilaResumenYastas(
            etiqueta: 'Comision cliente',
            valor: ConfigMoneda.formato(comisionCliente),
          ),
          _FilaResumenYastas(
            etiqueta: 'Comision Yastas',
            valor: ConfigMoneda.formato(comisionYastas),
          ),
          _FilaResumenYastas(
            etiqueta: 'Regalia',
            valor: ConfigMoneda.formato(regaliaYastas),
          ),
          _FilaResumenYastas(
            etiqueta: 'Ganancia farmacia',
            valor: ConfigMoneda.formato(gananciaFarmacia),
          ),
          const Divider(height: 18),
          _FilaResumenYastas(
            etiqueta: 'Total al cliente',
            valor: ConfigMoneda.formato(totalCobrado),
            destacado: true,
          ),
        ],
      ),
    );
  }
}

class _FilaResumenYastas extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final bool destacado;

  const _FilaResumenYastas({
    required this.etiqueta,
    required this.valor,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              etiqueta,
              style: TextStyle(
                fontSize: destacado ? 13 : 11,
                fontWeight: destacado ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              fontSize: destacado ? 13 : 11,
              fontWeight: destacado ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
