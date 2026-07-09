import 'package:flutter/material.dart';

const Color _fondoPagina = Color(0xFFF8F6F5);
const Color _verdeOscuro = Color(0xFF397800);
const Color _verde = Color(0xFF64D20A);
const Color _textoPrincipal = Color(0xFF101828);
const Color _textoSecundario = Color(0xFF667085);
const Color _bordeSuave = Color(0xFFD9E6D3);
const Color _grisCampo = Color(0xFFF8F7F4);

class MenuCartaPedidos extends StatelessWidget {
  final VoidCallback onCerrar;
  final VoidCallback onGuardarOrden;

  const MenuCartaPedidos({
    super.key,
    required this.onCerrar,
    required this.onGuardarOrden,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 275,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(
            color: _bordeSuave,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _EncabezadoNuevaOrden(
            onCerrar: onCerrar,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(10, 16, 10, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _CampoTextoPedido(
                    etiqueta: 'Folio de Orden',
                    texto: 'ORD-00942',
                  ),
                  SizedBox(height: 16),
                  _CampoDropdownPedido(
                    etiqueta: 'Proveedor',
                    valor: 'Distribuidora Farmacéutica Global',
                  ),
                  SizedBox(height: 16),
                  _CampoFechaPedido(),
                  SizedBox(height: 16),
                  _CamposSubtotalDescuento(),
                  SizedBox(height: 18),
                  _ResumenFinalPedido(),
                  SizedBox(height: 18),
                  _CampoObservacionesPedido(),
                ],
              ),
            ),
          ),
          _AccionesNuevaOrden(
            onCancelar: onCerrar,
            onGuardar: onGuardarOrden,
          ),
        ],
      ),
    );
  }
}

class _EncabezadoNuevaOrden extends StatelessWidget {
  final VoidCallback onCerrar;

  const _EncabezadoNuevaOrden({
    required this.onCerrar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: _bordeSuave,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.add_shopping_cart,
            color: _verdeOscuro,
            size: 17,
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Nueva Orden',
              style: TextStyle(
                color: _textoPrincipal,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            onPressed: onCerrar,
            icon: const Icon(
              Icons.close,
              color: _textoPrincipal,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _CampoTextoPedido extends StatelessWidget {
  final String etiqueta;
  final String texto;

  const _CampoTextoPedido({
    required this.etiqueta,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return _ContenedorCampo(
      etiqueta: etiqueta,
      child: TextField(
        controller: TextEditingController(text: texto),
        readOnly: true,
        style: const TextStyle(
          color: _textoPrincipal,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        decoration: _decoracionCampo(),
      ),
    );
  }
}

class _CampoDropdownPedido extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _CampoDropdownPedido({
    required this.etiqueta,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return _ContenedorCampo(
      etiqueta: etiqueta,
      child: DropdownButtonFormField<String>(
        value: valor,
        isExpanded: true,
        icon: const Icon(
          Icons.keyboard_arrow_down,
          color: _textoSecundario,
          size: 18,
        ),
        style: const TextStyle(
          color: _textoPrincipal,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        decoration: _decoracionCampo(),
        items: const [
          DropdownMenuItem(
            value: 'Distribuidora Farmacéutica Global',
            child: Text(
              'Distribuidora Farmacéutica Global',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          DropdownMenuItem(
            value: 'Proveedor Local',
            child: Text('Proveedor Local'),
          ),
          DropdownMenuItem(
            value: 'Laboratorio Nacional',
            child: Text('Laboratorio Nacional'),
          ),
        ],
        onChanged: (_) {},
      ),
    );
  }
}

class _CampoFechaPedido extends StatelessWidget {
  const _CampoFechaPedido();

  @override
  Widget build(BuildContext context) {
    return _ContenedorCampo(
      etiqueta: 'Fecha de Compra',
      child: TextField(
        controller: TextEditingController(text: '24/10/2023'),
        readOnly: true,
        style: const TextStyle(
          color: _textoPrincipal,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        decoration: _decoracionCampo(
          prefixIcon: Icons.calendar_today_outlined,
          suffixIcon: Icons.calendar_month_outlined,
        ),
      ),
    );
  }
}

class _CamposSubtotalDescuento extends StatelessWidget {
  const _CamposSubtotalDescuento();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ContenedorCampo(
            etiqueta: 'Subtotal',
            child: TextField(
              controller: TextEditingController(text: '\$250.00'),
              readOnly: true,
              style: const TextStyle(
                color: _textoPrincipal,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              decoration: _decoracionCampo(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ContenedorCampo(
            etiqueta: 'Descuento',
            child: TextField(
              controller: TextEditingController(text: '10'),
              readOnly: true,
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: _textoPrincipal,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              decoration: _decoracionCampo(
                suffixText: '%',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResumenFinalPedido extends StatelessWidget {
  const _ResumenFinalPedido();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7DF),
        border: Border.all(
          color: const Color(0xFFCFE8BF),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Resumen Final',
                  style: TextStyle(
                    color: _textoSecundario,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9F2C7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'AUTOMÁTICO',
                  style: TextStyle(
                    color: _verdeOscuro,
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Total',
                  style: TextStyle(
                    color: _verdeOscuro,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '\$1,125.00',
                style: TextStyle(
                  color: _verdeOscuro,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CampoObservacionesPedido extends StatelessWidget {
  const _CampoObservacionesPedido();

  @override
  Widget build(BuildContext context) {
    return _ContenedorCampo(
      etiqueta: 'Observaciones',
      child: TextField(
        maxLines: 5,
        style: const TextStyle(
          color: _textoPrincipal,
          fontSize: 12,
        ),
        decoration: _decoracionCampo().copyWith(
          hintText: 'Notas sobre el envío, urgencia o condiciones especiales...',
          hintStyle: const TextStyle(
            color: _textoSecundario,
            fontSize: 11,
            height: 1.4,
          ),
          alignLabelWithHint: true,
          contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        ),
      ),
    );
  }
}

class _ContenedorCampo extends StatelessWidget {
  final String etiqueta;
  final Widget child;

  const _ContenedorCampo({
    required this.etiqueta,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: const TextStyle(
            color: _textoPrincipal,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 38,
          ),
          child: child,
        ),
      ],
    );
  }
}

class _AccionesNuevaOrden extends StatelessWidget {
  final VoidCallback onCancelar;
  final VoidCallback onGuardar;

  const _AccionesNuevaOrden({
    required this.onCancelar,
    required this.onGuardar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: _bordeSuave,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 34,
              child: OutlinedButton(
                onPressed: onCancelar,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: _bordeSuave,
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    color: _textoPrincipal,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 34,
              child: ElevatedButton.icon(
                onPressed: onGuardar,
                icon: const Icon(
                  Icons.save_outlined,
                  color: Colors.white,
                  size: 13,
                ),
                label: const Text(
                  'Guardar Orden',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _verde,
                  elevation: 4,
                  shadowColor: _verde.withOpacity(0.35),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _decoracionCampo({
  IconData? prefixIcon,
  IconData? suffixIcon,
  String? suffixText,
}) {
  return InputDecoration(
    filled: true,
    fillColor: _grisCampo,
    prefixIcon: prefixIcon == null
        ? null
        : Icon(
            prefixIcon,
            color: _textoSecundario,
            size: 16,
          ),
    suffixIcon: suffixIcon == null
        ? null
        : Icon(
            suffixIcon,
            color: _textoPrincipal,
            size: 16,
          ),
    suffixText: suffixText,
    suffixStyle: const TextStyle(
      color: _textoPrincipal,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 10,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(
        color: _bordeSuave,
        width: 1,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(
        color: _bordeSuave,
        width: 1,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(
        color: _verdeOscuro,
        width: 1.3,
      ),
    ),
  );
}