import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Shares the signed-in session with JSON and multipart requests. A failed or
/// interrupted write retains its retry key across app restarts.
class AuthenticatedHttpClient extends http.BaseClient {
  AuthenticatedHttpClient(String baseUrl, {http.Client? inner})
    : _api = Uri.parse(baseUrl),
      _inner = inner ?? http.Client();
  final Uri _api;
  final http.Client _inner;
  final Map<String, Future<String>> _pendingKeys = {};

  Future<String> _retryKey(SharedPreferences prefs, String storageKey) async {
    final existing = prefs.getString(storageKey);
    if (existing != null) return existing;
    final random = Random.secure();
    final key = List.generate(
      24,
      (_) => random.nextInt(256),
    ).map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    if (!await prefs.setString(storageKey, key)) {
      throw http.ClientException(
        'Unable to save retry state. Request was not sent.',
      );
    }
    return key;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_session_token');
    final ownApi =
        request.url.origin == _api.origin &&
        request.url.path.startsWith('${_api.path}/');
    if (ownApi && token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    final path = request.url.path;
    final retryable =
        ownApi &&
        request.method == 'POST' &&
        (path.endsWith('/orders') ||
            RegExp(r'/orders/[^/]+/payment$').hasMatch(path));
    String? storageKey;
    try {
      if (retryable) {
        dynamic payload;
        if (request is http.Request) {
          payload = json.decode(request.body);
          if (payload is Map) payload.remove('orderNumber');
        } else if (request is http.MultipartRequest) {
          payload = request.fields;
        }
        final identity =
            '${prefs.getString('user_json')}|${request.url}|${json.encode(payload)}';
        final pendingKey =
            'pending_write_${sha256.convert(utf8.encode(identity))}';
        storageKey = pendingKey;
        // Concurrent equivalent requests share the persisted key.
        request.headers['Idempotency-Key'] = await _pendingKeys.putIfAbsent(
          pendingKey,
          () => _retryKey(prefs, pendingKey),
        );
      }
      final response = await _inner
          .send(request)
          .timeout(const Duration(seconds: 60));
      // Read the complete response before retiring a key: a stream failure is
      // still an uncertain result and must be retried with the original key.
      final bytes = await response.stream.toBytes().timeout(
        const Duration(seconds: 60),
      );
      if (storageKey != null &&
          response.statusCode >= 200 &&
          response.statusCode < 300) {
        // An invalid/truncated success body is still an uncertain result.
        dynamic result;
        try {
          result = json.decode(utf8.decode(bytes));
        } catch (_) {}
        if (result is Map && result['success'] == true) {
          await prefs.remove(storageKey);
        }
      }
      return http.StreamedResponse(
        Stream.value(bytes),
        response.statusCode,
        headers: response.headers,
        request: response.request,
        reasonPhrase: response.reasonPhrase,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
      );
    } finally {
      if (storageKey != null) _pendingKeys.remove(storageKey);
    }
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
