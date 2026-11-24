import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../models/social.dart';

class WaromSession {
  final String token;
  final Map<String, dynamic> user;

  const WaromSession({required this.token, required this.user});

  String get id => '${user['id']}';
  String get username => '${user['username'] ?? ''}';
  String? get email => user['email'] as String?;
  bool get onboardingCompleted =>
      user['onboarding_completed'] == true ||
      user['onboarding_completed'] == 1 ||
      user['onboarding_completed'] == 'true' ||
      user['onboarding_completed'] == '1';
}

class WaromAuth {
  WaromAuth._();
  static final instance = WaromAuth._();

  static const _tokenKey = 'warom_chatter_token';
  static const _userKey = 'warom_chatter_user';

  String? _token;
  Map<String, dynamic>? _user;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isSignedIn => _token != null && _user != null;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final raw = prefs.getString(_userKey);
    if (token != null && raw != null) {
      try {
        _token = token;
        _user = jsonDecode(raw) as Map<String, dynamic>;
        return;
      } catch (_) {
        // Fall through — keep any in-memory session from this run.
      }
    }
    // Never wipe a live in-memory session just because prefs are empty
    // (hot reload / race during onboarding was causing "Session expired").
  }

  /// Refresh the cached user from GET /api/auth/me (source of truth for onboarding_completed).
  Future<WaromSession> refreshMe() async {
    await restore();
    if (_token == null) {
      throw const ApiException('Session expired. Please log in again.');
    }
    http.Response response;
    try {
      response = await http
          .get(
            Uri.parse('$kWaromApiBase/api/auth/me'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $_token',
            },
          )
          .timeout(const Duration(seconds: 20));
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
      throw ApiException(payload['message']?.toString() ?? 'Could not load profile.');
    }

    final data = payload['data'];
    final user = data is Map<String, dynamic>
        ? data
        : (data is Map ? Map<String, dynamic>.from(data) : null);
    if (user == null) throw const ApiException('Unexpected response from server.');

    _user = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
    return WaromSession(token: _token!, user: user);
  }

  Future<WaromSession> register({
    required String email,
    required String password,
    required String username,
    String? dateOfBirth,
    String? gender,
    String? country,
    String? city,
    String? bio,
    List<String>? hobbies,
  }) async {
    final data = await _post('/api/auth/register', {
      'account_type': kChatterAccountType,
      'auth_provider': 'email',
      'email': email.trim().toLowerCase(),
      'password': password,
      'username': username.trim(),
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      if (gender != null) 'gender': gender,
      if (country != null) 'country': country,
      if (city != null) 'city': city,
      if (bio != null) 'bio': bio,
      if (hobbies != null) 'hobbies': hobbies,
    });
    return _persist(data);
  }

  Future<WaromSession> login({
    required String email,
    required String password,
  }) async {
    final data = await _post('/api/auth/login', {
      'account_type': kChatterAccountType,
      'email': email.trim().toLowerCase(),
      'password': password,
    });
    return _persist(data);
  }

  Future<WaromSession> registerWithProvider({
    required String provider,
    required String providerId,
    required String email,
    required String username,
  }) async {
    final data = await _post('/api/auth/register', {
      'account_type': kChatterAccountType,
      'auth_provider': provider,
      'email': email.trim().toLowerCase(),
      'username': username.trim(),
      if (provider == 'google') 'google_id': providerId,
      if (provider == 'apple') 'apple_id': providerId,
    });
    return _persist(data);
  }

  Future<WaromSession?> loginExistingProviderEmail(String email) async {
    // Provider accounts have no password — try /me after we already registered.
    // For returning provider users we look up by attempting register which may fail on unique email.
    // Fallback: call login is not possible without password. Store sessions locally after first register.
    await restore();
    if (isSignedIn && (_user?['email'] as String?)?.toLowerCase() == email.toLowerCase()) {
      return WaromSession(token: _token!, user: _user!);
    }
    return null;
  }

  Future<void> clear() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  /// Merge server profile fields into the cached session user (e.g. after onboarding).
  Future<void> mergeUser(Map<String, dynamic> patch) async {
    if (_user == null) return;
    _user = {..._user!, ...patch};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(_user));
  }

  Future<WaromSession> _persist(Map<String, dynamic> data) async {
    final token = data['token'] as String?;
    final user = data['user'] as Map<String, dynamic>?;
    if (token == null || user == null) {
      throw const ApiException('Unexpected response from server.');
    }
    _token = token;
    _user = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user));
    return WaromSession(token: token, user: user);
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$kWaromApiBase$path'),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
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

    final data = payload['data'];
    if (data is Map<String, dynamic>) return data;
    throw const ApiException('Unexpected response from server.');
  }
}
