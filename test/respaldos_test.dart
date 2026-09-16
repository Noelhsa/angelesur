import 'package:angelesur/models/permisos_usuario.dart';
import 'package:angelesur/models/usuario.dart';
import 'package:angelesur/ui/interfaces/contenido_respaldos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const jefe = Usuario(
      id: 1,
      nombre: 'Administrador',
      username: 'admin',
      rol: 'JEFE',
      activo: true);
  const empleado = Usuario(
      id: 2,
      nombre: 'Empleado',
      username: 'empleado',
      rol: 'EMPLEADO',
      activo: true);

  test('Respaldos solo aparece en los menus del jefe', () {
    expect(const PermisosUsuario(jefe).puedeVerMenu(9), isTrue);
    expect(const PermisosUsuario(empleado).puedeVerMenu(9), isFalse);
  });

  testWidgets('La pantalla muestra ambas acciones sin desbordamientos',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ContenidoRespaldos(
      usuario: jefe,
      onRestaurado: () {},
      onOcupado: (_) {},
    ))));
    expect(find.text('Crear respaldo'), findsOneWidget);
    expect(find.text('Cargar respaldo'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(const Size(360, 640));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
  });
}
