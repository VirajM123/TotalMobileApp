import 'dart:convert';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:totalsolution/services/authenticated_http_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'api_session_token': 'session-one',
      'user_json': '{"salesman_id":"SM1"}',
    });
  });

  test(
    'uncertain order retries keep their key across client restarts',
    () async {
      final keys = <String?>[];
      var fail = true;
      final transport = MockClient((request) async {
        keys.add(request.headers['Idempotency-Key']);
        expect(request.headers['Authorization'], 'Bearer session-one');
        if (fail) throw http.ClientException('Connection lost');
        return http.Response('{"success":true}', 200);
      });
      var client = AuthenticatedHttpClient(
        'https://example.test/api',
        inner: transport,
      );
      final uri = Uri.parse('https://example.test/api/orders');
      Future<http.Response> submit(String number) => client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'orderNumber': number,
          'items': [
            {'quantity': 1},
          ],
        }),
      );
      await expectLater(submit('first'), throwsA(isA<http.ClientException>()));
      fail = false;
      client = AuthenticatedHttpClient(
        'https://example.test/api',
        inner: transport,
      );
      await submit('retry-number');
      expect(keys[0], isNotEmpty);
      expect(keys[1], keys[0]);
      await submit('new-order');
      expect(keys[2], isNot(keys[1]));
    },
  );

  test('session credentials are never attached to another origin', () async {
    final client = AuthenticatedHttpClient(
      'https://example.test/api',
      inner: MockClient((request) async {
        expect(request.headers.containsKey('Authorization'), false);
        return http.Response('{}', 200);
      }),
    );
    await client.get(Uri.parse('https://maps.example.test/api/routes'));
    client.close();
  });

  test('simultaneous copies of one order use the same retry key', () async {
    final keys = <String?>[];
    final bothArrived = Completer<void>();
    final client = AuthenticatedHttpClient(
      'https://example.test/api',
      inner: MockClient((request) async {
        keys.add(request.headers['Idempotency-Key']);
        if (keys.length == 2) bothArrived.complete();
        await bothArrived.future;
        return http.Response('{"success":true}', 200);
      }),
    );
    Future<http.Response> submit() => client.post(
      Uri.parse('https://example.test/api/orders'),
      body: '{"items":[{"quantity":1}]}',
    );
    await Future.wait([submit(), submit()]);
    expect(keys[0], isNotEmpty);
    expect(keys[1], keys[0]);
    client.close();
  });

  test(
    'multipart payment retries reuse the original key after a server failure',
    () async {
      final keys = <String?>[];
      final client = AuthenticatedHttpClient(
        'https://example.test/api',
        inner: MockClient((request) async {
          keys.add(request.headers['Idempotency-Key']);
          return http.Response('{}', keys.length == 1 ? 503 : 200);
        }),
      );
      for (var i = 0; i < 2; i++) {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('https://example.test/api/orders/ORD1/payment'),
        )..fields.addAll({'amount': '100', 'paymentMode': 'cash'});
        await client.send(request);
      }
      expect(keys[0], isNotEmpty);
      expect(keys[1], keys[0]);
      client.close();
    },
  );
}
