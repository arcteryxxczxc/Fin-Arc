// lib/services/settings_service.dart
import '../api/endpoints/settings_api.dart';
import '../utils/error_handler.dart';

class SettingsService {
  final SettingsApi _settingsApi = SettingsApi();

  /// Get user settings
  Future<Map<String, dynamic>> getUserSettings() async {
    try {
      final result = await _settingsApi.getUserSettings();
      
      // Debug output for response format
      print('User settings response: ${_truncateResponseForLog(result)}');
      
      return result;
    } catch (e) {
      print('Error getting user settings: $e');
      return {'success': false, 'message': ErrorHandler.parseApiError(e)};
    }
  }

  /// Update a specific user setting
  Future<Map<String, dynamic>> updateUserSetting(String key, dynamic value) async {
    try {
      // Create the settings object with only the specific setting to update
      final settings = {key: value};
      
      final result = await _settingsApi.updateUserSettings(settings);
      
      // Debug output for response format
      print('Update setting response: ${_truncateResponseForLog(result)}');
      
      return result;
    } catch (e) {
      print('Error updating user setting: $e');
      return {'success': false, 'message': ErrorHandler.parseApiError(e)};
    }
  }

  /// Update multiple user settings at once
  Future<Map<String, dynamic>> updateUserSettings(Map<String, dynamic> settings) async {
    try {
      final result = await _settingsApi.updateUserSettings(settings);
      
      // Debug output for response format
      print('Update settings response: ${_truncateResponseForLog(result)}');
      
      return result;
    } catch (e) {
      print('Error updating user settings: $e');
      return {'success': false, 'message': ErrorHandler.parseApiError(e)};
    }
  }

  /// Get available currencies
  Future<Map<String, dynamic>> getAvailableCurrencies() async {
    try {
      final result = await _settingsApi.getAvailableCurrencies();
      
      // Debug output for response format
      print('Available currencies response: ${_truncateResponseForLog(result)}');
      
      // Process the response to ensure it's in the expected format
      if (result['success'] && result.containsKey('data')) {
        final data = result['data'];
        
        // The API might return currencies in different formats
        // Check if it's directly a list of currencies or if it's nested
        if (data is List) {
          // Already in the correct format
          return {'success': true, 'data': data};
        } else if (data is Map && data.containsKey('currencies')) {
          // Extract currencies from nested structure
          final currencies = data['currencies'];
          if (currencies is List) {
            return {'success': true, 'data': currencies};
          }
        }
        
        // If we couldn't find currencies in the expected formats, return the raw data
        return {'success': true, 'data': data};
      }
      
      return result;
    } catch (e) {
      print('Error getting available currencies: $e');
      return {'success': false, 'message': ErrorHandler.parseApiError(e)};
    }
  }

  /// Helper method to truncate long responses for logging
  String _truncateResponseForLog(Map<String, dynamic> response) {
    final responseStr = response.toString();
    return responseStr.length > 300 
        ? '${responseStr.substring(0, 300)}...'
        : responseStr;
  }
}