import 'package:flutter/material.dart';

import '../../models/usuario.dart';

/// =====================================================================
/// EditarPerfilScreen
/// Pantalla de edición de perfil de usuario para el POS de farmacia.
/// Basada en el diseño: tarjeta de identidad (izquierda) + formulario
/// de datos y preferencias (derecha).
/// =====================================================================
class EditarPerfilScreen extends StatefulWidget {
  final Usuario usuario;

  const EditarPerfilScreen({
    super.key,
    required this.usuario,
  });

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  // ---- Controladores de los campos ----
  late final TextEditingController _nombreController;
  late final TextEditingController _correoController;
  final _passwordController = TextEditingController(text: '********');

  bool _passwordVisible = false;
  bool _notificacionesPush = true;
  bool _modoOscuroAutomatico = false;

  // ---- Colores base del diseño ----
  static const Color _verdePrincipal = Color(0xFF2E7D32);
  static const Color _verdeClaroFondo = Color(0xFFE8F5E9);
  static const Color _grisFondoPagina = Color(0xFFE9E9EB);
  static const Color _grisTextoSecundario = Color(0xFF6B7280);
  static const Color _bordeCampo = Color(0xFFE2E2E6);
  static const Color _azulSeguridadFondo = Color(0xFFEFF3FB);
  static const Color _azulSeguridadTexto = Color(0xFF3B5BA9);

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.usuario.nombre);
    _correoController = TextEditingController(text: widget.usuario.username);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _grisFondoPagina,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 28),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 800;
                    final tarjetaIdentidad = _buildTarjetaIdentidad();
                    final tarjetaFormulario = _buildTarjetaFormulario();

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 4, child: tarjetaIdentidad),
                          const SizedBox(width: 24),
                          Expanded(flex: 6, child: tarjetaFormulario),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        tarjetaIdentidad,
                        const SizedBox(height: 24),
                        tarjetaFormulario,
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // ENCABEZADO
  // ---------------------------------------------------------------------
  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Editar Perfil',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2430),
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Actualiza tu información personal y preferencias de la cuenta.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF8A8F98),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // TARJETA IZQUIERDA: IDENTIDAD
  // ---------------------------------------------------------------------
  Widget _buildTarjetaIdentidad() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'COLOR ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: Color(0xFF1F2430),
                ),
              ),
              Text(
                'PALETTE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: _verdePrincipal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 140,
              height: 90,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Círculo negro (avatar)
                  Positioned(
                    left: 14,
                    top: 0,
                    child: _colorCircle(Colors.black, size: 70),
                  ),
                  // Círculo gris claro
                  Positioned(
                    left: 70,
                    top: 6,
                    child: _colorCircle(const Color(0xFFD9D9D9), size: 58),
                  ),
                  // Punto azul decorativo
                  const Positioned(
                    left: 6,
                    top: 30,
                    child: _SmallDot(color: Color(0xFF3B82F6)),
                  ),
                  // Punto verde decorativo
                  const Positioned(
                    right: 6,
                    top: 4,
                    child: _SmallDot(color: Color(0xFF22C55E)),
                  ),
                  // Botón de cámara (cambiar foto)
                  Positioned(
                    right: 24,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () {
                        // TODO: lógica para cambiar foto de perfil
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: _verdePrincipal,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              widget.usuario.nombre,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2430),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _verdePrincipal,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Sesión Activa',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: _verdePrincipal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: _bordeCampo),
          const SizedBox(height: 14),
          _infoRow('ID de Empleado', '#${widget.usuario.id}'),
          const SizedBox(height: 10),
          _infoRow('Rol', widget.usuario.rol),
          const SizedBox(height: 18),
          _buildAvisoSeguridad(),
        ],
      ),
    );
  }

  Widget _colorCircle(Color color, {required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: _azulSeguridadTexto,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF1F2430),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAvisoSeguridad() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _azulSeguridadFondo,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined,
              size: 18, color: _azulSeguridadTexto),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seguridad de la cuenta',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _azulSeguridadTexto,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tu contraseña fue actualizada hace 45 días. '
                  'Recomendamos cambiarla periódicamente.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: _azulSeguridadTexto.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // TARJETA DERECHA: FORMULARIO
  // ---------------------------------------------------------------------
  Widget _buildTarjetaFormulario() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Nombre Completo'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _nombreController,
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 18),
          _fieldLabel('Correo Electrónico'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _correoController,
            icon: Icons.mail_outline,
            borderColor: _verdePrincipal,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Rol del Sistema'),
                    const SizedBox(height: 6),
                    _buildRolDropdownDeshabilitado(),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Contraseña'),
                    const SizedBox(height: 6),
                    _buildPasswordField(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'El rol solo puede ser modificado por un administrador.',
            style: TextStyle(
              fontSize: 12,
              color: _grisTextoSecundario,
            ),
          ),
          const SizedBox(height: 22),
          const Divider(height: 1, color: _bordeCampo),
          const SizedBox(height: 22),
          const Text(
            'Preferencias de Interfaz',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2430),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildPreferenciaToggle(
                  icon: Icons.notifications_none,
                  iconColor: _verdePrincipal,
                  iconBg: _verdeClaroFondo,
                  label: 'Notificaciones\nPush',
                  value: _notificacionesPush,
                  onChanged: (v) => setState(() => _notificacionesPush = v),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPreferenciaToggle(
                  icon: Icons.dark_mode_outlined,
                  iconColor: const Color(0xFF3B82F6),
                  iconBg: const Color(0xFFE9F1FF),
                  label: 'Modo Oscuro\nAutomático',
                  value: _modoOscuroAutomatico,
                  onChanged: (v) => setState(() => _modoOscuroAutomatico = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          const Divider(height: 1, color: _bordeCampo),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () {
                  // TODO: descartar cambios
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _bordeCampo),
                  foregroundColor: const Color(0xFF6B7280),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: guardar cambios del perfil
                },
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('Guardar Cambios'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _verdePrincipal,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1F2430),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    Color borderColor = _bordeCampo,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1F2430)),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 18, color: _grisTextoSecundario),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _bordeCampo),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _bordeCampo),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor, width: 1.4),
        ),
      ),
    );
  }

  Widget _buildRolDropdownDeshabilitado() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _bordeCampo),
      ),
      child: Row(
        children: [
          Icon(Icons.badge_outlined, size: 18, color: _grisTextoSecundario),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.usuario.rol,
              style: TextStyle(
                fontSize: 14,
                color: _grisTextoSecundario,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(Icons.keyboard_arrow_down,
              size: 18, color: _grisTextoSecundario),
        ],
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: !_passwordVisible,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1F2430)),
      decoration: InputDecoration(
        prefixIcon:
            Icon(Icons.lock_outline, size: 18, color: _grisTextoSecundario),
        suffixIcon: IconButton(
          icon: Icon(
            _passwordVisible ? Icons.visibility_off : Icons.visibility,
            size: 18,
            color: _grisTextoSecundario,
          ),
          onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _bordeCampo),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _verdePrincipal, width: 1.4),
        ),
      ),
    );
  }

  Widget _buildPreferenciaToggle({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _bordeCampo),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2430),
                height: 1.2,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: _verdePrincipal,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFD9D9D9),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// WIDGETS AUXILIARES
// ===========================================================================

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SmallDot extends StatelessWidget {
  final Color color;
  const _SmallDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}
