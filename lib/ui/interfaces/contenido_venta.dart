import 'package:flutter/material.dart';

import '../../models/medicamento.dart';
import '../../services/servicios_yastas_api_service.dart';
import '../../utils/config_moneda.dart';
import 'contenido_venta_yastas.dart';

const Color _blanco = Color(0xFFFFFFFF);
const Color _verde = Color(0xFF6FD000);
const Color _verdeOscuro = Color(0xFF417A00);
const Color _texto = Color(0xFF101010);

class ContenidoVenta extends StatefulWidget {
  final TextEditingController busquedaController;
  final List<Medicamento> medicamentos;
  final ValueChanged<Medicamento> onAgregar;
  final ValueChanged<TarifaServicioYastas> onAgregarYastas;

  const ContenidoVenta({
    super.key,
    required this.busquedaController,
    required this.medicamentos,
    required this.onAgregar,
    required this.onAgregarYastas,
  });

  @override
  State<ContenidoVenta> createState() => _ContenidoVentaState();
}

class _ContenidoVentaState extends State<ContenidoVenta> {
  String _seccionSeleccionada = 'Medicamentos';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BarraSuperiorVenta(
          busquedaController: widget.busquedaController,
          seccionSeleccionada: _seccionSeleccionada,
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
                  onAgregar: widget.onAgregar,
                ),
        ),
      ],
    );
  }
}

class _BarraSuperiorVenta extends StatelessWidget {
  final TextEditingController busquedaController;
  final String seccionSeleccionada;
  final ValueChanged<String> onSeleccionarSeccion;

  const _BarraSuperiorVenta({
    required this.busquedaController,
    required this.seccionSeleccionada,
    required this.onSeleccionarSeccion,
  });

  @override
  Widget build(BuildContext context) {
    final esYastas = seccionSeleccionada == 'Yastas';

    return Container(
      height: 78,
      padding: const EdgeInsets.only(left: 28, top: 20, right: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 310,
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
                  color: Colors.black.withOpacity(0.04),
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
                      cursorColor: _verdeOscuro,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        color: _texto,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: esYastas
                            ? 'Buscar servicio...'
                            : 'Buscar medicamento...',
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
          ),
          const SizedBox(width: 18),
          _ChipCategoria(
            texto: 'Medicamentos',
            activo: seccionSeleccionada == 'Medicamentos',
            onTap: () => onSeleccionarSeccion('Medicamentos'),
            ancho: 98,
          ),
          const SizedBox(width: 13),
          _ChipCategoria(
            texto: 'Yastas',
            activo: seccionSeleccionada == 'Yastas',
            onTap: () => onSeleccionarSeccion('Yastas'),
            ancho: 72,
          ),
        ],
      ),
    );
  }
}

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

class _CatalogoMedicamentos extends StatelessWidget {
  final List<Medicamento> medicamentos;
  final ValueChanged<Medicamento> onAgregar;

  const _CatalogoMedicamentos({
    required this.medicamentos,
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
                    padding: EdgeInsets.only(top: 24),
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
                    children: medicamentos.map((medicamento) {
                      return _TarjetaMedicamento(
                        medicamento: medicamento,
                        onAgregar: () => onAgregar(medicamento),
                      );
                    }).toList(),
                  ),
          ),
        ),
      ),
    );
  }
}

class _TarjetaMedicamento extends StatelessWidget {
  final Medicamento medicamento;
  final VoidCallback onAgregar;

  const _TarjetaMedicamento({
    required this.medicamento,
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
          _ImagenProducto(
            medicamentoId: medicamento.id,
            imagenAsset: medicamento.imagenAsset,
          ),
          const SizedBox(height: 20),
          Text(
            medicamento.nombre,
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
            medicamento.detalle,
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
                  ConfigMoneda.formato(medicamento.precio),
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
          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: _texto,
                fontSize: 6.6,
                fontWeight: FontWeight.w500,
              ),
              children: [
                const TextSpan(text: 'Stock: '),
                TextSpan(
                  text: '${medicamento.stock} unidades',
                  style: const TextStyle(
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

class _ImagenProducto extends StatelessWidget {
  final int medicamentoId;
  final String? imagenAsset;

  const _ImagenProducto({
    required this.medicamentoId,
    required this.imagenAsset,
  });

  @override
  Widget build(BuildContext context) {
    const double size = 95;

    if (imagenAsset != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Image.asset(
          imagenAsset!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _colorImagenBase(medicamentoId),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: _IlustracionProducto(medicamentoId: medicamentoId),
      ),
    );
  }

  Color _colorImagenBase(int id) {
    switch (id) {
      case 1:
        return const Color(0xFFF3F5F5);
      case 2:
        return const Color(0xFFEFEFEA);
      case 3:
        return const Color(0xFFF4F4F0);
      case 4:
        return const Color(0xFF0B4B43);
      case 5:
        return const Color(0xFFB9D9D4);
      default:
        return const Color(0xFFF3F5F5);
    }
  }
}

class _IlustracionProducto extends StatelessWidget {
  final int medicamentoId;

  const _IlustracionProducto({
    required this.medicamentoId,
  });

  @override
  Widget build(BuildContext context) {
    switch (medicamentoId) {
      case 1:
        return _CajaMedicamento(
          texto: 'Paracetamol',
          colorPrincipal: const Color(0xFF55BFD2),
          colorSecundario: const Color(0xFFE9F6FA),
        );
      case 2:
        return const _FrascoMedicamento();
      case 3:
        return _CajaMedicamento(
          texto: 'Ibuprofeno',
          colorPrincipal: const Color(0xFFFF8500),
          colorSecundario: const Color(0xFFFFF0DE),
        );
      case 4:
        return _CajaMedicamento(
          texto: 'Ome',
          colorPrincipal: const Color(0xFF0F8B70),
          colorSecundario: const Color(0xFFE7FFF8),
        );
      case 5:
        return Transform.rotate(
          angle: -0.2,
          child: const Icon(
            Icons.thermostat,
            size: 55,
            color: Color(0xFF4E7B78),
          ),
        );
      default:
        return const Icon(
          Icons.medication_outlined,
          size: 48,
          color: Color(0xFF6A7B84),
        );
    }
  }
}

class _CajaMedicamento extends StatelessWidget {
  final String texto;
  final Color colorPrincipal;
  final Color colorSecundario;

  const _CajaMedicamento({
    required this.texto,
    required this.colorPrincipal,
    required this.colorSecundario,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 46,
      decoration: BoxDecoration(
        color: _blanco,
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 6,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 14,
              color: colorSecundario,
            ),
          ),
          Positioned(
            left: 7,
            top: 13,
            child: Text(
              texto,
              style: TextStyle(
                color: colorPrincipal,
                fontSize: 7,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 7,
            child: Container(
              height: 4,
              color: colorPrincipal,
            ),
          ),
        ],
      ),
    );
  }
}

class _FrascoMedicamento extends StatelessWidget {
  const _FrascoMedicamento();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFFD9D9D9),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(2),
            ),
          ),
        ),
        Container(
          width: 34,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF965D28),
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.14),
                blurRadius: 6,
                offset: const Offset(2, 3),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 28,
              height: 15,
              color: _blanco,
            ),
          ),
        ),
      ],
    );
  }
}
