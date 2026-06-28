import 'package:flutter/material.dart';

const Color _fondoPagina = Color(0xFFE2E2E2);
const Color _blanco = Color(0xFFFFFFFF);
const Color _verde = Color(0xFF64D20A);
const Color _verdeOscuro = Color(0xFF397800);
const Color _verdeTexto = Color(0xFF447700);
const Color _azul = Color(0xFF3478F6);
const Color _rojo = Color(0xFFD71919);
const Color _textoPrincipal = Color(0xFF101828);
const Color _textoSecundario = Color(0xFF526171);
const Color _bordeSuave = Color(0xFFD9E6D3);

class ContenidoCajero extends StatelessWidget {
  const ContenidoCajero({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _fondoPagina,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 22),
        child: Column(
          children: [
            const _ResumenSuperiorCajero(),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 850) {
                  return const Column(
                    children: [
                      _FlujoTurnoCard(),
                      SizedBox(height: 18),
                      _CorteCajaCard(),
                    ],
                  );
                }

                return const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: _FlujoTurnoCard(),
                    ),
                    SizedBox(width: 18),
                    Expanded(
                      flex: 3,
                      child: _CorteCajaCard(),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumenSuperiorCajero extends StatelessWidget {
  const _ResumenSuperiorCajero();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return const Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _TarjetaResumenCaja(
                titulo: 'Fondo Inicial',
                valor: '\$1,500.00',
                subtitulo: 'Registrado 08:00 AM',
                icono: Icons.account_balance_wallet_outlined,
                colorIcono: _azul,
                fondoIcono: Color(0xFFE8F1FF),
              ),
              _TarjetaResumenCaja(
                titulo: 'Ventas Efectivo',
                valor: '\$4,235.50',
                subtitulo: '↗ +12% vs ayer',
                subtituloVerde: true,
                icono: Icons.payments_outlined,
                colorIcono: _verdeOscuro,
                fondoIcono: Color(0xFFEAF8DD),
              ),
              _TarjetaResumenCaja(
                titulo: 'Otros Métodos',
                valor: '\$8,120.00',
                subtitulo: 'Tarjeta: \$7,400.00\nTransferencia: \$720.00',
                icono: Icons.credit_card,
                colorIcono: _azul,
                fondoIcono: Color(0xFFE8F1FF),
              ),
              _TarjetaBalanceEfectivo(),
            ],
          );
        }

        return const Row(
          children: [
            Expanded(
              child: _TarjetaResumenCaja(
                titulo: 'Fondo Inicial',
                valor: '\$1,500.00',
                subtitulo: 'Registrado 08:00 AM',
                icono: Icons.account_balance_wallet_outlined,
                colorIcono: _azul,
                fondoIcono: Color(0xFFE8F1FF),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _TarjetaResumenCaja(
                titulo: 'Ventas Efectivo',
                valor: '\$4,235.50',
                subtitulo: '↗ +12% vs ayer',
                subtituloVerde: true,
                icono: Icons.payments_outlined,
                colorIcono: _verdeOscuro,
                fondoIcono: Color(0xFFEAF8DD),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _TarjetaResumenCaja(
                titulo: 'Otros Métodos',
                valor: '\$8,120.00',
                subtitulo: 'Tarjeta: \$7,400.00\nTransferencia: \$720.00',
                icono: Icons.credit_card,
                colorIcono: _azul,
                fondoIcono: Color(0xFFE8F1FF),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _TarjetaBalanceEfectivo(),
            ),
          ],
        );
      },
    );
  }
}

class _TarjetaResumenCaja extends StatelessWidget {
  final String titulo;
  final String valor;
  final String subtitulo;
  final IconData icono;
  final Color colorIcono;
  final Color fondoIcono;
  final bool subtituloVerde;

  const _TarjetaResumenCaja({
    required this.titulo,
    required this.valor,
    required this.subtitulo,
    required this.icono,
    required this.colorIcono,
    required this.fondoIcono,
    this.subtituloVerde = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 128,
      constraints: const BoxConstraints(minWidth: 155),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: _blanco,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: fondoIcono,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  icono,
                  size: 20,
                  color: colorIcono,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textoPrincipal,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            valor,
            style: const TextStyle(
              color: _textoPrincipal,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            subtitulo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: subtituloVerde ? _verdeOscuro : _textoSecundario,
              fontSize: 10,
              fontWeight: subtituloVerde ? FontWeight.w800 : FontWeight.w500,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaBalanceEfectivo extends StatelessWidget {
  const _TarjetaBalanceEfectivo();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 128,
      constraints: const BoxConstraints(minWidth: 155),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: _verde,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _blanco, width: 2),
        boxShadow: [
          BoxShadow(
            color: _verde.withOpacity(0.28),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconoBalance(),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Balance Efectivo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _verdeOscuro,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 18),
          Text(
            '\$5,735.50',
            style: TextStyle(
              color: _verdeOscuro,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Dinero total en caja física',
            style: TextStyle(
              color: _verdeTexto,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconoBalance extends StatelessWidget {
  const _IconoBalance();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFA8EC52),
        borderRadius: BorderRadius.circular(7),
      ),
      child: const Icon(
        Icons.payments_outlined,
        size: 20,
        color: _blanco,
      ),
    );
  }
}

class _FlujoTurnoCard extends StatelessWidget {
  const _FlujoTurnoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 310,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
      decoration: BoxDecoration(
        color: _blanco,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Flujo del Turno',
                  style: TextStyle(
                    color: _textoPrincipal,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F7F4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Tiempo Real',
                  style: TextStyle(
                    color: _textoSecundario,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              decoration: BoxDecoration(
                color: _blanco,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _bordeSuave),
              ),
              child: const Column(
                children: [
                  _LeyendaGrafica(),
                  SizedBox(height: 7),
                  Expanded(
                    child: _GraficaBarrasTurno(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _MetricasTurno(),
        ],
      ),
    );
  }
}

class _LeyendaGrafica extends StatelessWidget {
  const _LeyendaGrafica();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _PuntoLeyenda(
          color: _verdeOscuro,
          texto: 'Ingresos (Pico 14:00h)',
        ),
        SizedBox(width: 18),
        _PuntoLeyenda(
          color: _rojo,
          texto: 'Retiros / Gastos',
        ),
      ],
    );
  }
}

class _PuntoLeyenda extends StatelessWidget {
  final Color color;
  final String texto;

  const _PuntoLeyenda({
    required this.color,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          texto,
          style: const TextStyle(
            color: _textoPrincipal,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _GraficaBarrasTurno extends StatelessWidget {
  const _GraficaBarrasTurno();

  static const List<double> _alturas = [
    0.32,
    0.48,
    0.42,
    0.64,
    0.92,
    0.76,
    0.53,
    1.0,
    0.42,
    0.32,
    0.22,
    0.11,
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(_alturas.length, (index) {
        final bool pico = index == 7;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FractionallySizedBox(
              heightFactor: _alturas[index],
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: BoxDecoration(
                  color: pico
                      ? const Color(0xFF88A76E)
                      : const Color(0xFFD6E0CD),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(1),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _MetricasTurno extends StatelessWidget {
  const _MetricasTurno();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          const Expanded(
            child: _MetricaTurno(
              titulo: 'TRANSACCIONES',
              valor: '142',
              colorValor: _textoPrincipal,
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: _bordeSuave,
          ),
          const Expanded(
            child: _MetricaTurno(
              titulo: 'PROMEDIO',
              valor: '\$98.00',
              colorValor: _textoPrincipal,
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: _bordeSuave,
          ),
          const Expanded(
            child: _MetricaTurno(
              titulo: 'RETIROS',
              valor: '-\$250.00',
              colorValor: _rojo,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricaTurno extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color colorValor;

  const _MetricaTurno({
    required this.titulo,
    required this.valor,
    required this.colorValor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          titulo,
          style: const TextStyle(
            color: _textoSecundario,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          valor,
          style: TextStyle(
            color: colorValor,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _CorteCajaCard extends StatelessWidget {
  const _CorteCajaCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 310,
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
      decoration: BoxDecoration(
        color: _blanco,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: _verde,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline,
              size: 34,
              color: _verdeOscuro,
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Corte de Caja',
            style: TextStyle(
              color: _textoPrincipal,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Al realizar el corte, se cerrará el\n'
            'turno actual y se generará un reporte\n'
            'detallado para administración.\n'
            'Asegúrate de contar el efectivo físico\n'
            'antes de proceder.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textoPrincipal,
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(
                Icons.receipt_long_outlined,
                color: Colors.white,
                size: 18,
              ),
              label: const Text(
                'Realizar Corte de Caja',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _verdeOscuro,
                elevation: 8,
                shadowColor: _verdeOscuro.withOpacity(0.25),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}