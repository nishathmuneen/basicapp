import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/health_models.dart';
import '../utils/date_formatters.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class AuthExpiredException extends ApiException {
  AuthExpiredException(super.message) : super(statusCode: 401);
}

class HealthApiClient {
  HealthApiClient({
    http.Client? httpClient,
    String? initialBaseUrl,
  })  : _httpClient = httpClient ?? http.Client(),
        _baseUrl = _normalizeBaseUrl(initialBaseUrl ?? defaultBaseUrl());

  static const _tokenPrefKey = 'mht_access_token';
  static const _serverPrefKey = 'mht_server_url';

  final http.Client _httpClient;
  String _baseUrl;
  String? _accessToken;

  String get baseUrl => _baseUrl;
  bool get hasToken => _accessToken != null && _accessToken!.isNotEmpty;

  static String defaultBaseUrl() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  static String _normalizeBaseUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  Future<void> initFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_serverPrefKey);
    if (savedUrl != null && savedUrl.trim().isNotEmpty) {
      _baseUrl = _normalizeBaseUrl(savedUrl);
    }
    _accessToken = prefs.getString(_tokenPrefKey);
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = _normalizeBaseUrl(url);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverPrefKey, _baseUrl);
  }

  Future<void> _saveToken(String? token) async {
    _accessToken = token;
    final prefs = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await prefs.remove(_tokenPrefKey);
    } else {
      await prefs.setString(_tokenPrefKey, token);
    }
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Object? body,
    bool includeAuth = true,
  }) async {
    final uri = Uri.parse('$_baseUrl/api$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (includeAuth && _accessToken != null && _accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    late http.Response response;
    final encodedBody = body != null ? jsonEncode(body) : null;

    switch (method) {
      case 'GET':
        response = await _httpClient.get(uri, headers: headers);
      case 'POST':
        response = await _httpClient.post(uri, headers: headers, body: encodedBody);
      case 'PUT':
        response = await _httpClient.put(uri, headers: headers, body: encodedBody);
      case 'DELETE':
        response = await _httpClient.delete(uri, headers: headers);
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }

    if (response.statusCode == 204) {
      return null;
    }

    dynamic parsed;
    if (response.body.isNotEmpty) {
      try {
        parsed = jsonDecode(response.body);
      } catch (_) {
        parsed = null;
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Unable to connect to My Health Tracker server.';
      if (parsed is Map<String, dynamic>) {
        final detail = parsed['detail'];
        if (detail is String && detail.isNotEmpty) {
          message = detail;
        } else if (detail is List) {
          message = detail
              .map((item) => item is Map ? item['msg']?.toString() ?? '' : '')
              .where((item) => item.isNotEmpty)
              .join(' ');
        }
      }
      if (response.statusCode == 401) {
        if (includeAuth) {
          await _saveToken(null);
        }
        throw AuthExpiredException(message);
      }
      throw ApiException(message, statusCode: response.statusCode);
    }

    return parsed;
  }

  Future<AuthSession> getSession() async {
    final json = await _request('GET', '/auth/session') as Map<String, dynamic>;
    final session = AuthSession.fromJson(json);
    if (!session.authenticated) {
      await _saveToken(null);
    }
    return session;
  }

  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final json = await _request(
      'POST',
      '/auth/login',
      includeAuth: false,
      body: {'username': username, 'password': password},
    ) as Map<String, dynamic>;
    final session = AuthSession.fromJson(json);
    await _saveToken(session.accessToken);
    return session;
  }

  Future<void> logout() async {
    try {
      await _request('POST', '/auth/logout');
    } finally {
      await _saveToken(null);
    }
  }

  Future<AuthSession> updateCredentials({
    required String currentPassword,
    required String username,
    required String displayName,
    String? newPassword,
  }) async {
    final json = await _request(
      'PUT',
      '/auth/credentials',
      body: {
        'current_password': currentPassword,
        'username': username,
        'display_name': displayName,
        'new_password': newPassword?.isNotEmpty == true ? newPassword : null,
      },
    ) as Map<String, dynamic>;
    return AuthSession.fromJson(json);
  }

  Future<DashboardData> getDashboard({DateTime? now}) async {
    final localNow = Uri.encodeQueryComponent(toApiDateTimeString(now ?? DateTime.now()));
    final json = await _request('GET', '/dashboard?local_now=$localNow') as Map<String, dynamic>;
    return DashboardData.fromJson(json);
  }

  Future<List<HealthReading>> getReadings({
    String period = 'weekly',
    String category = 'all',
    DateTime? referenceDate,
  }) async {
    final refDate = Uri.encodeQueryComponent(toApiDateString(referenceDate ?? DateTime.now()));
    final json = await _request(
      'GET',
      '/readings?period=$period&category=$category&reference_date=$refDate',
    ) as List<dynamic>;
    return json
        .map((item) => HealthReading.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<HealthReading> createGlucoseReading({
    required double glucoseValue,
    required String glucoseType,
    required DateTime recordedAt,
  }) async {
    final json = await _request(
      'POST',
      '/readings/glucose',
      body: {
        'glucose_value': glucoseValue,
        'glucose_type': glucoseType,
        'recorded_at': toApiDateTimeString(recordedAt),
      },
    ) as Map<String, dynamic>;
    return HealthReading.fromJson(json);
  }

  Future<HealthReading> createBPReading({
    required int systolic,
    required int diastolic,
    int? heartRate,
    required DateTime recordedAt,
  }) async {
    final json = await _request(
      'POST',
      '/readings/bp',
      body: {
        'systolic': systolic,
        'diastolic': diastolic,
        'heart_rate': heartRate,
        'recorded_at': toApiDateTimeString(recordedAt),
      },
    ) as Map<String, dynamic>;
    return HealthReading.fromJson(json);
  }

  Future<void> deleteReading(int id) async {
    await _request('DELETE', '/readings/$id');
  }

  Future<ChartsData> getCharts({
    String period = 'weekly',
    DateTime? referenceDate,
  }) async {
    final refDate = Uri.encodeQueryComponent(toApiDateString(referenceDate ?? DateTime.now()));
    final json = await _request(
      'GET',
      '/charts?period=$period&reference_date=$refDate',
    ) as Map<String, dynamic>;
    return ChartsData.fromJson(json);
  }

  Future<ThresholdsModel> updateThresholds(ThresholdsModel thresholds) async {
    final json = await _request(
      'PUT',
      '/thresholds',
      body: thresholds.toJson(),
    ) as Map<String, dynamic>;
    return ThresholdsModel.fromJson(json);
  }

  Future<ThresholdsModel> resetThresholds() async {
    final json = await _request('POST', '/thresholds/reset') as Map<String, dynamic>;
    return ThresholdsModel.fromJson(json);
  }

  Future<List<ReminderItem>> getReminders() async {
    final json = await _request('GET', '/reminders') as List<dynamic>;
    return json
        .map((item) => ReminderItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ReminderItem> updateReminder({
    required String key,
    required String timeOfDay,
    required bool enabled,
    required String note,
  }) async {
    final json = await _request(
      'PUT',
      '/reminders/$key',
      body: {
        'time_of_day': timeOfDay,
        'enabled': enabled,
        'note': note,
      },
    ) as Map<String, dynamic>;
    return ReminderItem.fromJson(json);
  }
}

