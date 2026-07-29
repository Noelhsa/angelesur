import 'package:flutter/material.dart';

import '../../models/usuario.dart';

const Color _fondoPanel = Color(0xFFF8F8F8);
const Color _verdeOscuro = Color(0xFF397800);
const Color _textoPrincipal = Color(0xFF101828);
const Color _textoSecundario = Color(0xFF667085);
const Color _bordeSuave = Color(0xFFD9E6D3);
const Color _grisCampo = Color(0xFFF2F2F2);
const Color _rojo = Color(0xFFE02020);

class DatosFormularioUsuario {
  final String nombre;
  final String username;
  final String telefono;
  final String password;
  final String rol;
  final bool activo;

  const DatosFormularioUsuario({
    required this.nombre,
    required this.username,
    required this.telefono,
    required this.password,
    required this.rol,
    required this.activo,
  });
}

class MenuCartaUsuario extends StatefulWidget {
  final VoidCallback onCerrar;
  final ValueChanged<DatosFormularioUsuario> onGuardarUsuario;
  final bool guardando;
  final Usuario? usuario;

  const MenuCartaUsuario({
    super.key,
    required this.onCerrar,
    required this.onGuardarUsuario,
    this.guardando = false,
    this.usuario,
  });

  @override
  State<MenuCartaUsuario> createState() =>
      _MenuCartaUsuarioState();
}

class _MenuCartaUsuarioState extends State<MenuCartaUsuario> {
  final TextEditingController _nombreController =
      TextEditingController();

  final TextEditingController _usuarioController =
      TextEditingController();

  final TextEditingController _telefonoController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  String? _rolSeleccionado;
  bool _usuarioActivo = true;
  bool _passwordVisible = false;
  String? _error;

  bool get _editando => widget.usuario != null;

  @override
  void initState() {
    super.initState();

    final usuario = widget.usuario;

    if (usuario != null) {
      _nombreController.text = usuario.nombre;
      _usuarioController.text = usuario.username;
      _telefonoController.text = usuario.telefono ?? '';
      _rolSeleccionado = usuario.rol;
      _usuarioActivo = usuario.activo;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _usuarioController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: double.infinity,
      decoration: BoxDecoration(
        color: _fondoPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _bordeSuave,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.08,
            ),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                12,
                18,
                12,
                18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _EncabezadoNuevoUsuario(
                    editando: _editando,
                    onCerrar: widget.onCerrar,
                  ),
                  const SizedBox(height: 28),
                  _CampoTextoUsuario(
                    etiqueta: 'Nombre completo',
                    controller: _nombreController,
                    hintText: 'Ej: Juan Pérez',
                  ),
                  const SizedBox(height: 18),
                  _CampoTextoUsuario(
                    etiqueta: 'Nombre de usuario',
                    controller: _usuarioController,
                    hintText: 'Ej: jperez',
                  ),
                  const SizedBox(height: 18),
                  _CampoTextoUsuario(
                    etiqueta: 'Teléfono',
                    controller: _telefonoController,
                    hintText: 'Ej: +52 55 1234 5678',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 18),
                  _CampoTextoUsuario(
                    etiqueta: _editando
                        ? 'Nueva contraseña (opcional)'
                        : 'Contraseña',
                    controller: _passwordController,
                    hintText: '••••••••',
                    obscureText: !_passwordVisible,
                    suffixWidget: IconButton(
                      onPressed: () {
                        setState(() {
                          _passwordVisible =
                              !_passwordVisible;
                        });
                      },
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: _textoSecundario,
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _CampoDropdownUsuario(
                    etiqueta: 'Rol',
                    valor: _rolSeleccionado,
                    opciones: const [
                      'JEFE',
                      'EMPLEADO',
                    ],
                    onChanged: (value) {
                      setState(() {
                        _rolSeleccionado = value;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  _CampoEstadoUsuario(
                    activo: _usuarioActivo,
                    onChanged: (value) {
                      setState(() {
                        _usuarioActivo = value;
                      });
                    },
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _rojo,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  const SizedBox(height: 70),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed:
                          widget.guardando ? null : _guardar,
                      icon: widget.guardando
                          ? const SizedBox(
                              width: 13,
                              height: 13,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.save_outlined,
                              color: Colors.white,
                              size: 14,
                            ),
                      label: Text(
                        widget.guardando
                            ? 'Guardando...'
                            : 'Guardar Usuario',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _verdeOscuro,
                        disabledBackgroundColor:
                            _verdeOscuro.withValues(
                          alpha: 0.55,
                        ),
                        elevation: 4,
                        shadowColor:
                            _verdeOscuro.withValues(
                          alpha: 0.25,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _guardar() {
    final nombre = _nombreController.text.trim();
    final username = _usuarioController.text.trim();
    final telefono = _telefonoController.text.trim();
    final password = _passwordController.text;
    final rol = _rolSeleccionado;

    if (nombre.isEmpty ||
        username.isEmpty ||
        (!_editando && password.isEmpty) ||
        rol == null) {
      setState(() {
        _error =
            'Nombre, usuario, contrasena y rol son obligatorios';
      });
      return;
    }

    if (password.isNotEmpty && password.length < 4) {
      setState(() {
        _error =
            'La contrasena debe tener al menos 4 caracteres';
      });
      return;
    }

    setState(() {
      _error = null;
    });

    widget.onGuardarUsuario(
      DatosFormularioUsuario(
        nombre: nombre,
        username: username,
        telefono: telefono,
        password: password,
        rol: rol,
        activo: _usuarioActivo,
      ),
    );
  }
}

class _EncabezadoNuevoUsuario extends StatelessWidget {
  final VoidCallback onCerrar;
  final bool editando;

  const _EncabezadoNuevoUsuario({
    required this.onCerrar,
    required this.editando,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          editando
              ? Icons.edit_outlined
              : Icons.person_add_alt_1,
          color: _verdeOscuro,
          size: 17,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            editando ? 'Editar Usuario' : 'Nuevo Usuario',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textoPrincipal,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        IconButton(
          onPressed: onCerrar,
          icon: const Icon(
            Icons.close,
            color: _textoSecundario,
            size: 18,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 28,
            minHeight: 28,
          ),
        ),
      ],
    );
  }
}

class _CampoTextoUsuario extends StatelessWidget {
  final String etiqueta;
  final TextEditingController controller;
  final String hintText;
  final Widget? suffixWidget;
  final bool obscureText;
  final TextInputType? keyboardType;

  const _CampoTextoUsuario({
    required this.etiqueta,
    required this.controller,
    required this.hintText,
    this.suffixWidget,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return _ContenedorCampoUsuario(
      etiqueta: etiqueta,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        cursorColor: _verdeOscuro,
        style: const TextStyle(
          color: _textoPrincipal,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        decoration: _decoracionCampo(
          hintText: hintText,
          suffixWidget: suffixWidget,
        ),
      ),
    );
  }
}

class _CampoDropdownUsuario extends StatelessWidget {
  final String etiqueta;
  final String? valor;
  final List<String> opciones;
  final ValueChanged<String?> onChanged;

  const _CampoDropdownUsuario({
    required this.etiqueta,
    required this.valor,
    required this.opciones,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _ContenedorCampoUsuario(
      etiqueta: etiqueta,
      child: DropdownButtonFormField<String>(
        initialValue: valor,
        isExpanded: true,
        icon: const Icon(
          Icons.keyboard_arrow_down,
          color: _textoSecundario,
          size: 18,
        ),
        hint: const Text(
          'Seleccione un rol...',
          style: TextStyle(
            color: _textoSecundario,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: const TextStyle(
          color: _textoPrincipal,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        decoration: _decoracionCampo(),
        items: opciones.map((opcion) {
          return DropdownMenuItem<String>(
            value: opcion,
            child: Text(opcion),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _CampoEstadoUsuario extends StatelessWidget {
  final bool activo;
  final ValueChanged<bool> onChanged;

  const _CampoEstadoUsuario({
    required this.activo,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _ContenedorCampoUsuario(
      etiqueta: 'Estado',
      child: Container(
        padding: const EdgeInsets.only(
          left: 12,
          right: 6,
          top: 3,
          bottom: 3,
        ),
        decoration: BoxDecoration(
          color: _grisCampo,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                activo ? 'Activo' : 'Inactivo',
                style: const TextStyle(
                  color: _textoPrincipal,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Transform.scale(
              scale: 0.82,
              child: Switch(
                value: activo,
                onChanged: onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: _verdeOscuro,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor:
                    const Color(0xFFC9C9C9),
                materialTapTargetSize:
                    MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContenedorCampoUsuario extends StatelessWidget {
  final String etiqueta;
  final Widget child;

  const _ContenedorCampoUsuario({
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
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

InputDecoration _decoracionCampo({
  String? hintText,
  Widget? suffixWidget,
}) {
  return InputDecoration(
    filled: true,
    fillColor: _grisCampo,
    hintText: hintText,
    hintStyle: const TextStyle(
      color: _textoSecundario,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    ),
    suffixIcon: suffixWidget,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 11,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(
        color: Color(0xFFE0E0E0),
        width: 1,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(
        color: Color(0xFFE0E0E0),
        width: 1,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(
        color: _verdeOscuro,
        width: 1.2,
      ),
    ),
  );
}