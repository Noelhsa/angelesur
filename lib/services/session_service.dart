import 'package:shared_preferences/shared_preferences.dart';

import '../models/usuario.dart';

class SessionService {
  static const String _keyIdUsuario = 'session.idUsuario';
  static const String _keyNombre = 'session.nombre';
  static const String _keyUsername = 'session.username';
  static const String _keyTelefono = 'session.telefono';
  static const String _keyRol = 'session.rol';
  static const String _keyActivo = 'session.activo';

  Future<Usuario?> cargarUsuario() async {
    await cerrarSesion();
    return null;
  }

  Future<void> guardarUsuario(Usuario usuario) async {
    await cerrarSesion();
  }

  Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIdUsuario);
    await prefs.remove(_keyNombre);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyTelefono);
    await prefs.remove(_keyRol);
    await prefs.remove(_keyActivo);
  }
}
