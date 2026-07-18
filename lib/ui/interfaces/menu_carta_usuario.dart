import 'package:flutter/material.dart';

import '../../models/usuario.dart';

const Color _fondoPagina = Color(0xFFF8F6F5);
const Color _verdeOscuro = Color(0xFF397800);
const Color _textoPrincipal = Color(0xFF101828);
const Color _textoSecundario = Color(0xFF667085);
const Color _bordeSuave = Color(0xFFD9E6D3);
const Color _grisCampo = Color(0xFFF6F4F1);

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
  State<MenuCartaUsuario> createState() => _MenuCartaUsuarioState();
}

class _MenuCartaUsuarioState extends State<MenuCartaUsuario> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
      width: 430,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: _fondoPagina,
        border: Border(
          left: BorderSide(
            color: _bordeSuave,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _EncabezadoNuevoUsuario(
            editando: _editando,
            onCerrar: widget.onCerrar,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _bordeSuave),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CampoTextoUsuario(
                      etiqueta: 'Nombre Completo',
                      controller: _nombreController,
                      hintText: 'Ej: Juan Pérez',
                      suffixIcon: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    _CampoTextoUsuario(
                      etiqueta: 'Nombre de Usuario',
                      controller: _usuarioController,
                      hintText: 'jperez_pharmacy',
                      suffixIcon: Icons.alternate_email,
                    ),
                    const SizedBox(height: 16),
                    _CampoTextoUsuario(
                      etiqueta: 'Teléfono',
                      controller: _telefonoController,
                      hintText: '+52 555 123 4567',
                      suffixIcon: Icons.phone_outlined,
                    ),
                    const SizedBox(height: 16),
                    _CampoTextoUsuario(
                      etiqueta: _editando
                          ? 'Nueva contrasena (opcional)'
                          : 'Contrasena',
                      controller: _passwordController,
                      hintText: '••••••••',
                      obscureText: !_passwordVisible,
                      suffixWidget: IconButton(
                        onPressed: () {
                          setState(() {
                            _passwordVisible = !_passwordVisible;
                          });
                        },
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: _textoSecundario,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 24),
                    _CampoEstadoUsuario(
                      activo: _usuarioActivo,
                      onChanged: (value) {
                        setState(() {
                          _usuarioActivo = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    const _AreaAvatarUsuario(),
                    const SizedBox(height: 18),
                    const Divider(color: _bordeSuave),
                    const SizedBox(height: 14),
                    _AccionesNuevoUsuario(
                      onCancelar: widget.onCerrar,
                      onGuardar: _guardar,
                      guardando: widget.guardando,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFE02020),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
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
        _error = 'Nombre, usuario, contrasena y rol son obligatorios';
      });
      return;
    }

    if (password.isNotEmpty && password.length < 4) {
      setState(() {
        _error = 'La contrasena debe tener al menos 4 caracteres';
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
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: _fondoPagina,
        border: Border(
          bottom: BorderSide(
            color: _bordeSuave,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onCerrar,
            icon: const Icon(
              Icons.arrow_back,
              color: _textoPrincipal,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 30,
              minHeight: 30,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  editando ? 'Editar Usuario' : 'Añadir Nuevo Usuario',
                  style: const TextStyle(
                    color: _textoPrincipal,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  editando
                      ? 'Actualiza datos, rol y acceso del usuario.'
                      : 'Gestione los permisos y el acceso de su personal clínico.',
                  style: const TextStyle(
                    color: Color(0xFF214025),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
              minWidth: 30,
              minHeight: 30,
            ),
          ),
        ],
      ),
    );
  }
}

class _CampoTextoUsuario extends StatelessWidget {
  final String etiqueta;
  final TextEditingController controller;
  final String hintText;
  final IconData? suffixIcon;
  final Widget? suffixWidget;
  final bool obscureText;

  const _CampoTextoUsuario({
    required this.etiqueta,
    required this.controller,
    required this.hintText,
    this.suffixIcon,
    this.suffixWidget,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return _ContenedorCampoUsuario(
      etiqueta: etiqueta,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        cursorColor: _verdeOscuro,
        style: const TextStyle(
          color: _textoPrincipal,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        decoration: _decoracionCampo(
          hintText: hintText,
          suffixIcon: suffixIcon,
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
        value: valor,
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
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: const TextStyle(
          color: _textoPrincipal,
          fontSize: 12,
          fontWeight: FontWeight.w600,
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
        height: 38,
        padding: const EdgeInsets.only(left: 12, right: 6),
        decoration: BoxDecoration(
          color: _grisCampo,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _bordeSuave),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                activo ? 'Activo' : 'Inactivo',
                style: const TextStyle(
                  color: _textoPrincipal,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Switch(
              value: activo,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: _verdeOscuro,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFC9C9C9),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}

class _AreaAvatarUsuario extends StatelessWidget {
  const _AreaAvatarUsuario();

  @override
  Widget build(BuildContext context) {
    return _ContenedorCampoUsuario(
      etiqueta: 'Avatar de Usuario',
      child: Container(
        height: 130,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _grisCampo,
          borderRadius: BorderRadius.circular(8),
        ),
        child: CustomPaint(
          painter: _DashedBorderPainter(),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Color(0xFFC8F2DD),
                  child: Icon(
                    Icons.add_a_photo_outlined,
                    color: _verdeOscuro,
                    size: 25,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'Haz clic o arrastra la imagen del usuario aquí',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _textoPrincipal,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'JPG, PNG HASTA 5MB',
                  style: TextStyle(
                    color: _textoSecundario,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccionesNuevoUsuario extends StatelessWidget {
  final VoidCallback onCancelar;
  final VoidCallback onGuardar;
  final bool guardando;

  const _AccionesNuevoUsuario({
    required this.onCancelar,
    required this.onGuardar,
    required this.guardando,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: 92,
          height: 36,
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
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 145,
          height: 36,
          child: ElevatedButton.icon(
            onPressed: guardando ? null : onGuardar,
            icon: guardando
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
              guardando ? 'Guardando...' : 'Guardar Usuario',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _verdeOscuro,
              elevation: 4,
              shadowColor: _verdeOscuro.withOpacity(0.25),
              padding: EdgeInsets.zero,
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
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

InputDecoration _decoracionCampo({
  String? hintText,
  IconData? suffixIcon,
  Widget? suffixWidget,
}) {
  return InputDecoration(
    filled: true,
    fillColor: _grisCampo,
    hintText: hintText,
    hintStyle: const TextStyle(
      color: _textoSecundario,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    suffixIcon: suffixWidget ??
        (suffixIcon == null
            ? null
            : Icon(
                suffixIcon,
                color: _textoSecundario,
                size: 17,
              )),
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

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const double dashWidth = 6;
    const double dashSpace = 5;

    final paint = Paint()
      ..color = const Color(0xFFC8D6C0)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(8),
    );

    final path = Path()..addRRect(rect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final nextDistance = distance + dashWidth;
        final extractPath = metric.extractPath(distance, nextDistance);
        canvas.drawPath(extractPath, paint);
        distance = nextDistance + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
