import 'package:flutter/material.dart';

import '../../models/usuario.dart';
import '../../services/api_client.dart';
import '../../services/usuarios_api_service.dart';
import 'menu_carta_usuario.dart';

const Color _fondoPagina = Color(0xFFE2E2E2);
const Color _verdeOscuro = Color(0xFF397800);
const Color _verde = Color(0xFF64D20A);
const Color _azul = Color(0xFF0B63CE);
const Color _textoPrincipal = Color(0xFF101828);
const Color _textoSecundario = Color(0xFF667085);
const Color _bordeSuave = Color(0xFFD9E6D3);
const Color _grisCabeceraTabla = Color(0xFFE7E3E3);
const Color _rojo = Color(0xFFE02020);

class ContenidoUsuarios extends StatefulWidget {
  final Usuario usuario;

  const ContenidoUsuarios({
    super.key,
    required this.usuario,
  });

  @override
  State<ContenidoUsuarios> createState() => _ContenidoUsuariosState();
}

class _ContenidoUsuariosState extends State<ContenidoUsuarios> {
  final UsuariosApiService _usuariosApiService = UsuariosApiService();
  final TextEditingController _busquedaController = TextEditingController();

  bool _cargando = true;
  bool _guardando = false;
  bool _mostrarMenuNuevoUsuario = false;
  String? _error;
  String _rolSeleccionado = 'Todos';
  List<Usuario> _usuarios = [];
  Usuario? _usuarioEditando;

  @override
  void initState() {
    super.initState();
    _busquedaController.addListener(() {
      setState(() {});
    });
    _cargarUsuarios();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  List<Usuario> get _usuariosFiltrados {
    final texto = _busquedaController.text.trim().toLowerCase();

    return _usuarios.where((usuario) {
      final coincideTexto = texto.isEmpty ||
          usuario.nombre.toLowerCase().contains(texto) ||
          usuario.username.toLowerCase().contains(texto) ||
          (usuario.telefono ?? '').toLowerCase().contains(texto) ||
          usuario.rol.toLowerCase().contains(texto);
      final coincideRol = _rolSeleccionado == 'Todos' ||
          usuario.rol.toUpperCase() == _rolSeleccionado;

      return coincideTexto && coincideRol;
    }).toList();
  }

  int get _usuariosActivos {
    return _usuarios.where((usuario) => usuario.activo).length;
  }

  int get _jefes {
    return _usuarios.where((usuario) => usuario.rol == 'JEFE').length;
  }

  Future<void> _cargarUsuarios() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final usuarios = await _usuariosApiService.listarUsuarios(
        incluirInactivos: true,
      );
      if (!mounted) return;

      setState(() {
        _usuarios = usuarios;
        _cargando = false;
      });
    } on ApiException catch (error) {
      _mostrarError(error.message);
    } catch (_) {
      _mostrarError('No se pudieron cargar los usuarios');
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;

    setState(() {
      _error = mensaje;
      _cargando = false;
      _guardando = false;
    });
  }

  Future<void> _guardarUsuario(DatosFormularioUsuario datos) async {
    setState(() {
      _guardando = true;
    });

    try {
      final usuario = await _usuariosApiService.crearUsuario(
        nombre: datos.nombre,
        username: datos.username,
        password: datos.password,
        rol: datos.rol,
        telefono: datos.telefono.isEmpty ? null : datos.telefono,
      );

      if (!datos.activo) {
        await _usuariosApiService.cambiarEstado(
          idUsuario: usuario.id,
          activo: false,
        );
      }

      await _cargarUsuarios();
      if (!mounted) return;

      setState(() {
        _mostrarMenuNuevoUsuario = false;
        _guardando = false;
      });

      _mostrarSnack('Usuario creado.');
    } on ApiException catch (error) {
      _mostrarSnack(error.message);
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    } catch (_) {
      _mostrarSnack('No se pudo guardar el usuario');
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  Future<void> _guardarEdicionUsuario(DatosFormularioUsuario datos) async {
    final usuarioEditando = _usuarioEditando;
    if (usuarioEditando == null) return;

    if (usuarioEditando.id == widget.usuario.id && !datos.activo) {
      _mostrarSnack('No puedes desactivar tu propia sesion.');
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      await _usuariosApiService.actualizarUsuario(
        idUsuario: usuarioEditando.id,
        nombre: datos.nombre,
        username: datos.username,
        password: datos.password.isEmpty ? null : datos.password,
        rol: datos.rol,
        telefono: datos.telefono,
      );

      if (datos.activo != usuarioEditando.activo) {
        await _usuariosApiService.cambiarEstado(
          idUsuario: usuarioEditando.id,
          activo: datos.activo,
        );
      }

      await _cargarUsuarios();
      if (!mounted) return;

      setState(() {
        _mostrarMenuNuevoUsuario = false;
        _usuarioEditando = null;
        _guardando = false;
      });

      _mostrarSnack('Usuario actualizado.');
    } on ApiException catch (error) {
      _mostrarSnack(error.message);
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    } catch (_) {
      _mostrarSnack('No se pudo actualizar el usuario');
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  void _abrirNuevoUsuario() {
    setState(() {
      _usuarioEditando = null;
      _mostrarMenuNuevoUsuario = true;
    });
  }

  void _abrirEditarUsuario(Usuario usuario) {
    setState(() {
      _usuarioEditando = usuario;
      _mostrarMenuNuevoUsuario = true;
    });
  }

  void _cerrarMenuUsuario() {
    setState(() {
      _mostrarMenuNuevoUsuario = false;
      _usuarioEditando = null;
      _guardando = false;
    });
  }

  Future<void> _cambiarEstado(Usuario usuario) async {
    try {
      await _usuariosApiService.cambiarEstado(
        idUsuario: usuario.id,
        activo: !usuario.activo,
      );
      await _cargarUsuarios();
    } on ApiException catch (error) {
      _mostrarSnack(error.message);
    } catch (_) {
      _mostrarSnack('No se pudo cambiar el estado del usuario');
    }
  }

  void _mostrarSnack(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _fondoPagina,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(26, 26, 26, 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _EncabezadoUsuarios(
                    onNuevoUsuario: _abrirNuevoUsuario,
                    onRefrescar: _cargarUsuarios,
                  ),
                  const SizedBox(height: 24),
                  _ResumenUsuarios(
                    totalUsuarios: _usuarios.length,
                    usuariosActivos: _usuariosActivos,
                    administradores: _jefes,
                    empleados: _usuarios.length - _jefes,
                  ),
                  const SizedBox(height: 24),
                  if (_cargando)
                    const _EstadoUsuarios(mensaje: 'Cargando usuarios...')
                  else if (_error != null)
                    _EstadoUsuarios(
                      mensaje: _error!,
                      onReintentar: _cargarUsuarios,
                    )
                  else
                    _PanelUsuarios(
                      busquedaController: _busquedaController,
                      rolSeleccionado: _rolSeleccionado,
                      onRolChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _rolSeleccionado = value;
                        });
                      },
                      usuarios: _usuariosFiltrados,
                      usuarioActualId: widget.usuario.id,
                      onCambiarEstado: _cambiarEstado,
                      onEditar: _abrirEditarUsuario,
                    ),
                ],
              ),
            ),
          ),
          if (_mostrarMenuNuevoUsuario)
            MenuCartaUsuario(
              usuario: _usuarioEditando,
              guardando: _guardando,
              onCerrar: _cerrarMenuUsuario,
              onGuardarUsuario: _usuarioEditando == null
                  ? _guardarUsuario
                  : _guardarEdicionUsuario,
            ),
        ],
      ),
    );
  }
}

class _EncabezadoUsuarios extends StatelessWidget {
  final VoidCallback onNuevoUsuario;
  final VoidCallback onRefrescar;

  const _EncabezadoUsuarios({
    required this.onNuevoUsuario,
    required this.onRefrescar,
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
                'Usuarios',
                style: TextStyle(
                  color: _textoPrincipal,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Administra accesos, roles y estado del personal.',
                style: TextStyle(
                  color: Color(0xFF214025),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onRefrescar,
          tooltip: 'Actualizar',
          icon: const Icon(Icons.refresh, color: _textoSecundario),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 38,
          child: ElevatedButton.icon(
            onPressed: onNuevoUsuario,
            icon: const Icon(
              Icons.person_add_alt_1,
              color: Colors.white,
              size: 17,
            ),
            label: const Text(
              'Nuevo Usuario',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _verdeOscuro,
              elevation: 6,
              shadowColor: _verdeOscuro.withValues(alpha: 0.25),
              padding: const EdgeInsets.symmetric(horizontal: 28),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResumenUsuarios extends StatelessWidget {
  final int totalUsuarios;
  final int usuariosActivos;
  final int administradores;
  final int empleados;

  const _ResumenUsuarios({
    required this.totalUsuarios,
    required this.usuariosActivos,
    required this.administradores,
    required this.empleados,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TarjetaResumenUsuario(
            titulo: 'Total Usuarios',
            valor: '$totalUsuarios',
            icono: Icons.group_outlined,
            fondoIcono: const Color(0xFFE8F1FF),
            colorIcono: _azul,
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: _TarjetaResumenUsuario(
            titulo: 'Activos',
            valor: '$usuariosActivos',
            icono: Icons.check_circle_outline,
            fondoIcono: const Color(0xFFE5FFD9),
            colorIcono: _verde,
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: _TarjetaResumenUsuario(
            titulo: 'Jefes',
            valor: '$administradores',
            icono: Icons.admin_panel_settings_outlined,
            fondoIcono: const Color(0xFFE8E8E8),
            colorIcono: const Color(0xFF4C555F),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: _TarjetaResumenUsuario(
            titulo: 'Empleados',
            valor: '$empleados',
            icono: Icons.badge_outlined,
            fondoIcono: const Color(0xFFE8F1FF),
            colorIcono: _azul,
          ),
        ),
      ],
    );
  }
}

class _TarjetaResumenUsuario extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color fondoIcono;
  final Color colorIcono;

  const _TarjetaResumenUsuario({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.fondoIcono,
    required this.colorIcono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _bordeSuave),
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6A736C),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  valor,
                  style: const TextStyle(
                    color: _textoPrincipal,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: fondoIcono,
              shape: BoxShape.circle,
            ),
            child: Icon(icono, color: colorIcono, size: 22),
          ),
        ],
      ),
    );
  }
}

class _PanelUsuarios extends StatelessWidget {
  final TextEditingController busquedaController;
  final String rolSeleccionado;
  final ValueChanged<String?> onRolChanged;
  final List<Usuario> usuarios;
  final int usuarioActualId;
  final ValueChanged<Usuario> onCambiarEstado;
  final ValueChanged<Usuario> onEditar;

  const _PanelUsuarios({
    required this.busquedaController,
    required this.rolSeleccionado,
    required this.onRolChanged,
    required this.usuarios,
    required this.usuarioActualId,
    required this.onCambiarEstado,
    required this.onEditar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _fondoPagina,
        border: Border.all(color: _bordeSuave),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
            child: Row(
              children: [
                SizedBox(
                  width: 330,
                  height: 38,
                  child: TextField(
                    controller: busquedaController,
                    cursorColor: _verdeOscuro,
                    style: const TextStyle(
                      color: _textoPrincipal,
                      fontSize: 12,
                    ),
                    decoration: _inputDecoration(
                      hintText: 'Buscar por nombre, usuario, telefono o rol...',
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 150,
                  height: 38,
                  child: DropdownButtonFormField<String>(
                    initialValue: rolSeleccionado,
                    isExpanded: true,
                    decoration: _inputDecoration(),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 17,
                      color: _textoSecundario,
                    ),
                    style: const TextStyle(
                      color: _textoPrincipal,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                      DropdownMenuItem(value: 'JEFE', child: Text('JEFE')),
                      DropdownMenuItem(
                        value: 'EMPLEADO',
                        child: Text('EMPLEADO'),
                      ),
                    ],
                    onChanged: onRolChanged,
                  ),
                ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final anchoTabla =
                  constraints.maxWidth < 930 ? 930.0 : constraints.maxWidth;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: anchoTabla,
                  child: _TablaUsuarios(
                    usuarios: usuarios,
                    usuarioActualId: usuarioActualId,
                    onCambiarEstado: onCambiarEstado,
                    onEditar: onEditar,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF6F4F1),
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF7E8790),
        fontSize: 12,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFC8D6C0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFC8D6C0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: _verdeOscuro, width: 1.2),
      ),
    );
  }
}

class _TablaUsuarios extends StatelessWidget {
  final List<Usuario> usuarios;
  final int usuarioActualId;
  final ValueChanged<Usuario> onCambiarEstado;
  final ValueChanged<Usuario> onEditar;

  const _TablaUsuarios({
    required this.usuarios,
    required this.usuarioActualId,
    required this.onCambiarEstado,
    required this.onEditar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _HeaderTablaUsuarios(),
        if (usuarios.isEmpty)
          const _EstadoUsuariosVacio()
        else
          for (final usuario in usuarios)
            _FilaUsuario(
              usuario: usuario,
              esUsuarioActual: usuario.id == usuarioActualId,
              onCambiarEstado: () => onCambiarEstado(usuario),
              onEditar: () => onEditar(usuario),
            ),
      ],
    );
  }
}

class _HeaderTablaUsuarios extends StatelessWidget {
  const _HeaderTablaUsuarios();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      color: _grisCabeceraTabla,
      child: const Row(
        children: [
          SizedBox(width: 22),
          Expanded(flex: 24, child: _TextoHeaderTabla('Usuario')),
          Expanded(flex: 18, child: _TextoHeaderTabla('Username')),
          Expanded(flex: 18, child: _TextoHeaderTabla('Telefono')),
          Expanded(flex: 14, child: _TextoHeaderTabla('Rol')),
          Expanded(flex: 14, child: _TextoHeaderTabla('Estado')),
          Expanded(flex: 16, child: _TextoHeaderTabla('Acciones')),
          SizedBox(width: 16),
        ],
      ),
    );
  }
}

class _TextoHeaderTabla extends StatelessWidget {
  final String texto;

  const _TextoHeaderTabla(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        color: Color(0xFF747B65),
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _FilaUsuario extends StatelessWidget {
  final Usuario usuario;
  final bool esUsuarioActual;
  final VoidCallback onCambiarEstado;
  final VoidCallback onEditar;

  const _FilaUsuario({
    required this.usuario,
    required this.esUsuarioActual,
    required this.onCambiarEstado,
    required this.onEditar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0E8D8))),
      ),
      child: Row(
        children: [
          const SizedBox(width: 22),
          Expanded(
            flex: 24,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: usuario.activo
                      ? const Color(0xFFE8F1FF)
                      : const Color(0xFFFFE8E8),
                  child: Text(
                    _iniciales(usuario.nombre),
                    style: const TextStyle(
                      color: _textoPrincipal,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    usuario.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF56605A),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              usuario.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _textoFila,
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              usuario.telefono?.isEmpty == false
                  ? usuario.telefono!
                  : 'Sin telefono',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _textoFila,
            ),
          ),
          Expanded(
            flex: 14,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _BadgeRol(rol: usuario.rol),
            ),
          ),
          Expanded(
            flex: 14,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _BadgeEstadoUsuario(activo: usuario.activo),
            ),
          ),
          Expanded(
            flex: 16,
            child: Row(
              children: [
                IconButton(
                  onPressed: onEditar,
                  icon: const Icon(Icons.edit_outlined),
                  iconSize: 18,
                  color: _azul,
                  tooltip: 'Editar',
                ),
                IconButton(
                  onPressed: esUsuarioActual ? null : onCambiarEstado,
                  icon: Icon(
                    usuario.activo
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  iconSize: 18,
                  color: esUsuarioActual ? _textoSecundario : _verdeOscuro,
                  tooltip: esUsuarioActual
                      ? 'No puedes desactivar tu propia sesion'
                      : usuario.activo
                          ? 'Desactivar'
                          : 'Activar',
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  String _iniciales(String nombre) {
    final partes = nombre.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return 'US';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
  }
}

class _BadgeRol extends StatelessWidget {
  final String rol;

  const _BadgeRol({
    required this.rol,
  });

  @override
  Widget build(BuildContext context) {
    final jefe = rol == 'JEFE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: jefe ? const Color(0xFFE8F1FF) : const Color(0xFFE4E4E4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        rol,
        style: TextStyle(
          color: jefe ? _azul : const Color(0xFF555D66),
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BadgeEstadoUsuario extends StatelessWidget {
  final bool activo;

  const _BadgeEstadoUsuario({
    required this.activo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: activo ? const Color(0xFFE8F5DD) : const Color(0xFFFFE8E8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        activo ? 'Activo' : 'Inactivo',
        style: TextStyle(
          color: activo ? _verdeOscuro : _rojo,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EstadoUsuarios extends StatelessWidget {
  final String mensaje;
  final VoidCallback? onReintentar;

  const _EstadoUsuarios({
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

class _EstadoUsuariosVacio extends StatelessWidget {
  const _EstadoUsuariosVacio();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 90,
      child: Center(
        child: Text(
          'No hay usuarios para mostrar',
          style: TextStyle(
            color: _textoPrincipal,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

const TextStyle _textoFila = TextStyle(
  color: Color(0xFF6A736C),
  fontSize: 12,
  fontWeight: FontWeight.w700,
);
