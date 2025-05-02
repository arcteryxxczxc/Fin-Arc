import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class StorageService {
  // Shared preferences for non-sensitive data
  late SharedPreferences _prefs;
  
  // Secure storage for sensitive data
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  
  // Initialize shared preferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  // Save simple data using shared preferences
  Future<bool> saveData(String key, dynamic value) async {
    if (value is String) {
      return await _prefs.setString(key, value);
    } else if (value is int) {
      return await _prefs.setInt(key, value);
    } else if (value is double) {
      return await _prefs.setDouble(key, value);
    } else if (value is bool) {
      return await _prefs.setBool(key, value);
    } else if (value is List<String>) {
      return await _prefs.setStringList(key, value);
    } else {
      // Convert complex objects to JSON string
      return await _prefs.setString(key, jsonEncode(value));
    }
  }
  
  // Get data from shared preferences
  dynamic getData(String key, {dynamic defaultValue}) {
    return _prefs.get(key) ?? defaultValue;
  }
  
  // Remove data from shared preferences
  Future<bool> removeData(String key) async {
    return await _prefs.remove(key);
  }
  
  // Clear all data from shared preferences
  Future<bool> clearAll() async {
    return await _prefs.clear();
  }
  
  // Check if key exists in shared preferences
  bool containsKey(String key) {
    return _prefs.containsKey(key);
  }
  
  // Save sensitive data using secure storage
  Future<void> saveSecureData(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }
  
  // Get sensitive data from secure storage
  Future<String?> getSecureData(String key) async {
    return await _secureStorage.read(key: key);
  }
  
  // Remove sensitive data from secure storage
  Future<void> removeSecureData(String key) async {
    await _secureStorage.delete(key: key);
  }
  
  // Clear all sensitive data from secure storage
  Future<void> clearAllSecureData() async {
    await _secureStorage.deleteAll();
  }
  
  // Helper method to save complex objects
  Future<bool> saveObject<T>(String key, T object, Function encode) async {
    final jsonData = encode(object);
    return await saveData(key, jsonEncode(jsonData));
  }
  
  // Helper method to retrieve complex objects
  T? getObject<T>(String key, Function decode) {
    final jsonString = getData(key) as String?;
    if (jsonString == null) return null;
    
    final jsonData = jsonDecode(jsonString);
    return decode(jsonData) as T;
  }
  
  // Helper methods for common settings
  Future<bool> saveThemeMode(bool isDarkMode) async {
    return await saveData(AppConstants.themeKey, isDarkMode);
  }
  
  bool getThemeMode() {
    return getData(AppConstants.themeKey, defaultValue: true) as bool;
  }
  
  Future<bool> saveLanguage(String language) async {
    return await saveData(AppConstants.languageKey, language);
  }
  
  String getLanguage() {
    return getData(AppConstants.languageKey, defaultValue: 'en_US') as String;
  }
  
  Future<bool> saveCurrency(String currency) async {
    return await saveData('currency', currency);
  }
  
  String getCurrency() {
    return getData('currency', defaultValue: AppConstants.defaultCurrency) as String;
  }
}