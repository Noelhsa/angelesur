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
    final prefs = await SharedPreferences.getInstance();
    final idUsuario = prefs.getInt(_keyIdUsuario);
    final nombre = prefs.getString(_keyNombre);
    final username = prefs.getString(_keyUsername);
    final rol = prefs.getString(_keyRol);

    if (idUsuario == null ||
        nombre == null ||
        username == null ||
        rol == null) {
      return null;
    }

    return Usuario(
      id: idUsuario,
      nombre: nombre,
      username: username,
      telefono: prefs.getString(_keyTelefono),
      rol: rol,
      activo: prefs.getBool(_keyActivo) ?? true,
    );
  }

  Future<void> guardarUsuario(Usuario usuario) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyIdUsuario, usuario.id);
    await prefs.setString(_keyNombre, usuario.nombre);
    await prefs.setString(_keyUsername, usuario.username);
    await prefs.setString(_keyRol, usuario.rol);
    await prefs.setBool(_keyActivo, usuario.activo);

    if (usuario.telefono == null || usuario.telefono!.isEmpty) {
      await prefs.remove(_keyTelefono);
    } else {
      await prefs.setString(_keyTelefono, usuario.telefono!);
    }
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
