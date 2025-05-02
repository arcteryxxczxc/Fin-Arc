class AppConstants {
  // API URLs
  //static const String baseUrl = 'http://10.0.2.2:5000/api'; // For emulator use
  static const String baseUrl = 'http://localhost:5000/api'; // For web use
  //static const String baseUrl = 'http://127.0.0.1:5000/api';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'app_theme';
  static const String languageKey = 'app_language';
  
  // App Info
  static const String appName = 'Fin-Arc';
  static const String appVersion = '1.0.0';
  
  // Default Values
  static const String defaultCurrency = 'UZS';
  
  // Notification Channels
  static const String budgetChannel = 'budget_notifications';
}