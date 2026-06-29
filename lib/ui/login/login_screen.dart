import 'package:flutter/material.dart';

import '../../models/usuario.dart';
import '../../services/api_client.dart';
import '../../services/auth_api_service.dart';

const Color _fondoApp = Color(0xFF181A20);
const Color _verde = Color(0xFF58D000);
const Color _verdeOscuro = Color(0xFF2F6E00);
const Color _texto = Color(0xFF101010);

class LoginScreen extends StatefulWidget {
  final ValueChanged<Usuario> onLogin;

  const LoginScreen({
    super.key,
    required this.onLogin,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthApiService _authApiService = AuthApiService();
  final TextEditingController _usuarioController =
      TextEditingController(text: 'admin');
  final TextEditingController _passwordController =
      TextEditingController(text: '1234');

  bool _cargando = false;
  bool _ocultarPassword = true;
  String? _error;

  @override
  void dispose() {
    _usuarioController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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

  void _mostrarError(String mensaje) {
    if (!mounted) {
      return;
    }

    setState(() {
      _error = mensaje;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondoApp,
      body: Center(
        child: Container(
          width: 390,
          padding: const EdgeInsets.fromLTRB(34, 32, 34, 30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'assets/sistema/logo_principal.png',
                height: 78,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 22),
              const Text(
                'Iniciar sesion',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _texto,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _usuarioController,
                enabled: !_cargando,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Usuario',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                enabled: !_cargando,
                obscureText: _ocultarPassword,
                onSubmitted: (_) => _iniciarSesion(),
                decoration: InputDecoration(
                  labelText: 'Contrasena',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: _cargando
                        ? null
                        : () {
                            setState(() {
                              _ocultarPassword = !_ocultarPassword;
                            });
                          },
                    icon: Icon(
                      _ocultarPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
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
              const SizedBox(height: 22),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: _cargando ? null : _iniciarSesion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _verde,
                    foregroundColor: _verdeOscuro,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  child: _cargando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _verdeOscuro,
                          ),
                        )
                      : const Text(
                          'Entrar',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
