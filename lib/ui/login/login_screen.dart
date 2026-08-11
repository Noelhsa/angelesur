import 'package:flutter/material.dart';

import '../../models/usuario.dart';
import '../../services/api_client.dart';
import '../../services/auth_api_service.dart';

// ============================================================================
// COLORES
// ============================================================================

const Color _azulPrincipal = Color(0xFF276AC2);
const Color _azulBoton = Color(0xFF2D73D2);
const Color _azulLink = Color(0xFF0755D7);

const Color _fondoCampo = Color(0xFFF5F7FA);

const Color _texto = Color(0xFF171717);
const Color _textoSecundario = Color(0xFF616B7B);
const Color _linea = Color(0xFFE2E5E9);

// ============================================================================
// LOGIN SCREEN
// ============================================================================

class LoginScreen extends StatefulWidget {
  final ValueChanged<Usuario> onLogin;

  const LoginScreen({
    super.key,
    required this.onLogin,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// ============================================================================
// ESTADO
// ============================================================================

class _LoginScreenState extends State<LoginScreen> {
  final AuthApiService _authApiService = AuthApiService();

  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _cargando = false;
  bool _ocultarPassword = true;
  String? _error;

  // ==========================================================================
  // LIBERAR CONTROLADORES
  // ==========================================================================

  @override
  void dispose() {
    _usuarioController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  // ==========================================================================
  // INICIAR SESIÓN
  // ==========================================================================

  Future<void> _iniciarSesion() async {
    final username = _usuarioController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Ingresa usuario y contrasena';
      });

      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final usuario = await _authApiService.login(
        username: username,
        password: password,
      );

      if (!mounted) {
        return;
      }

      widget.onLogin(usuario);
    } on ApiException catch (error) {
      _mostrarError(error.message);
    } catch (_) {
      _mostrarError('No se pudo conectar con la API local');
    }
  }

  // ==========================================================================
  // MOSTRAR ERROR
  // ==========================================================================

  void _mostrarError(String mensaje) {
    if (!mounted) {
      return;
    }

    setState(() {
      _error = mensaje;
      _cargando = false;
    });
  }

  // ==========================================================================
  // FECHA ACTUAL
  // ==========================================================================

  String _obtenerFechaActual() {
    final fecha = DateTime.now();

    const meses = <String>[
      '',
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    return '${fecha.day} de ${meses[fecha.month]}, ${fecha.year}';
  }

  // ==========================================================================
  // INTERFAZ
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final ancho = constraints.maxWidth;

            return Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // ==========================================================
                  // PANEL AZUL IZQUIERDO
                  // ==========================================================

                  SizedBox(
                    width: ancho * 0.36,
                    height: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _azulPrincipal,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 35,
                          vertical: 35,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // ==================================================
                              // BIENVENIDO
                              // ==================================================

                              const Text(
                                'Bienvenido a',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              const SizedBox(height: 30),

                              // ==================================================
                              // LOGO
                              // ==================================================

                              Container(
                                width: 100,
                                height: 100,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(22),
                                  child: Image.asset(
                                    'assets/sistema/isotipo_farmacia.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (
                                      context,
                                      error,
                                      stackTrace,
                                    ) {
                                      return const Icon(
                                        Icons.local_pharmacy_outlined,
                                        color: _azulPrincipal,
                                        size: 45,
                                      );
                                    },
                                  ),
                                ),
                              ),

                              const SizedBox(height: 30),

                              // ==================================================
                              // FARMACIA ANGELES
                              // ==================================================

                              const Text(
                                'FARMACIA ANGELES',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),

                              const SizedBox(height: 13),

                              // ==================================================
                              // FECHA
                              // ==================================================

                              Text(
                                _obtenerFechaActual(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFD3E0F1),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ==========================================================
                  // ESPACIO ENTRE PANELES
                  // ==========================================================

                  const SizedBox(width: 28),

                  // ==========================================================
                  // PANEL DERECHO
                  // ==========================================================

                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 55,
                          vertical: 35,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 455,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ==================================================
                              // TITULO
                              // ==================================================

                              const Text(
                                'Iniciar sesión',
                                style: TextStyle(
                                  color: _texto,
                                  fontSize: 31,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),

                              const SizedBox(height: 34),

                              // ==================================================
                              // USUARIO
                              // ==================================================

                              const Text(
                                'Usuario',
                                style: TextStyle(
                                  color: _texto,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              const SizedBox(height: 8),

                              TextField(
                                controller: _usuarioController,
                                enabled: !_cargando,
                                textInputAction: TextInputAction.next,
                                style: const TextStyle(
                                  color: _texto,
                                  fontSize: 15,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Ingresa tu usuario',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF697488),
                                    fontSize: 15,
                                  ),
                                  filled: true,
                                  fillColor: _fondoCampo,
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 17,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(7),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(7),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(7),
                                    borderSide: const BorderSide(
                                      color: _azulBoton,
                                      width: 1.2,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 22),

                              // ==================================================
                              // CONTRASEÑA
                              // ==================================================

                              const Text(
                                'Contraseña',
                                style: TextStyle(
                                  color: _texto,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              const SizedBox(height: 8),

                              TextField(
                                controller: _passwordController,
                                enabled: !_cargando,
                                obscureText: _ocultarPassword,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) {
                                  if (!_cargando) {
                                    _iniciarSesion();
                                  }
                                },
                                style: const TextStyle(
                                  color: _texto,
                                  fontSize: 15,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Ingresa tu contraseña',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF697488),
                                    fontSize: 15,
                                  ),
                                  filled: true,
                                  fillColor: _fondoCampo,
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 17,
                                  ),
                                  suffixIcon: IconButton(
                                    tooltip: _ocultarPassword
                                        ? 'Mostrar contraseña'
                                        : 'Ocultar contraseña',
                                    onPressed: _cargando
                                        ? null
                                        : () {
                                            setState(() {
                                              _ocultarPassword =
                                                  !_ocultarPassword;
                                            });
                                          },
                                    icon: Icon(
                                      _ocultarPassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 20,
                                      color: _textoSecundario,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(7),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(7),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(7),
                                    borderSide: const BorderSide(
                                      color: _azulBoton,
                                      width: 1.2,
                                    ),
                                  ),
                                ),
                              ),

                              // ==================================================
                              // ERROR
                              // ==================================================

                              if (_error != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFFE21F1F),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],

                              // ==================================================
                              // BOTÓN INGRESAR
                              // ==================================================

                              const SizedBox(height: 48),

                              SizedBox(
                                height: 47,
                                child: ElevatedButton(
                                  onPressed:
                                      _cargando ? null : _iniciarSesion,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _azulBoton,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor:
                                        _azulBoton.withValues(
                                      alpha: 0.65,
                                    ),
                                    disabledForegroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                  ),
                                  child: _cargando
                                      ? const SizedBox(
                                          width: 19,
                                          height: 19,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Ingresar',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 31),

                              // ==================================================
                              // LÍNEA
                              // ==================================================

                              Container(
                                height: 1,
                                color: _linea,
                              ),

                              const SizedBox(height: 5),

                              // ==================================================
                              // RECUPERACIÓN
                              // ==================================================

                              Column(
                                children: [
                                  const Text(
                                    '¿No recuerdas tu contraseña?',
                                    style: TextStyle(
                                      color: _textoSecundario,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),

                                  const SizedBox(height: 1),

                                  TextButton(
                                    onPressed: () {},
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 25),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Contactar al administrador',
                                      style: TextStyle(
                                        color: _azulLink,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}