import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  // Android emülatörde PC'nin localhost'u 10.0.2.2 olarak erişilir.
  // Web veya fiziksel cihazda gerçek IP kullanılır.
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:5000';
    if (Platform.isAndroid) return 'http://10.0.2.2:5000';
    return 'http://localhost:5000';
  }

  static String get apiUrl => '$baseUrl/api';

  static String resolveUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('/')) return '$baseUrl$url';
    if (!kIsWeb && Platform.isAndroid) {
      return url
          .replaceFirst('http://localhost:5000', baseUrl)
          .replaceFirst('https://localhost:9001', baseUrl);
    }
    return url;
  }
}
