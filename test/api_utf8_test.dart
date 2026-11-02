import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:angelesur/services/api_client.dart';

void main() {
  const texto =
      'Vualá, José Muñoz: devolución, pediátrico, pingüino. ¿Sí? ¡Sí!';
  for (final headers in <Map<String, String>>[
    {},
    {'content-type': 'application/json'},
    {'content-type': 'application/json; charset=utf-8'},
  ]) {
    test('Respuesta UTF-8 con encabezados $headers', () async {
      final api = ApiClient(
          client: MockClient((_) async => http.Response.bytes(
                utf8.encode(jsonEncode({'texto': texto})),
                200,
                headers: headers,
              )));
      expect((await api.get('/prueba'))['texto'], texto);
    });
  }
  test('POST y PATCH envian los mismos caracteres Unicode', () async {
    final api = ApiClient(client: MockClient((request) async {
      expect(request.headers['content-type'], contains('charset=utf-8'));
      expect(jsonDecode(utf8.decode(request.bodyBytes))['texto'], texto);
      return http.Response.bytes(
          utf8.encode(jsonEncode({'texto': texto})), 200);
    }));
    expect((await api.post('/prueba', {'texto': texto}))['texto'], texto);
    expect((await api.patch('/prueba', {'texto': texto}))['texto'], texto);
  });
  test('Errores conservan tildes y no ocultan bytes invalidos', () async {
    final api = ApiClient(
        client: MockClient((_) async => http.Response.bytes(
              utf8.encode(jsonEncode({'detail': texto})),
              400,
            )));
    await expectLater(
        api.get('/prueba'),
        throwsA(isA<ApiException>()
            .having((error) => error.message, 'mensaje', texto)));
    final invalida = ApiClient(
        client: MockClient((_) async => http.Response.bytes([255], 200)));
    await expectLater(invalida.get('/prueba'), throwsFormatException);
  });
}
