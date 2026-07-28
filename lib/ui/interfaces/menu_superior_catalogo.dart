import 'package:flutter/material.dart';

const Color _verdeActivo = Color(0xFF4F7D35);
const Color _textoPrincipal = Color(0xFF111111);
const Color _lineaDivisoria = Color(0xFFD4D4C8);

class MenuSuperiorCatalogo extends StatelessWidget {
  final int indiceSeleccionado;
  final ValueChanged<int> onSeleccionar;

  const MenuSuperiorCatalogo({
    super.key,
    required this.indiceSeleccionado,
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        14,
        18,
        14,
        0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gestión de Catálogo',
            style: TextStyle(
              color: _textoPrincipal,
              fontSize: 27,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 32,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 1,
                    color: _lineaDivisoria,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _OpcionSubmenuCatalogo(
                      texto: 'Inventario',
                      activo: indiceSeleccionado == 0,
                      onTap: () => onSeleccionar(0),
                    ),
                    const SizedBox(width: 24),
                    _OpcionSubmenuCatalogo(
                      texto: 'Producto',
                      activo: indiceSeleccionado == 1,
                      onTap: () => onSeleccionar(1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OpcionSubmenuCatalogo extends StatelessWidget {
  final String texto;
  final bool activo;
  final VoidCallback onTap;

  const _OpcionSubmenuCatalogo({
    required this.texto,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 32,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 2,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                texto,
                style: TextStyle(
                  color: activo
                      ? _verdeActivo
                      : _textoPrincipal,
                  fontSize: 12,
                  fontWeight: activo
                      ? FontWeight.w900
                      : FontWeight.w600,
                  height: 1,
                ),
              ),
              const SizedBox(height: 7),
              Container(
                width: texto == 'Inventario'
                    ? 66
                    : 55,
                height: 2,
                color: activo
                    ? _verdeActivo
                    : Colors.transparent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}