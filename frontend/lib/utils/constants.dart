// lib/utils/constants.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

/// Application constants
class AppConstants {
  // API Base URL - Dynamically determined based on platform
  static String get baseUrl {
    if (kIsWeb) {
      // Web platform logic
      try {
        final currentUrl = Uri.base.toString();
        if (currentUrl.contains('localhost') || currentUrl.contains('127.0.0.1')) {
          // For development on localhost
          return 'http://localhost:8111/api';
        } else {
          // For production deployed site
          final uri = Uri.parse(currentUrl);
          return '${uri.scheme}://${uri.host}${uri.port > 0 ? ':${uri.port}' : ''}/api';
        }
      } catch (e) {
        print('Error determining API URL: $e');
        // Default fallback API URL for web
        return 'http://localhost:8111/api';
      }
    } else {
      // Mobile platforms
      if (Platform.isAndroid) {
        return androidBaseUrl;
      } else if (Platform.isIOS) {
        return iosBaseUrl;
      }
      // Fallback for other platforms
      return 'http://localhost:8111/api';
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
  static const String languageKey = 'app_language';
  
  // Date formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm';
  static const String monthYearFormat = 'MMMM yyyy';
  
  // Currency formats
  static const int decimalDigits = 2;
  
  // Pagination defaults
  static const int defaultPageSize = 10;

  // This function is now replaced with the direct URL construction in the API client
  // We're keeping it for backward compatibility but NOT USING it anymore
  static String apiUrl(String endpoint) {
    // Remove leading slash if present
    if (endpoint.startsWith('/')) {
      endpoint = endpoint.substring(1);
    }
    
    // Return just the endpoint (no additional path manipulation)
    return endpoint;
  }
}