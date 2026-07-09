import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/proveedores_api_service.dart';

const Color _fondoPagina = Color(0xFFF8F6F5);
const Color _verdeOscuro = Color(0xFF397800);
const Color _azul = Color(0xFF0B63CE);
const Color _rojo = Color(0xFFE02020);
const Color _textoPrincipal = Color(0xFF101828);
const Color _textoSecundario = Color(0xFF526171);
const Color _bordeSuave = Color(0xFFD9E6D3);
const Color _grisCampo = Color(0xFFF8F7F4);

class ContenidoProveedores extends StatefulWidget {
  const ContenidoProveedores({super.key});

  @override
  State<ContenidoProveedores> createState() => _ContenidoProveedoresState();
}

class _ContenidoProveedoresState extends State<ContenidoProveedores> {
  final ProveedoresApiService _proveedoresApiService = ProveedoresApiService();
  final TextEditingController _busquedaController = TextEditingController();

  bool _cargando = true;
  bool _procesando = false;
  String _estadoSeleccionado = 'Todos';
  String? _error;
  List<ProveedorApi> _proveedores = [];

  @override
  void initState() {
    super.initState();
    _cargarProveedores();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  List<ProveedorApi> get _proveedoresFiltrados {
    return _proveedores.where((proveedor) {
      return switch (_estadoSeleccionado) {
        'Activos' => proveedor.activo,
        'Inactivos' => !proveedor.activo,
        _ => true,
      };
    }).toList();
  }

  Future<void> _cargarProveedores() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final proveedores = await _proveedoresApiService.listarProveedores(
        busqueda: _busquedaController.text,
      );
      if (!mounted) return;
      setState(() {
        _proveedores = proveedores;
        _cargando = false;
      });
    } on ApiException catch (error) {
      _mostrarError(error.message);
    } catch (_) {
      _mostrarError('No se pudieron cargar los proveedores');
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    setState(() {
      _error = mensaje;
      _cargando = false;
      _procesando = false;
    });
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  Future<void> _guardarProveedor({ProveedorApi? proveedor}) async {
    final datos = await showDialog<ProveedorPayload>(
      context: context,
      builder: (context) => _DialogoProveedor(proveedor: proveedor),
    );
    if (datos == null) return;

    setState(() {
      _procesando = true;
    });

    try {
      if (proveedor == null) {
        await _proveedoresApiService.crearProveedor(datos);
        _mostrarMensaje('Proveedor creado');
      } else {
        await _proveedoresApiService.actualizarProveedor(
          proveedor.idProveedor,
          datos,
        );
        _mostrarMensaje('Proveedor actualizado');
      }
      await _cargarProveedores();
    } on ApiException catch (error) {
      _mostrarMensaje(error.message);
    } catch (_) {
      _mostrarMensaje('No se pudo guardar el proveedor');
    } finally {
      if (mounted) {
        setState(() {
          _procesando = false;
        });
      }
    }
  }

  Future<void> _cambiarEstado(ProveedorApi proveedor) async {
    setState(() {
      _procesando = true;
    });

    try {
      await _proveedoresApiService.cambiarEstado(
        proveedor.idProveedor,
        activo: !proveedor.activo,
      );
      _mostrarMensaje(
        proveedor.activo ? 'Proveedor desactivado' : 'Proveedor activado',
      );
      await _cargarProveedores();
    } on ApiException catch (error) {
      _mostrarMensaje(error.message);
    } catch (_) {
      _mostrarMensaje('No se pudo cambiar el estado');
    } finally {
      if (mounted) {
        setState(() {
          _procesando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activos = _proveedores.where((proveedor) => proveedor.activo).length;
    final inactivos = _proveedores.length - activos;

    return Container(
      color: _fondoPagina,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EncabezadoProveedores(
              onNuevo: _procesando ? null : () => _guardarProveedor(),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _TarjetaResumenProveedor(
                    titulo: 'TOTAL',
                    valor: '${_proveedores.length}',
                    icono: Icons.local_shipping_outlined,
                    fondoIcono: const Color(0xFFEAF7DF),
                    colorIcono: _verdeOscuro,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: _TarjetaResumenProveedor(
                    titulo: 'ACTIVOS',
                    valor: '$activos',
                    icono: Icons.check_circle_outline,
                    fondoIcono: const Color(0xFFE8F1FF),
                    colorIcono: _azul,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: _TarjetaResumenProveedor(
                    titulo: 'INACTIVOS',
                    valor: '$inactivos',
                    icono: Icons.cancel_outlined,
                    fondoIcono: const Color(0xFFFFE8E8),
                    colorIcono: _rojo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _PanelFiltrosProveedores(
              busquedaController: _busquedaController,
              estadoSeleccionado: _estadoSeleccionado,
              onEstadoChanged: (estado) {
                setState(() {
                  _estadoSeleccionado = estado;
                });
              },
              onBuscar: _cargarProveedores,
              onRefrescar: _cargarProveedores,
            ),
            const SizedBox(height: 18),
            if (_cargando)
              const _EstadoProveedores(mensaje: 'Cargando proveedores...')
            else if (_error != null)
              _EstadoProveedores(
                mensaje: _error!,
                onReintentar: _cargarProveedores,
              )
            else if (_proveedoresFiltrados.isEmpty)
              const _EstadoProveedores(
                  mensaje: 'No hay proveedores para mostrar')
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final anchoTabla =
                      constraints.maxWidth < 980 ? 980.0 : constraints.maxWidth;
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: anchoTabla,
                      child: _TablaProveedores(
                        proveedores: _proveedoresFiltrados,
                        procesando: _procesando,
                        onEditar: (proveedor) =>
                            _guardarProveedor(proveedor: proveedor),
                        onCambiarEstado: _cambiarEstado,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _EncabezadoProveedores extends StatelessWidget {
  final VoidCallback? onNuevo;

  const _EncabezadoProveedores({required this.onNuevo});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Proveedores',
                style: TextStyle(
                  color: _textoPrincipal,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Directorio de proveedores para compras y abastecimiento.',
                style: TextStyle(
                  color: Color(0xFF214025),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 36,
          child: ElevatedButton.icon(
            onPressed: onNuevo,
            icon: const Icon(Icons.add, size: 18, color: Colors.white),
            label: const Text(
              'Nuevo Proveedor',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _verdeOscuro,
              elevation: 7,
              shadowColor: _verdeOscuro.withValues(alpha: 0.35),
              padding: const EdgeInsets.symmetric(horizontal: 22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TarjetaResumenProveedor extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color fondoIcono;
  final Color colorIcono;

  const _TarjetaResumenProveedor({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.fondoIcono,
    required this.colorIcono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _bordeSuave),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: fondoIcono,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icono, color: colorIcono, size: 23),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Color(0xFF34423B),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  valor,
                  style: const TextStyle(
                    color: _textoPrincipal,
                    fontSize: 20,
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

class _PanelFiltrosProveedores extends StatelessWidget {
  final TextEditingController busquedaController;
  final String estadoSeleccionado;
  final ValueChanged<String> onEstadoChanged;
  final VoidCallback onBuscar;
  final VoidCallback onRefrescar;

  const _PanelFiltrosProveedores({
    required this.busquedaController,
    required this.estadoSeleccionado,
    required this.onEstadoChanged,
    required this.onBuscar,
    required this.onRefrescar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        color: _fondoPagina,
        border: Border.all(color: _bordeSuave),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          SizedBox(
            width: 280,
            child: TextField(
              controller: busquedaController,
              onSubmitted: (_) => onBuscar(),
              decoration: InputDecoration(
                labelText: 'Buscar proveedor',
                hintText: 'Nombre, contacto o telefono',
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                fillColor: _grisCampo,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFC8D6C0)),
                ),
                isDense: true,
              ),
            ),
          ),
          SizedBox(
            width: 160,
            child: DropdownButtonFormField<String>(
              initialValue: estadoSeleccionado,
              decoration: InputDecoration(
                labelText: 'Estado',
                filled: true,
                fillColor: _grisCampo,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFC8D6C0)),
                ),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                DropdownMenuItem(value: 'Activos', child: Text('Activos')),
                DropdownMenuItem(value: 'Inactivos', child: Text('Inactivos')),
              ],
              onChanged: (value) {
                if (value == null) return;
                onEstadoChanged(value);
              },
            ),
          ),
          _BotonSecundario(
            texto: 'Buscar',
            icono: Icons.search,
            onTap: onBuscar,
          ),
          _BotonSecundario(
            texto: 'Actualizar',
            icono: Icons.refresh,
            onTap: onRefrescar,
          ),
        ],
      ),
    );
  }
}

class _BotonSecundario extends StatelessWidget {
  final String texto;
  final IconData icono;
  final VoidCallback onTap;

  const _BotonSecundario({
    required this.texto,
    required this.icono,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icono, size: 16, color: _textoSecundario),
        label: Text(
          texto,
          style: const TextStyle(
            color: _textoPrincipal,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          side: const BorderSide(color: Color(0xFFC8D6C0)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }
}

class _TablaProveedores extends StatelessWidget {
  final List<ProveedorApi> proveedores;
  final bool procesando;
  final ValueChanged<ProveedorApi> onEditar;
  final ValueChanged<ProveedorApi> onCambiarEstado;

  const _TablaProveedores({
    required this.proveedores,
    required this.procesando,
    required this.onEditar,
    required this.onCambiarEstado,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _bordeSuave),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        children: [
          const _HeaderTablaProveedores(),
          for (final proveedor in proveedores)
            _FilaProveedor(
              proveedor: proveedor,
              procesando: procesando,
              onEditar: onEditar,
              onCambiarEstado: onCambiarEstado,
            ),
        ],
      ),
    );
  }
}

class _HeaderTablaProveedores extends StatelessWidget {
  const _HeaderTablaProveedores();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: const BoxDecoration(
        color: Color(0xFFE7E3E3),
        borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 18),
          Expanded(flex: 8, child: _TextoHeader('ID')),
          Expanded(flex: 28, child: _TextoHeader('PROVEEDOR')),
          Expanded(flex: 18, child: _TextoHeader('CONTACTO')),
          Expanded(flex: 16, child: _TextoHeader('TELEFONO')),
          Expanded(flex: 24, child: _TextoHeader('DIRECCION')),
          Expanded(flex: 12, child: _TextoHeader('ESTADO')),
          Expanded(flex: 14, child: _TextoHeader('ACCIONES')),
          SizedBox(width: 12),
        ],
      ),
    );
  }
}

class _TextoHeader extends StatelessWidget {
  final String texto;

  const _TextoHeader(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        color: Color(0xFF34423B),
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _FilaProveedor extends StatelessWidget {
  final ProveedorApi proveedor;
  final bool procesando;
  final ValueChanged<ProveedorApi> onEditar;
  final ValueChanged<ProveedorApi> onCambiarEstado;

  const _FilaProveedor({
    required this.proveedor,
    required this.procesando,
    required this.onEditar,
    required this.onCambiarEstado,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 62),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE0E8D8))),
        ),
        child: Row(
          children: [
            const SizedBox(width: 18),
            Expanded(
              flex: 8,
              child: Text(
                '${proveedor.idProveedor}',
                style: const TextStyle(
                  color: _verdeOscuro,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Expanded(
              flex: 28,
              child: Text(
                proveedor.nombre,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _textoPrincipal,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Expanded(
              flex: 18,
              child: _TextoTabla(proveedor.contacto, fallback: 'Sin contacto'),
            ),
            Expanded(
              flex: 16,
              child: _TextoTabla(proveedor.telefono, fallback: 'Sin telefono'),
            ),
            Expanded(
              flex: 24,
              child:
                  _TextoTabla(proveedor.direccion, fallback: 'Sin direccion'),
            ),
            Expanded(
              flex: 12,
              child: _BadgeEstadoProveedor(activo: proveedor.activo),
            ),
            Expanded(
              flex: 14,
              child: Row(
                children: [
                  IconButton(
                    onPressed: procesando ? null : () => onEditar(proveedor),
                    tooltip: 'Editar',
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    color: _verdeOscuro,
                  ),
                  IconButton(
                    onPressed:
                        procesando ? null : () => onCambiarEstado(proveedor),
                    tooltip: proveedor.activo ? 'Desactivar' : 'Activar',
                    icon: Icon(
                      proveedor.activo
                          ? Icons.toggle_on_outlined
                          : Icons.toggle_off_outlined,
                      size: 22,
                    ),
                    color: proveedor.activo ? _verdeOscuro : _rojo,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

class _TextoTabla extends StatelessWidget {
  final String texto;
  final String fallback;

  const _TextoTabla(this.texto, {required this.fallback});

  @override
  Widget build(BuildContext context) {
    return Text(
      texto.isEmpty ? fallback : texto,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: _textoPrincipal,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _BadgeEstadoProveedor extends StatelessWidget {
  final bool activo;

  const _BadgeEstadoProveedor({required this.activo});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: activo ? const Color(0xFFEAF8DD) : const Color(0xFFFFE8E8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          activo ? 'Activo' : 'Inactivo',
          style: TextStyle(
            color: activo ? _verdeOscuro : _rojo,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _EstadoProveedores extends StatelessWidget {
  final String mensaje;
  final VoidCallback? onReintentar;

  const _EstadoProveedores({
    required this.mensaje,
    this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 42),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textoPrincipal,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (onReintentar != null) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: onReintentar,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DialogoProveedor extends StatefulWidget {
  final ProveedorApi? proveedor;

  const _DialogoProveedor({this.proveedor});

  @override
  State<_DialogoProveedor> createState() => _DialogoProveedorState();
}

class _DialogoProveedorState extends State<_DialogoProveedor> {
  late final TextEditingController _nombreController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _contactoController;
  late final TextEditingController _direccionController;
  String? _error;

  @override
  void initState() {
    super.initState();
    final proveedor = widget.proveedor;
    _nombreController = TextEditingController(text: proveedor?.nombre ?? '');
    _telefonoController =
        TextEditingController(text: proveedor?.telefono ?? '');
    _contactoController =
        TextEditingController(text: proveedor?.contacto ?? '');
    _direccionController =
        TextEditingController(text: proveedor?.direccion ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _contactoController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  void _confirmar() {
    final nombre = _nombreController.text.trim();
    if (nombre.isEmpty) {
      setState(() {
        _error = 'Ingresa el nombre del proveedor';
      });
      return;
    }

    Navigator.of(context).pop(
      ProveedorPayload(
        nombre: nombre,
        telefono: _limpiar(_telefonoController.text),
        contacto: _limpiar(_contactoController.text),
        direccion: _limpiar(_direccionController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.proveedor == null ? 'Nuevo proveedor' : 'Editar proveedor'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CampoDialogo(label: 'Nombre', controller: _nombreController),
            const SizedBox(height: 12),
            _CampoDialogo(label: 'Contacto', controller: _contactoController),
            const SizedBox(height: 12),
            _CampoDialogo(label: 'Telefono', controller: _telefonoController),
            const SizedBox(height: 12),
            _CampoDialogo(
              label: 'Direccion',
              controller: _direccionController,
              maxLines: 2,
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: _rojo,
                    fontWeight: FontWeight.w800,
                  ),
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
        ElevatedButton(
          onPressed: _confirmar,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _CampoDialogo extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;

  const _CampoDialogo({
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

String? _limpiar(String value) {
  final text = value.trim();
  return text.isEmpty ? null : text;
}
