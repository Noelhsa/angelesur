import 'package:flutter/material.dart';

const Color _fondoPagina = Color(0xFFF8F6F5);
const Color _verdeOscuro = Color(0xFF397800);
const Color _verdeTexto = Color(0xFF4E8A33);
const Color _azul = Color(0xFF0B63CE);
const Color _textoPrincipal = Color(0xFF101828);
const Color _textoSecundario = Color(0xFF526171);
const Color _bordeSuave = Color(0xFFD9E6D3);
const Color _grisCabeceraTabla = Color(0xFFE7E3E3);

class ContenidoHistorial extends StatefulWidget {
  const ContenidoHistorial({super.key});

  @override
  State<ContenidoHistorial> createState() => _ContenidoHistorialState();
}

class _ContenidoHistorialState extends State<ContenidoHistorial> {
  final TextEditingController _sustanciaController = TextEditingController();

  String _periodoSeleccionado = 'Hoy';
  String _categoriaSeleccionada = 'Todos los Productos';

  final List<_VentaHistorial> _ventas = const [
    _VentaHistorial(
      producto: 'Amoxicilina 500mg',
      folio: 'PX-4520',
      sustancia: 'Amoxicilina',
      contenido: '20 Cápsulas',
      fecha: '24 Oct 2023',
      hora: '10:15 AM',
      precio: 185.00,
      colorImagen: Color(0xFFBFE0D6),
      icono: Icons.medication_outlined,
    ),
    _VentaHistorial(
      producto: 'Paracetamol 500mg',
      folio: 'PX-4521',
      sustancia: 'Paracetamol',
      contenido: '10 Tabletas',
      fecha: '24 Oct 2023',
      hora: '10:42 AM',
      precio: 45.50,
      colorImagen: Color(0xFF151925),
      icono: Icons.medication_outlined,
    ),
    _VentaHistorial(
      producto: 'Vitamina C + Zinc',
      folio: 'PX-45922',
      sustancia: 'Ácido Ascórbico',
      contenido: '30 Tabletas',
      fecha: '24 Oct 2023',
      hora: '11:05 AM',
      precio: 120.00,
      colorImagen: Color(0xFFFFD69A),
      icono: Icons.medication_liquid_outlined,
    ),
    _VentaHistorial(
      producto: 'Salbutamol Spray',
      folio: 'PX-45923',
      sustancia: 'Salbutamol',
      contenido: '200 Dosis',
      fecha: '24 Oct 2023',
      hora: '11:30 AM',
      precio: 215.00,
      colorImagen: Color(0xFFD9F1F2),
      icono: Icons.medication_outlined,
    ),
  ];

  @override
  void dispose() {
    _sustanciaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _fondoPagina,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(26, 38, 26, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EncabezadoHistorial(
              periodoSeleccionado: _periodoSeleccionado,
              onPeriodoSeleccionado: (periodo) {
                setState(() {
                  _periodoSeleccionado = periodo;
                });
              },
            ),
            const SizedBox(height: 34),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _PanelFiltros(
                    categoriaSeleccionada: _categoriaSeleccionada,
                    sustanciaController: _sustanciaController,
                    onCategoriaChanged: (valor) {
                      if (valor == null) return;

                      setState(() {
                        _categoriaSeleccionada = valor;
                      });
                    },
                    onAplicarFiltros: () {},
                  ),
                ),
                const SizedBox(width: 20),
                const _TarjetaTotalTurno(),
              ],
            ),
            const SizedBox(height: 32),
            _TablaHistorialVentas(
              ventas: _ventas,
            ),
          ],
        ),
      ),
    );
  }
}

class _EncabezadoHistorial extends StatelessWidget {
  final String periodoSeleccionado;
  final ValueChanged<String> onPeriodoSeleccionado;

  const _EncabezadoHistorial({
    required this.periodoSeleccionado,
    required this.onPeriodoSeleccionado,
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
                'Historial de Ventas',
                style: TextStyle(
                  color: _textoPrincipal,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Visualiza y gestiona el registro de transacciones recientes del turno.',
                style: TextStyle(
                  color: Color(0xFF214025),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        _SelectorPeriodo(
          periodoSeleccionado: periodoSeleccionado,
          onPeriodoSeleccionado: onPeriodoSeleccionado,
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 32,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(
              Icons.download,
              size: 15,
              color: Colors.white,
            ),
            label: const Text(
              'Exportar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _verdeOscuro,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectorPeriodo extends StatelessWidget {
  final String periodoSeleccionado;
  final ValueChanged<String> onPeriodoSeleccionado;

  const _SelectorPeriodo({
    required this.periodoSeleccionado,
    required this.onPeriodoSeleccionado,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFECEAEA),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _BotonPeriodo(
            texto: 'Hoy',
            activo: periodoSeleccionado == 'Hoy',
            onTap: () => onPeriodoSeleccionado('Hoy'),
          ),
          _BotonPeriodo(
            texto: 'Semana',
            activo: periodoSeleccionado == 'Semana',
            onTap: () => onPeriodoSeleccionado('Semana'),
          ),
          _BotonPeriodo(
            texto: 'Mes',
            activo: periodoSeleccionado == 'Mes',
            onTap: () => onPeriodoSeleccionado('Mes'),
          ),
        ],
      ),
    );
  }
}

class _BotonPeriodo extends StatelessWidget {
  final String texto;
  final bool activo;
  final VoidCallback onTap;

  const _BotonPeriodo({
    required this.texto,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      width: texto == 'Semana' ? 70 : 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: activo ? 2 : 0,
          backgroundColor: activo ? _azul : Colors.transparent,
          foregroundColor: activo ? Colors.white : Colors.black,
          padding: EdgeInsets.zero,
          shadowColor: Colors.black.withOpacity(0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: Text(
          texto,
          style: TextStyle(
            fontSize: 11,
            fontWeight: activo ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PanelFiltros extends StatelessWidget {
  final String categoriaSeleccionada;
  final TextEditingController sustanciaController;
  final ValueChanged<String?> onCategoriaChanged;
  final VoidCallback onAplicarFiltros;

  const _PanelFiltros({
    required this.categoriaSeleccionada,
    required this.sustanciaController,
    required this.onCategoriaChanged,
    required this.onAplicarFiltros,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _bordeSuave),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 190,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _LabelFiltro(texto: 'CATEGORÍA'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 37,
                  child: DropdownButtonFormField<String>(
                    value: categoriaSeleccionada,
                    isExpanded: true,
                    decoration: _decoracionCampo(),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                    ),
                    style: const TextStyle(
                      color: _textoPrincipal,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Todos los Productos',
                        child: Text('Todos los Productos'),
                      ),
                      DropdownMenuItem(
                        value: 'Antibióticos',
                        child: Text('Antibióticos'),
                      ),
                      DropdownMenuItem(
                        value: 'Analgésicos',
                        child: Text('Analgésicos'),
                      ),
                    ],
                    onChanged: onCategoriaChanged,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          SizedBox(
            width: 190,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _LabelFiltro(texto: 'SUSTANCIA ACTIVA'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 37,
                  child: TextField(
                    controller: sustanciaController,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _textoPrincipal,
                    ),
                    decoration: _decoracionCampo(
                      hintText: 'Ejem: Paracetamol',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Padding(
            padding: const EdgeInsets.only(top: 22),
            child: SizedBox(
              width: 190,
              height: 37,
              child: ElevatedButton.icon(
                onPressed: onAplicarFiltros,
                icon: const Icon(
                  Icons.filter_list,
                  size: 17,
                  color: Colors.white,
                ),
                label: const Text(
                  'Aplicar Filtros',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _azul,
                  elevation: 0,
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

  InputDecoration _decoracionCampo({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF7E8790),
        fontSize: 12,
      ),
      filled: true,
      fillColor: const Color(0xFFF6F4F1),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFC6CFC0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFC6CFC0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: _verdeOscuro, width: 1.2),
      ),
    );
  }
}

class _LabelFiltro extends StatelessWidget {
  final String texto;

  const _LabelFiltro({
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        color: Color(0xFF203624),
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _TarjetaTotalTurno extends StatelessWidget {
  const _TarjetaTotalTurno();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 310,
      height: 110,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FAEE),
        border: Border.all(color: _bordeSuave),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL DEL TURNO',
            style: TextStyle(
              color: _verdeOscuro,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$12,450.50',
                style: TextStyle(
                  color: _textoPrincipal,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(width: 10),
              Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Text(
                  '↗ +8.4%',
                  style: TextStyle(
                    color: _verdeOscuro,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2),
          Text(
            'Vs promedio del día de ayer',
            style: TextStyle(
              color: Color(0xFF667085),
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _TablaHistorialVentas extends StatelessWidget {
  final List<_VentaHistorial> ventas;

  const _TablaHistorialVentas({
    required this.ventas,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE1E6DA)),
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const _FilaTablaHeader(),
          for (final venta in ventas) _FilaVenta(venta: venta),
        ],
      ),
    );
  }
}

class _FilaTablaHeader extends StatelessWidget {
  const _FilaTablaHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: const BoxDecoration(
        color: _grisCabeceraTabla,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(9),
        ),
      ),
      child: const Row(
        children: [
          SizedBox(width: 20),
          Expanded(
            flex: 32,
            child: _HeaderTexto('PRODUCTO'),
          ),
          Expanded(
            flex: 20,
            child: _HeaderTexto('SUSTANCIA'),
          ),
          Expanded(
            flex: 20,
            child: _HeaderTexto('CONTENIDO'),
          ),
          Expanded(
            flex: 19,
            child: _HeaderTexto('FECHA'),
          ),
          Expanded(
            flex: 18,
            child: _HeaderTexto('PRECIO'),
          ),
          Expanded(
            flex: 18,
            child: _HeaderTexto('ACCIÓN'),
          ),
          SizedBox(width: 12),
        ],
      ),
    );
  }
}

class _HeaderTexto extends StatelessWidget {
  final String texto;

  const _HeaderTexto(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        color: Color(0xFF747B65),
        fontSize: 13,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _FilaVenta extends StatelessWidget {
  final _VentaHistorial venta;

  const _FilaVenta({
    required this.venta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(0xFFE6EADC),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 20),
          Expanded(
            flex: 32,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: venta.colorImagen,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    venta.icono,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        venta.producto,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF56605A),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'FOLIO: ${venta.folio}',
                        style: const TextStyle(
                          color: Color(0xFF9BA0A0),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 20,
            child: Text(
              venta.sustancia,
              style: const TextStyle(
                color: Color(0xFF6A736C),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 20,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE4E4E1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  venta.contenido,
                  style: const TextStyle(
                    color: Color(0xFF7C817B),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 19,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  venta.fecha,
                  style: const TextStyle(
                    color: Color(0xFF56605A),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  venta.hora,
                  style: const TextStyle(
                    color: Color(0xFF7A8180),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              '\$${venta.precio.toStringAsFixed(2)}',
              style: const TextStyle(
                color: _verdeTexto,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            flex: 18,
            child: InkWell(
              onTap: () {},
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Detalles',
                    style: TextStyle(
                      color: _azul,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.open_in_new,
                    size: 13,
                    color: _azul,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

class _VentaHistorial {
  final String producto;
  final String folio;
  final String sustancia;
  final String contenido;
  final String fecha;
  final String hora;
  final double precio;
  final Color colorImagen;
  final IconData icono;

  const _VentaHistorial({
    required this.producto,
    required this.folio,
    required this.sustancia,
    required this.contenido,
    required this.fecha,
    required this.hora,
    required this.precio,
    required this.colorImagen,
    required this.icono,
  });
}