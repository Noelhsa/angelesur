import 'package:flutter/material.dart';

import '../../models/usuario.dart';
import 'menu_carta_perfil.dart';

const Color _fondoPagina = Color(0xFFE2E2E2);
const Color _verdeOscuro = Color(0xFF397800);
const Color _verde = Color(0xFF64D20A);
const Color _azul = Color(0xFF0B63CE);
const Color _textoPrincipal = Color(0xFF101828);
const Color _textoSecundario = Color(0xFF667085);
const Color _bordeSuave = Color(0xFFD9E6D3);
const Color _grisCabeceraTabla = Color(0xFFE7E3E3);
const Color _rojo = Color(0xFFE02020);

class EditarPerfilScreen extends StatelessWidget {
  final Usuario usuario;

  const EditarPerfilScreen({
    super.key,
    required this.usuario,
  });

  @override
  Widget build(BuildContext context) {
    return ContenidoPerfil(usuario: usuario);
  }
}

class ContenidoPerfil extends StatefulWidget {
  final Usuario usuario;

  const ContenidoPerfil({
    super.key,
    required this.usuario,
  });

  @override
  State<ContenidoPerfil> createState() => _ContenidoPerfilState();
}

class _ContenidoPerfilState extends State<ContenidoPerfil> {
  final TextEditingController _busquedaController = TextEditingController();

  bool _mostrarMenuNuevoUsuario = false;
  String _rolSeleccionado = 'Todos los Roles';

  List<_UsuarioSistema> get _usuarios {
    return [
      _UsuarioSistema(
        nombre: widget.usuario.nombre,
        telefono: 'Sin teléfono',
        rol: widget.usuario.rol,
        ultimoAcceso: 'Sesión actual',
        estado: _EstadoUsuario.activo,
        colorAvatar: const Color(0xFFE8F1FF),
        iniciales: _obtenerIniciales(widget.usuario.nombre),
      ),
      const _UsuarioSistema(
        nombre: 'Carlos Méndez',
        telefono: '9221119323',
        rol: 'Cajero',
        ultimoAcceso: 'Hoy, 08:45 AM',
        estado: _EstadoUsuario.activo,
        colorAvatar: Color(0xFFE8F1FF),
        iniciales: 'CM',
      ),
      const _UsuarioSistema(
        nombre: 'Elena Rodríguez',
        telefono: '9221772986',
        rol: 'Admin',
        ultimoAcceso: 'Ayer, 05:12 PM',
        estado: _EstadoUsuario.activo,
        colorAvatar: Color(0xFFEAF7DF),
        iniciales: 'ER',
      ),
      const _UsuarioSistema(
        nombre: 'Samuel Torres',
        telefono: '9221887654',
        rol: 'Auxiliar',
        ultimoAcceso: '12 Oct, 2023',
        estado: _EstadoUsuario.inactivo,
        colorAvatar: Color(0xFFFFE8E8),
        iniciales: 'ST',
      ),
      const _UsuarioSistema(
        nombre: 'Roberto Díaz',
        telefono: '9221555555',
        rol: 'Cajero',
        ultimoAcceso: 'Hoy, 10:30 AM',
        estado: _EstadoUsuario.activo,
        colorAvatar: Color(0xFFE8F1FF),
        iniciales: 'RD',
      ),
    ];
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  String _obtenerIniciales(String nombre) {
    final partes = nombre.trim().split(RegExp(r'\s+'));

    if (partes.isEmpty || partes.first.isEmpty) {
      return 'US';
    }

    if (partes.length == 1) {
      return partes.first.substring(0, 1).toUpperCase();
    }

    return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
  }

  List<_UsuarioSistema> get _usuariosFiltrados {
    final texto = _busquedaController.text.trim().toLowerCase();

    return _usuarios.where((usuario) {
      final coincideTexto = texto.isEmpty ||
          usuario.nombre.toLowerCase().contains(texto) ||
          usuario.telefono.toLowerCase().contains(texto) ||
          usuario.rol.toLowerCase().contains(texto);

      final coincideRol = _rolSeleccionado == 'Todos los Roles' ||
          usuario.rol == _rolSeleccionado;

      return coincideTexto && coincideRol;
    }).toList();
  }

  int get _usuariosActivos {
    return _usuarios
        .where((usuario) => usuario.estado == _EstadoUsuario.activo)
        .length;
  }

  int get _administradores {
    return _usuarios.where((usuario) => usuario.rol == 'Admin').length;
  }

  int get _invitacionesPendientes {
    return 2;
  }

  void _abrirMenuNuevoUsuario() {
    setState(() {
      _mostrarMenuNuevoUsuario = true;
    });
  }

  void _cerrarMenuNuevoUsuario() {
    setState(() {
      _mostrarMenuNuevoUsuario = false;
    });
  }

  void _guardarUsuario() {
    setState(() {
      _mostrarMenuNuevoUsuario = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Usuario guardado localmente. Falta conectar endpoint.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _fondoPagina,
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.topLeft,
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  color: _fondoPagina,
                  padding: const EdgeInsets.fromLTRB(26, 26, 26, 34),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _EncabezadoUsuarios(
                        onNuevoUsuario: _abrirMenuNuevoUsuario,
                      ),
                      const SizedBox(height: 28),
                      _ResumenUsuarios(
                        totalUsuarios: _usuarios.length,
                        usuariosActivos: _usuariosActivos,
                        administradores: _administradores,
                        invitacionesPendientes: _invitacionesPendientes,
                      ),
                      const SizedBox(height: 28),
                      _PanelUsuarios(
                        busquedaController: _busquedaController,
                        rolSeleccionado: _rolSeleccionado,
                        onBuscar: () {
                          setState(() {});
                        },
                        onRolChanged: (value) {
                          if (value == null) return;

                          setState(() {
                            _rolSeleccionado = value;
                          });
                        },
                        usuarios: _usuariosFiltrados,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_mostrarMenuNuevoUsuario)
            MenuCartaPerfil(
              onCerrar: _cerrarMenuNuevoUsuario,
              onGuardarUsuario: _guardarUsuario,
            ),
        ],
      ),
    );
  }
}

class _EncabezadoUsuarios extends StatelessWidget {
  final VoidCallback onNuevoUsuario;

  const _EncabezadoUsuarios({
    required this.onNuevoUsuario,
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
                'Gestión de Usuarios',
                style: TextStyle(
                  color: _textoPrincipal,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Administre los accesos, roles y permisos del personal de la farmacia.',
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
  final int invitacionesPendientes;

  const _ResumenUsuarios({
    required this.totalUsuarios,
    required this.usuariosActivos,
    required this.administradores,
    required this.invitacionesPendientes,
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
        const SizedBox(width: 22),
        Expanded(
          child: _TarjetaResumenUsuario(
            titulo: 'Usuarios Activos',
            valor: '$usuariosActivos',
            icono: Icons.check_circle_outline,
            fondoIcono: const Color(0xFFE5FFD9),
            colorIcono: _verde,
          ),
        ),
        const SizedBox(width: 22),
        Expanded(
          child: _TarjetaResumenUsuario(
            titulo: 'Administradores',
            valor: '$administradores',
            icono: Icons.admin_panel_settings_outlined,
            fondoIcono: const Color(0xFFE8E8E8),
            colorIcono: const Color(0xFF4C555F),
          ),
        ),
        const SizedBox(width: 22),
        Expanded(
          child: _TarjetaResumenUsuario(
            titulo: 'Inv. Pendientes',
            valor: '$invitacionesPendientes',
            icono: Icons.mail_outline,
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
            child: Icon(
              icono,
              color: colorIcono,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelUsuarios extends StatelessWidget {
  final TextEditingController busquedaController;
  final String rolSeleccionado;
  final VoidCallback onBuscar;
  final ValueChanged<String?> onRolChanged;
  final List<_UsuarioSistema> usuarios;

  const _PanelUsuarios({
    required this.busquedaController,
    required this.rolSeleccionado,
    required this.onBuscar,
    required this.onRolChanged,
    required this.usuarios,
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
                  width: 310,
                  height: 38,
                  child: TextField(
                    controller: busquedaController,
                    onChanged: (_) => onBuscar(),
                    cursorColor: _verdeOscuro,
                    style: const TextStyle(
                      color: _textoPrincipal,
                      fontSize: 12,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF6F4F1),
                      hintText: 'Buscar por nombre, teléfono o cargo...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF7E8790),
                        fontSize: 12,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
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
                        borderSide: const BorderSide(
                          color: _verdeOscuro,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 140,
                  height: 38,
                  child: DropdownButtonFormField<String>(
                    initialValue: rolSeleccionado,
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF6F4F1),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFFC8D6C0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFFC8D6C0)),
                      ),
                    ),
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
                      DropdownMenuItem(
                        value: 'Todos los Roles',
                        child: Text('Todos los Roles'),
                      ),
                      DropdownMenuItem(
                        value: 'Admin',
                        child: Text('Admin'),
                      ),
                      DropdownMenuItem(
                        value: 'Cajero',
                        child: Text('Cajero'),
                      ),
                      DropdownMenuItem(
                        value: 'Auxiliar',
                        child: Text('Auxiliar'),
                      ),
                    ],
                    onChanged: onRolChanged,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.filter_list,
                      size: 15,
                      color: _textoPrincipal,
                    ),
                    label: const Text(
                      'Filtros',
                      style: TextStyle(
                        color: _textoPrincipal,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFC8D6C0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final anchoTabla =
                  constraints.maxWidth < 900 ? 900.0 : constraints.maxWidth;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: anchoTabla,
                  child: _TablaUsuarios(
                    usuarios: usuarios,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TablaUsuarios extends StatelessWidget {
  final List<_UsuarioSistema> usuarios;

  const _TablaUsuarios({
    required this.usuarios,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _HeaderTablaUsuarios(),
        if (usuarios.isEmpty)
          const _EstadoUsuariosVacio()
        else
          for (final usuario in usuarios) _FilaUsuario(usuario: usuario),
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
          Expanded(flex: 23, child: _TextoHeaderTabla('Usuario')),
          Expanded(flex: 22, child: _TextoHeaderTabla('Teléfono')),
          Expanded(flex: 15, child: _TextoHeaderTabla('Rol')),
          Expanded(flex: 18, child: _TextoHeaderTabla('Último\nAcceso')),
          Expanded(flex: 15, child: _TextoHeaderTabla('Estado')),
          Expanded(flex: 12, child: _TextoHeaderTabla('Acciones')),
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
  final _UsuarioSistema usuario;

  const _FilaUsuario({
    required this.usuario,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE0E8D8),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 22),
          Expanded(
            flex: 23,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: usuario.colorAvatar,
                  child: Text(
                    usuario.iniciales,
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
            flex: 22,
            child: Text(
              usuario.telefono,
              style: const TextStyle(
                color: Color(0xFF6A736C),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 15,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _BadgeRol(rol: usuario.rol),
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              usuario.ultimoAcceso,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF6A736C),
                fontSize: 12,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 15,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _BadgeEstadoUsuario(estado: usuario.estado),
            ),
          ),
          Expanded(
            flex: 12,
            child: Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.edit_outlined),
                  iconSize: 18,
                  color: _verdeOscuro,
                  tooltip: 'Editar',
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_vert),
                  iconSize: 18,
                  color: _textoSecundario,
                  tooltip: 'Más opciones',
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

class _BadgeRol extends StatelessWidget {
  final String rol;

  const _BadgeRol({
    required this.rol,
  });

  @override
  Widget build(BuildContext context) {
    Color fondo;
    Color texto;

    switch (rol) {
      case 'Admin':
        fondo = const Color(0xFFE8F1FF);
        texto = _azul;
        break;
      case 'Cajero':
        fondo = const Color(0xFFE4ECFF);
        texto = const Color(0xFF102A6B);
        break;
      default:
        fondo = const Color(0xFFE4E4E4);
        texto = const Color(0xFF555D66);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        rol,
        style: TextStyle(
          color: texto,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BadgeEstadoUsuario extends StatelessWidget {
  final _EstadoUsuario estado;

  const _BadgeEstadoUsuario({
    required this.estado,
  });

  @override
  Widget build(BuildContext context) {
    final activo = estado == _EstadoUsuario.activo;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: activo ? const Color(0xFFE8F5DD) : const Color(0xFFFFE8E8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        activo ? '● Activo' : '● Inactivo',
        style: TextStyle(
          color: activo ? _verdeOscuro : _rojo,
          fontSize: 10,
          fontWeight: FontWeight.w900,
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

class _UsuarioSistema {
  final String nombre;
  final String telefono;
  final String rol;
  final String ultimoAcceso;
  final _EstadoUsuario estado;
  final Color colorAvatar;
  final String iniciales;

  const _UsuarioSistema({
    required this.nombre,
    required this.telefono,
    required this.rol,
    required this.ultimoAcceso,
    required this.estado,
    required this.colorAvatar,
    required this.iniciales,
  });
}

enum _EstadoUsuario {
  activo,
  inactivo,
}