import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/social.dart';
import 'warom_auth.dart';

/// Shared HTTP helper for authenticated WAROM calls.
class WaromClient {
  WaromClient._();
  static final instance = WaromClient._();

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$kWaromApiBase$path').replace(queryParameters: query);
    return _send(() => http.get(uri, headers: _headers()));
  }

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) async {
    return _send(
      () => http.post(
        Uri.parse('$kWaromApiBase$path'),
        headers: _headers(json: true),
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Future<dynamic> patch(String path, [Map<String, dynamic>? body]) async {
    return _send(
      () => http.patch(
        Uri.parse('$kWaromApiBase$path'),
        headers: _headers(json: true),
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Future<dynamic> delete(String path, [Map<String, dynamic>? body]) async {
    return _send(
      () => http.delete(
        Uri.parse('$kWaromApiBase$path'),
        headers: _headers(json: true),
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Map<String, String> _headers({bool json = false}) {
    final token = WaromAuth.instance.token;
    return {
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> _send(Future<http.Response> Function() call) async {
    http.Response response;
    try {
      response = await call().timeout(const Duration(seconds: 25));
    } catch (_) {
      throw const ApiException(
        'Could not reach WAROM. Check that the API is running and WAROM_API_BASE is correct.',
      );
    }

    Map<String, dynamic>? payload;
    try {
      payload = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Server error (${response.statusCode}).');
    }

    if (response.statusCode >= 400 || payload['success'] == false) {
      throw ApiException(payload['message']?.toString() ?? 'Request failed.');
    }
    return payload['data'];
  }
}
