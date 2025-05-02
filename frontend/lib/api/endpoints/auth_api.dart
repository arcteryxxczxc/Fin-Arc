// lib/api/endpoints/auth_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';
import '../client.dart';

class AuthApi {
  final ApiClient _client = ApiClient();
  final String baseUrl = AppConstants.baseUrl;

  /// Register a new user (direct HTTP call to avoid circular dependencies)
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final body = {
        'username': username,
        'email': email,
        'password': password,
        'first_name': firstName ?? '',
        'last_name': lastName ?? '',
      };

      print('AuthApi: Making register API call to $baseUrl/auth/register');
      
      // Direct HTTP call with proper CORS handling
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('AuthApi: Register response status: ${response.statusCode}');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        print('AuthApi: Register error response body: ${response.body}');
      } else {
        print('AuthApi: Register successful response');
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
          'message': data['msg'] ?? data['error'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      print('AuthApi: Registration network error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Login user (direct HTTP call to avoid circular dependencies)
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final body = {
        'username': username,
        'password': password,
      };

      print('AuthApi: Making login API call to $baseUrl/auth/login');
      
      // Direct HTTP call with proper CORS handling
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('AuthApi: Login response status: ${response.statusCode}');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        print('AuthApi: Login error response body: ${response.body}');
      } else {
        print('AuthApi: Login successful response');
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
          'message': data['msg'] ?? data['error'] ?? 'Login failed',
        };
      }
    } catch (e) {
      print('AuthApi: Login network error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>> getUserProfile() async {
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

  /// Refresh token (direct HTTP call to avoid circular dependencies)
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {
          'Authorization': 'Bearer $refreshToken',
          'Accept': 'application/json',
        },
      );

      // Parse response
      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        print('AuthApi: JSON parse error: $e');
        return {
          'success': false,
          'message': 'Failed to parse response'
        };
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
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
}