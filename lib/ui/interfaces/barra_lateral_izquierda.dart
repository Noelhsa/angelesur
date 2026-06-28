import 'package:flutter/material.dart';

const Color _colorFondoBarra = Color(0xFFF4F2F2);
const Color _colorAzulActivo = Color(0xFF316EE9);
const Color _colorIcono = Color(0xFF646C55);
const Color _colorRojo = Color(0xFFE53935);

class BarraLateralIzquierda extends StatelessWidget {
  final int seleccionado;
  final ValueChanged<int> onSeleccionar;

  const BarraLateralIzquierda({
    super.key,
    required this.seleccionado,
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      color: _colorFondoBarra,
      child: Column(
        children: [
          const SizedBox(height: 26),

          _BotonMenuLateral(
            indice: 0,
            seleccionado: seleccionado,
            icono: Icons.person_outline_rounded,
            texto: 'Perfil',
            onTap: onSeleccionar,
          ),

          const SizedBox(height: 18),

          _BotonMenuLateral(
            indice: 1,
            seleccionado: seleccionado,
            icono: Icons.storefront_outlined,
            texto: 'Venta',
            onTap: onSeleccionar,
          ),

          const SizedBox(height: 18),

          _BotonMenuLateral(
            indice: 2,
            seleccionado: seleccionado,
            icono: Icons.history,
            texto: 'Historial',
            onTap: onSeleccionar,
          ),

          const SizedBox(height: 18),

          _BotonMenuLateral(
            indice: 3,
            seleccionado: seleccionado,
            icono: Icons.assignment_outlined,
            texto: 'Pedidos',
            onTap: onSeleccionar,
          ),

          const SizedBox(height: 18),

          _BotonMenuLateral(
            indice: 4,
            seleccionado: seleccionado,
            icono: Icons.inventory_2_outlined,
            texto: 'Catálogo',
            onTap: onSeleccionar,
          ),

          const SizedBox(height: 18),

          _BotonMenuLateral(
            indice: 5,
            seleccionado: seleccionado,
            icono: Icons.payments_outlined,
            texto: 'Cajero',
            onTap: onSeleccionar,
          ),

          const Spacer(),

          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.settings_outlined,
              size: 20,
              color: _colorIcono,
            ),
          ),

          const SizedBox(height: 8),

          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.logout,
              size: 20,
              color: _colorRojo,
            ),
          ),

          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _BotonMenuLateral extends StatelessWidget {
  final int indice;
  final int seleccionado;
  final IconData icono;
  final String texto;
  final ValueChanged<int> onTap;

  const _BotonMenuLateral({
    required this.indice,
    required this.seleccionado,
    required this.icono,
    required this.texto,
    required this.onTap,
  });

  bool get activo => indice == seleccionado;

  @override
  Widget build(BuildContext context) {
    if (activo) {
      return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onTap(indice),
        child: Container(
          width: 54,
          height: 58,
          decoration: BoxDecoration(
            color: _colorAzulActivo,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _colorAzulActivo.withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icono,
                size: 22,
                color: Colors.white,
              ),
              const SizedBox(height: 4),
              Text(
                texto,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => onTap(indice),
      child: SizedBox(
        width: 54,
        height: 58,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icono,
              size: 21,
              color: _colorIcono,
            ),
            const SizedBox(height: 4),
            Text(
              texto,
              style: const TextStyle(
                color: Color(0xFF4B4F45),
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}