// lib/api/endpoints/settings_api.dart
import '../client.dart';

class SettingsApi {
  final ApiClient _client = ApiClient();

  /// Get user settings
  Future<Map<String, dynamic>> getUserSettings() async {
    try {
      final response = await _client.get(
        endpoint: 'settings',
        requiresAuth: true,
      );

      return response;
    } catch (e) {
      print('API error getting user settings: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Update user settings
  Future<Map<String, dynamic>> updateUserSettings(Map<String, dynamic> settings) async {
    try {
      final response = await _client.put(
        endpoint: 'settings',
        body: settings,
        requiresAuth: true,
      );

      return response;
    } catch (e) {
      print('API error updating user settings: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Get available currencies
  Future<Map<String, dynamic>> getAvailableCurrencies() async {
    try {
      final response = await _client.get(
        endpoint: 'currencies/list',
        requiresAuth: false, // This endpoint might not require authentication
      );

      // Check if we need to process the response format
      if (response['success']) {
        return response;
      }

      return response;
    } catch (e) {
      print('API error getting available currencies: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Convert currency
  Future<Map<String, dynamic>> convertCurrency({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    try {
      final queryParams = {
        'amount': amount.toString(),
        'from': fromCurrency,
        'to': toCurrency,
      };

      final response = await _client.get(
        endpoint: 'currencies/convert',
        queryParams: queryParams,
        requiresAuth: true,
      );

      return response;
    } catch (e) {
      print('API error converting currency: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Get exchange rates
  Future<Map<String, dynamic>> getExchangeRates({
    required String baseCurrency,
    String targetCurrencies = 'USD,EUR,RUB,KZT',
  }) async {
    try {
      final queryParams = {
        'base': baseCurrency,
        'targets': targetCurrencies,
      };

      final response = await _client.get(
        endpoint: 'currencies/rates',
        queryParams: queryParams,
        requiresAuth: true,
      );

      return response;
    } catch (e) {
      print('API error getting exchange rates: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}