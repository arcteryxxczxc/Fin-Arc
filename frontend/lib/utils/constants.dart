// lib/utils/constants.dart
import 'dart:html' as html;

/// Application constants
class AppConstants {
  // API Base URL - Динамически определяется на основе текущего URL
  static String get baseUrl {
    // Получаем текущий URL (работает только в web)
    final currentUrl = html.window.location.href;
    final serverPort = '8111'; // Порт вашего Flask-сервера
    
    try {
      if (currentUrl.contains('localhost') || currentUrl.contains('127.0.0.1')) {
        // В режиме разработки используем указанный порт Flask-сервера
        return 'http://localhost:$serverPort/api';
      } else {
        // В продакшене используем тот же домен (на одном сервере)
        final uri = Uri.parse(currentUrl);
        return '${uri.scheme}://${uri.host}/api';
      }
    } catch (e) {
      print('Error determining API URL: $e');
      // Запасной вариант
      return 'http://localhost:$serverPort/api';
    }
  }
  
  // Alternate URLs for different environments
  static const String androidBaseUrl = 'http://10.0.2.2:8111/api';
  static const String iosBaseUrl = 'http://127.0.0.1:8111/api';
  
  // Authentication settings
  static const int tokenExpirationDays = 30;
  
  // Theme settings
  static const String defaultTheme = 'light';
  
  // Currency settings
  static const String defaultCurrency = 'UZS';
  
  // App settings
  static const String appName = 'Fin-Arc';
  static const String appVersion = '1.0.0';
  static const String themeKey = 'app_theme';
  
  // Date formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm';
  static const String monthYearFormat = 'MMMM yyyy';
  
  // Currency formats
  static const int decimalDigits = 2;
  
  // Pagination defaults
  static const int defaultPageSize = 10;
}