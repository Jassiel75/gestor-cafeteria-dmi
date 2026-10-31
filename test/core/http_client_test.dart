import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_cafeteria/core/failure.dart';
import 'package:gestor_cafeteria/core/http_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

ApiClient crearCliente(
  MockClient mock, {
  Duration timeout = const Duration(seconds: 10),
}) {
  return ApiClient(client: mock, baseUrl: 'http://prueba', timeout: timeout);
}

http.Response respuestaJson(Object cuerpo, int codigo) {
  return http.Response(jsonEncode(cuerpo), codigo);
}

void main() {
  test('GET exitoso devuelve el JSON decodificado', () async {
    final mock = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.toString(), 'http://prueba/orders');
      return respuestaJson([
        {'id': 1, 'customer': 'Ana'},
      ], 200);
    });
    final api = crearCliente(mock);

    final resultado = await api.get('/orders');

    expect(resultado, [
      {'id': 1, 'customer': 'Ana'},
    ]);
  });

  test('404 lanza NotFoundFailure con el mensaje del servidor', () async {
    final mock = MockClient((request) async {
      return respuestaJson({'detail': 'Order 9 not found'}, 404);
    });
    final api = crearCliente(mock);

    await expectLater(
      api.get('/orders/9'),
      throwsA(
        isA<NotFoundFailure>().having(
          (f) => f.message,
          'message',
          'Order 9 not found',
        ),
      ),
    );
  });

  test('409 lanza ConflictFailure con el mensaje del servidor', () async {
    final mock = MockClient((request) async {
      return respuestaJson({
        'detail': 'Cannot change status from pending to delivered',
      }, 409);
    });
    final api = crearCliente(mock);

    await expectLater(
      api.patch('/orders/1', {'status': 'delivered'}),
      throwsA(
        isA<ConflictFailure>().having(
          (f) => f.message,
          'message',
          'Cannot change status from pending to delivered',
        ),
      ),
    );
  });

  test('422 lanza ValidationFailure con los campos y sus mensajes', () async {
    final mock = MockClient((request) async {
      return respuestaJson({
        'detail': [
          {
            'loc': ['body', 'customer'],
            'msg': 'Must be 1-50 characters',
          },
        ],
      }, 422);
    });
    final api = crearCliente(mock);

    await expectLater(
      api.post('/orders', {'customer': '', 'drink': 'latte', 'size': 'M'}),
      throwsA(
        isA<ValidationFailure>().having((f) => f.fields, 'fields', {
          'customer': 'Must be 1-50 characters',
        }),
      ),
    );
  });

  test('503 lanza ServerFailure con statusCode 503', () async {
    final mock = MockClient((request) async {
      return respuestaJson({'detail': 'Service Unavailable'}, 503);
    });
    final api = crearCliente(mock);

    await expectLater(
      api.get('/orders'),
      throwsA(
        isA<ServerFailure>().having((f) => f.statusCode, 'statusCode', 503),
      ),
    );
  });

  test('sin conexión lanza NetworkFailure', () async {
    final mock = MockClient((request) async {
      throw http.ClientException('sin red');
    });
    final api = crearCliente(mock);

    await expectLater(api.get('/orders'), throwsA(isA<NetworkFailure>()));
  });

  test('tiempo agotado lanza NetworkFailure', () async {
    final mock = MockClient((request) async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return respuestaJson([], 200);
    });
    final api = crearCliente(mock, timeout: const Duration(milliseconds: 50));

    await expectLater(api.get('/orders'), throwsA(isA<NetworkFailure>()));
  });
}
