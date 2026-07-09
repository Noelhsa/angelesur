import 'package:flutter/material.dart';

import '../../models/medicamento.dart';
import '../../utils/config_moneda.dart';

const Color _blanco = Color(0xFFFFFFFF);
const Color _verde = Color(0xFF58D000);
const Color _verdeOscuro = Color(0xFF2F6E00);
const Color _texto = Color(0xFF101010);
const Color _textoSuave = Color(0xFF707A83);
const Color _grisLinea = Color(0xFFE0E0E0);
const Color _rojo = Color(0xFFE21F1F);

class MenuCartaCarrito extends StatelessWidget {
  final List<Medicamento> medicamentos;
  final Map<int, int> cantidades;
  final double subtotal;
  final double descuento;
  final double total;
  final ValueChanged<int> onIncrementar;
  final ValueChanged<int> onDisminuir;
  final ValueChanged<int> onEliminar;
  final VoidCallback onPagar;
  final bool procesandoPago;

  const MenuCartaCarrito({
    super.key,
    required this.medicamentos,
    required this.cantidades,
    required this.subtotal,
    required this.descuento,
    required this.total,
    required this.onIncrementar,
    required this.onDisminuir,
    required this.onEliminar,
    required this.onPagar,
    this.procesandoPago = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 234,
      margin: const EdgeInsets.only(
        top: 20,
        right: 20,
        bottom: 20,
      ),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _blanco,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 51,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: _grisLinea,
                  width: 1,
                ),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.shopping_basket_outlined,
                  size: 16,
                  color: _verdeOscuro,
                ),
                SizedBox(width: 8),
                Text(
                  'Carrito',
                  style: TextStyle(
                    color: _texto,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: medicamentos.isEmpty
                ? const Center(
                    child: Text(
                      'Carrito vacío',
                      style: TextStyle(
                        color: _textoSuave,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(15, 13, 15, 10),
                    itemCount: medicamentos.length,
                    itemBuilder: (context, index) {
                      final medicamento = medicamentos[index];
                      final cantidad = cantidades[medicamento.id] ?? 0;

                      return _ItemCarrito(
                        medicamento: medicamento,
                        cantidad: cantidad,
                        onIncrementar: () => onIncrementar(medicamento.id),
                        onDisminuir: () => onDisminuir(medicamento.id),
                        onEliminar: () => onEliminar(medicamento.id),
                      );
                    },
                  ),
          ),
          _ResumenCarrito(
            subtotal: subtotal,
            descuento: descuento,
            total: total,
            onPagar: onPagar,
            procesandoPago: procesandoPago,
          ),
        ],
      ),
    );
  }
}

class _ItemCarrito extends StatelessWidget {
  final Medicamento medicamento;
  final int cantidad;
  final VoidCallback onIncrementar;
  final VoidCallback onDisminuir;
  final VoidCallback onEliminar;

  const _ItemCarrito({
    required this.medicamento,
    required this.cantidad,
    required this.onIncrementar,
    required this.onDisminuir,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final importe = medicamento.precio * cantidad;

    return Container(
      height: 57,
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ImagenCarrito(
            medicamentoId: medicamento.id,
            imagenAsset: medicamento.imagenAsset,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicamento.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _texto,
                      fontSize: 7.4,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${ConfigMoneda.formato(medicamento.precio)} c/u',
                    style: const TextStyle(
                      color: Color(0xFF8D8D8D),
                      fontSize: 6.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _ControlCantidad(
                    cantidad: cantidad,
                    onIncrementar: onIncrementar,
                    onDisminuir: onDisminuir,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 46,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                ConfigMoneda.formato(importe),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: _texto,
                  fontSize: 7.8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(top: 22),
            child: InkWell(
              onTap: onEliminar,
              child: const Icon(
                Icons.delete_outline,
                size: 13,
                color: _rojo,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlCantidad extends StatelessWidget {
  final int cantidad;
  final VoidCallback onIncrementar;
  final VoidCallback onDisminuir;

  const _ControlCantidad({
    required this.cantidad,
    required this.onIncrementar,
    required this.onDisminuir,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 19,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          _BotonCantidad(
            texto: '-',
            onTap: onDisminuir,
          ),
          Expanded(
            child: Center(
              child: Text(
                '$cantidad',
                style: const TextStyle(
                  color: _texto,
                  fontSize: 7.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          _BotonCantidad(
            texto: '+',
            onTap: onIncrementar,
          ),
        ],
      ),
    );
  }
}

class _BotonCantidad extends StatelessWidget {
  final String texto;
  final VoidCallback onTap;

  const _BotonCantidad({
    required this.texto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 19,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Text(
            texto,
            style: const TextStyle(
              color: _texto,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResumenCarrito extends StatelessWidget {
  final double subtotal;
  final double descuento;
  final double total;
  final VoidCallback onPagar;
  final bool procesandoPago;

  const _ResumenCarrito({
    required this.subtotal,
    required this.descuento,
    required this.total,
    required this.onPagar,
    required this.procesandoPago,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 178,
      padding: const EdgeInsets.fromLTRB(15, 18, 15, 20),
      decoration: const BoxDecoration(
        color: _blanco,
        border: Border(
          top: BorderSide(
            color: _grisLinea,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _FilaResumen(
            texto: 'Subtotal',
            valor: ConfigMoneda.formato(subtotal),
            color: _texto,
          ),
          const SizedBox(height: 11),
          _FilaResumen(
            texto: 'Descuento (Cupón: SALUD10)',
            valor: '-${ConfigMoneda.formato(descuento)}',
            color: _rojo,
          ),
          const SizedBox(height: 9),
          Container(
            height: 1,
            color: _grisLinea,
          ),
          const SizedBox(height: 9),
          _FilaResumen(
            texto: 'Total',
            valor: ConfigMoneda.formato(total),
            color: _verdeOscuro,
            grande: true,
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton.icon(
              onPressed: total <= 0 || procesandoPago ? null : onPagar,
              icon: const Icon(
                Icons.payments_outlined,
                size: 15,
                color: _verdeOscuro,
              ),
              label: Text(
                procesandoPago ? 'Procesando...' : 'Pagar',
                style: const TextStyle(
                  color: _verdeOscuro,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: ElevatedButton.styleFrom(
                elevation: 8,
                shadowColor: _verde.withOpacity(.35),
                backgroundColor: _verde,
                disabledBackgroundColor: const Color(0xFFBEBEBE),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaResumen extends StatelessWidget {
  final String texto;
  final String valor;
  final Color color;
  final bool grande;

  const _FilaResumen({
    required this.texto,
    required this.valor,
    required this.color,
    this.grande = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            texto,
            style: TextStyle(
              color: color,
              fontSize: grande ? 14 : 8,
              fontWeight: grande ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            color: color,
            fontSize: grande ? 14 : 8,
            fontWeight: grande ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ImagenCarrito extends StatelessWidget {
  final int medicamentoId;
  final String? imagenAsset;

  const _ImagenCarrito({
    required this.medicamentoId,
    required this.imagenAsset,
  });

  @override
  Widget build(BuildContext context) {
    const double size = 39;

    if (imagenAsset != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(5),
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
        borderRadius: BorderRadius.circular(5),
      ),
      child: Center(
        child: _IlustracionCarrito(
          medicamentoId: medicamentoId,
        ),
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

class _IlustracionCarrito extends StatelessWidget {
  final int medicamentoId;

  const _IlustracionCarrito({
    required this.medicamentoId,
  });

  @override
  Widget build(BuildContext context) {
    switch (medicamentoId) {
      case 1:
        return Transform.scale(
          scale: .42,
          child: _CajaCarrito(
            texto: 'Paracetamol',
            colorPrincipal: const Color(0xFF55BFD2),
            colorSecundario: const Color(0xFFE9F6FA),
          ),
        );
      case 2:
        return Transform.scale(
          scale: .42,
          child: const _FrascoCarrito(),
        );
      case 3:
        return Transform.scale(
          scale: .42,
          child: _CajaCarrito(
            texto: 'Ibuprofeno',
            colorPrincipal: Color(0xFFFF8500),
            colorSecundario: Color(0xFFFFF0DE),
          ),
        );
      case 4:
        return Transform.scale(
          scale: .42,
          child: _CajaCarrito(
            texto: 'Ome',
            colorPrincipal: Color(0xFF0F8B70),
            colorSecundario: Color(0xFFE7FFF8),
          ),
        );
      case 5:
        return Transform.rotate(
          angle: -0.2,
          child: const Icon(
            Icons.thermostat,
            size: 25,
            color: Color(0xFF4E7B78),
          ),
        );
      default:
        return const Icon(
          Icons.medication_outlined,
          size: 21,
          color: Color(0xFF6A7B84),
        );
    }
  }
}

class _CajaCarrito extends StatelessWidget {
  final String texto;
  final Color colorPrincipal;
  final Color colorSecundario;

  const _CajaCarrito({
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

class _FrascoCarrito extends StatelessWidget {
  const _FrascoCarrito();

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
