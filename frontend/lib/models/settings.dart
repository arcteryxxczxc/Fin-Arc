// settings.dart
class Settings {
  final String currency;
  final String locale;
  final bool useDarkMode;
  final bool notificationsEnabled;
  final List<String> notificationTypes;
  final String defaultView; // 'dashboard', 'expenses', etc.
  final int budgetPeriodStartDay;
  final Map<String, dynamic> customSettings;
  
  Settings({
    required this.currency,
    required this.locale,
    required this.useDarkMode,
    required this.notificationsEnabled,
    required this.notificationTypes,
    required this.defaultView,
    required this.budgetPeriodStartDay,
    required this.customSettings,
  });
  
  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      currency: json['currency'] ?? 'USD',
      locale: json['locale'] ?? 'en_US',
      useDarkMode: json['use_dark_mode'] ?? true,
      notificationsEnabled: json['notifications_enabled'] ?? true,
      notificationTypes: List<String>.from(json['notification_types'] ?? []),
      defaultView: json['default_view'] ?? 'dashboard',
      budgetPeriodStartDay: json['budget_period_start_day'] ?? 1,
      customSettings: json['custom_settings'] ?? {},
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'currency': currency,
      'locale': locale,
      'use_dark_mode': useDarkMode,
      'notifications_enabled': notificationsEnabled,
      'notification_types': notificationTypes,
      'default_view': defaultView,
      'budget_period_start_day': budgetPeriodStartDay,
      'custom_settings': customSettings,
    };
  }
  
  Settings copyWith({
    String? currency,
    String? locale,
    bool? useDarkMode,
    bool? notificationsEnabled,
    List<String>? notificationTypes,
    String? defaultView,
    int? budgetPeriodStartDay,
    Map<String, dynamic>? customSettings,
  }) {
    return Settings(
      currency: currency ?? this.currency,
      locale: locale ?? this.locale,
      useDarkMode: useDarkMode ?? this.useDarkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationTypes: notificationTypes ?? this.notificationTypes,
      defaultView: defaultView ?? this.defaultView,
      budgetPeriodStartDay: budgetPeriodStartDay ?? this.budgetPeriodStartDay,
      customSettings: customSettings ?? this.customSettings,
    );
  }
}