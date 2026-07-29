import 'usuario.dart';

class PermisosUsuario {
  final Usuario usuario;

  const PermisosUsuario(this.usuario);

  bool get esJefe => usuario.rol.trim().toUpperCase() == 'JEFE';

  bool get esEmpleado => usuario.rol.trim().toUpperCase() == 'EMPLEADO';

  bool get puedeGestionarUsuarios => esJefe;

  bool get puedeVerPedidos => esJefe;

  bool get puedeVerProveedores => esJefe;

  bool get puedeVerDevoluciones => esJefe;

  bool get puedeVerYastas => esJefe;

  bool get puedeEditarCatalogo => esJefe;

  Set<int> get menusPermitidos {
    return {
      if (puedeGestionarUsuarios) 0,
      1,
      2,
      if (puedeVerPedidos) 3,
      4,
      5,
      if (puedeVerProveedores) 6,
      if (puedeVerDevoluciones) 7,
      if (puedeVerYastas) 8,
    };
  }

  bool puedeVerMenu(int indice) {
    return menusPermitidos.contains(indice);
  }
}
