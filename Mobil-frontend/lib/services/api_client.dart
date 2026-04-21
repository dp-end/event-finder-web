import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../main.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  static Map<String, String> get _headers {
    final token = CampusHubApp.tokenNotifier.value;
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static bool get isAuthenticated => CampusHubApp.tokenNotifier.value?.isNotEmpty == true;

  static String? get currentUserId => CampusHubApp.userNotifier.value?['id']?.toString();

  static String? extractToken(Map<String, dynamic> data) {
    final value = data['jwToken'] ??
        data['JWToken'] ??
        data['jwtToken'] ??
        data['token'] ??
        data['accessToken'];
    final token = value?.toString().trim();
    return token == null || token.isEmpty ? null : token;
  }

  static String userTypeFrom(Map<String, dynamic> data, {String fallback = 'student'}) {
    final direct = data['userType']?.toString().toLowerCase();
    if (direct == 'club' || direct == 'student') return direct!;

    final roles = data['roles'];
    if (roles is List && roles.any((role) => role.toString().toLowerCase() == 'club')) {
      return 'club';
    }

    return fallback;
  }

  static Future<Map<String, dynamic>> refreshCurrentUser() async {
    final profile = await get('/Account/me') as Map<String, dynamic>;
    CampusHubApp.userNotifier.value = {
      ...?CampusHubApp.userNotifier.value,
      ...profile,
      'jwToken': CampusHubApp.tokenNotifier.value,
    };
    CampusHubApp.userTypeNotifier.value = userTypeFrom(profile, fallback: CampusHubApp.userTypeNotifier.value);
    return profile;
  }

  static Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('${AppConstants.apiUrl}$path').replace(
      queryParameters: query == null || query.isEmpty ? null : query,
    );
    final response = await http.get(uri, headers: _headers);
    return _decode(response);
  }

  static Future<dynamic> post(String path, {Object? body}) async {
    final uri = Uri.parse('${AppConstants.apiUrl}$path');
    final response = await http.post(
      uri,
      headers: _headers,
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(response);
  }

  static Future<dynamic> put(String path, {Object? body}) async {
    final uri = Uri.parse('${AppConstants.apiUrl}$path');
    final response = await http.put(
      uri,
      headers: _headers,
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(response);
  }

  static Future<void> delete(String path) async {
    final uri = Uri.parse('${AppConstants.apiUrl}$path');
    final response = await http.delete(uri, headers: _headers);
    _decode(response);
  }

  static String errorMessageFromResponse(http.Response response, String fallback) {
    var message = fallback;
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        message = body['message']?.toString() ??
            body['Message']?.toString() ??
            body['title']?.toString() ??
            _formatErrors(body['errors']) ??
            message;
      } else if (body is String && body.isNotEmpty) {
        message = body;
      }
    } catch (_) {
      if (response.body.isNotEmpty) message = response.body;
    }
    return message;
  }

  static dynamic _decode(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    var message = 'Istek tamamlanamadi (${response.statusCode}).';
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        message = body['message']?.toString() ??
            body['title']?.toString() ??
            body['errors']?.toString() ??
            message;
      } else if (body is String && body.isNotEmpty) {
        message = body;
      }
    } catch (_) {
      if (response.body.isNotEmpty) message = response.body;
    }

    debugPrint('API error ${response.statusCode}: $message');
    throw ApiException(message, statusCode: response.statusCode);
  }

  static String? _formatErrors(dynamic errors) {
    if (errors == null) return null;
    if (errors is List) return errors.map((e) => e.toString()).join(', ');
    if (errors is Map) {
      return errors.values
          .expand((value) => value is List ? value : [value])
          .map((value) => value.toString())
          .join(', ');
    }
    return errors.toString();
  }
}
