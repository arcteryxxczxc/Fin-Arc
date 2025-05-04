// lib/api/endpoints/auth_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';
import '../client.dart';

class AuthApi {
  final ApiClient _client = ApiClient();
  final String baseUrl = AppConstants.baseUrl;

  /// Common method for auth requests to avoid code duplication
  Future<Map<String, dynamic>> _makeAuthRequest(String endpoint, Map<String, dynamic> body) async {
    try {
      print('AuthApi: Making API call to $baseUrl/auth/$endpoint');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('AuthApi: $endpoint response status: ${response.statusCode}');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        print('AuthApi: $endpoint error response body: ${response.body}');
      } else {
        print('AuthApi: $endpoint successful response');
      }
      
      // Parse response
      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        print('AuthApi: JSON parse error: $e');
        return {
          'success': false,
          'message': 'Failed to parse response: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...'
        };
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': data['msg'] ?? data['error'] ?? '$endpoint failed',
        };
      }
    } catch (e) {
      print('AuthApi: $endpoint network error: $e');
      
      String errorMessage = 'Network error';
      if (e.toString().contains('SocketException')) {
        errorMessage = 'Cannot connect to server. Please check your internet connection.';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Connection timed out. Server might be down or unreachable.';
      } else {
        errorMessage = 'Network error: $e';
      }
      
      return {'success': false, 'message': errorMessage};
    }
  }

  /// Register a new user
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    final body = {
      'username': username,
      'email': email,
      'password': password,
      'first_name': firstName ?? '',
      'last_name': lastName ?? '',
    };
    
    return _makeAuthRequest('register', body);
  }

  /// Login user
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final body = {
      'username': username,
      'password': password,
    };
    
    return _makeAuthRequest('login', body);
  }

  /// Get user profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _client.get(
        endpoint: 'auth/profile',
      );

      return response;
    } catch (e) {
      print('AuthApi: Get profile error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Change password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final body = {
        'current_password': currentPassword,
        'new_password': newPassword,
      };

      final response = await _client.post(
        endpoint: 'auth/change-password',
        body: body,
      );

      return response;
    } catch (e) {
      print('AuthApi: Change password error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Refresh token 
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {
          'Authorization': 'Bearer $refreshToken',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      // Parse response
      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        print('AuthApi: Refresh token JSON parse error: $e');
        return {
          'success': false,
          'message': 'Failed to parse refresh token response',
          'error': e.toString()
        };
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (!data.containsKey('access_token')) {
          return {
            'success': false,
            'message': 'Invalid refresh token response: missing access_token'
          };
        }
        
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': data['msg'] ?? data['error'] ?? 'Failed to refresh token',
        };
      }
    } catch (e) {
      print('AuthApi: Refresh token error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Logout user
  Future<Map<String, dynamic>> logout() async {
    try {
      final response = await _client.post(
        endpoint: 'auth/logout',
      );

      return response;
    } catch (e) {
      print('AuthApi: Logout error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
  /// Get login history
  Future<Map<String, dynamic>> getLoginHistory() async {
    try {
      // This is a hypothetical endpoint that might be available in a future API version
      final response = await _client.get(
        endpoint: 'auth/login-history',
        requiresAuth: true,
      );
      
      return response;
    } catch (e) {
      print('API error getting login history: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}