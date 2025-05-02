// lib/api/client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class ApiClient {
  // Direct secure storage access for tokens to avoid circular dependencies
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  
  final String baseUrl = AppConstants.baseUrl;

  /// Make a GET request to the API
  Future<Map<String, dynamic>> get({
    required String endpoint,
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    try {
      // Get auth token if required
      String? token;
      if (requiresAuth) {
        token = await _getToken();
        if (token == null) {
          return {'success': false, 'message': 'Not authenticated'};
        }
      }

      // Build URI with query parameters
      final uri = Uri.parse('$baseUrl/$endpoint').replace(
        queryParameters: queryParams,
      );

      print('GET API call to $uri');

      // Set up headers
      final headers = {
        'Content-Type': 'application/json',
        if (requiresAuth && token != null) 'Authorization': 'Bearer $token',
      };

      // Make request
      final response = await http.get(uri, headers: headers);
      print('GET response status: ${response.statusCode}');

      // Handle response
      return _handleResponse(response);
    } catch (e) {
      print('API GET error: $e');
      // Handle exceptions
      return _handleException(e);
    }
  }

  /// Make a POST request to the API
  Future<Map<String, dynamic>> post({
    required String endpoint,
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      // Get auth token if required
      String? token;
      if (requiresAuth) {
        token = await _getToken();
        if (token == null) {
          return {'success': false, 'message': 'Not authenticated'};
        }
      }

      // Build URI
      final uri = Uri.parse('$baseUrl/$endpoint');
      print('POST API call to $uri');

      // Set up headers
      final headers = {
        'Content-Type': 'application/json',
        if (requiresAuth && token != null) 'Authorization': 'Bearer $token',
      };

      // Make request
      final response = await http.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      
      print('POST response status: ${response.statusCode}');

      // Handle response
      return _handleResponse(response);
    } catch (e) {
      print('API POST error: $e');
      // Handle exceptions
      return _handleException(e);
    }
  }

  /// Make a PUT request to the API
  Future<Map<String, dynamic>> put({
    required String endpoint,
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      // Get auth token if required
      String? token;
      if (requiresAuth) {
        token = await _getToken();
        if (token == null) {
          return {'success': false, 'message': 'Not authenticated'};
        }
      }

      // Build URI
      final uri = Uri.parse('$baseUrl/$endpoint');
      print('PUT API call to $uri');

      // Set up headers
      final headers = {
        'Content-Type': 'application/json',
        if (requiresAuth && token != null) 'Authorization': 'Bearer $token',
      };

      // Make request
      final response = await http.put(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      
      print('PUT response status: ${response.statusCode}');

      // Handle response
      return _handleResponse(response);
    } catch (e) {
      print('API PUT error: $e');
      // Handle exceptions
      return _handleException(e);
    }
  }

  /// Make a DELETE request to the API
  Future<Map<String, dynamic>> delete({
    required String endpoint,
    bool requiresAuth = true,
  }) async {
    try {
      // Get auth token if required
      String? token;
      if (requiresAuth) {
        token = await _getToken();
        if (token == null) {
          return {'success': false, 'message': 'Not authenticated'};
        }
      }

      // Build URI
      final uri = Uri.parse('$baseUrl/$endpoint');
      print('DELETE API call to $uri');

      // Set up headers
      final headers = {
        'Content-Type': 'application/json',
        if (requiresAuth && token != null) 'Authorization': 'Bearer $token',
      };

      // Make request
      final response = await http.delete(uri, headers: headers);
      
      print('DELETE response status: ${response.statusCode}');

      // Handle response
      return _handleResponse(response);
    } catch (e) {
      print('API DELETE error: $e');
      // Handle exceptions
      return _handleException(e);
    }
  }

  /// Get raw response (for file downloads)
  Future<http.Response> getRaw({
    required String endpoint,
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    // Get auth token if required
    String? token;
    if (requiresAuth) {
      token = await _getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }
    }

    // Build URI with query parameters
    final uri = Uri.parse('$baseUrl/$endpoint').replace(
      queryParameters: queryParams,
    );

    print('GET RAW API call to $uri');

    // Set up headers
    final headers = {
      if (requiresAuth && token != null) 'Authorization': 'Bearer $token',
    };

    // Make request and return raw response
    return await http.get(uri, headers: headers);
  }

  /// Handle HTTP response and parse JSON
  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      // Check if response body is empty
      if (response.body.isEmpty) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return {'success': true, 'data': {}};
        } else {
          return {
            'success': false,
            'statusCode': response.statusCode,
            'message': 'Empty response with status code ${response.statusCode}',
          };
        }
      }

      // Parse JSON response
      final data = jsonDecode(response.body);
      
      // Check if response is successful
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': data};
      } else {
        // Handle API error
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': data['msg'] ?? data['error'] ?? 'An error occurred',
        };
      }
    } catch (e) {
      print('Response parsing error: $e for body: ${response.body}');
      // If JSON parsing fails
      return {
        'success': false,
        'statusCode': response.statusCode,
        'message': 'Failed to parse response: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...',
      };
    }
  }

  /// Handle exceptions from HTTP requests
  Map<String, dynamic> _handleException(dynamic error) {
    // Format error message based on exception type
    String errorMessage;
    if (error is http.ClientException) {
      errorMessage = 'Network connection error: ${error.message}';
    } else if (error is FormatException) {
      errorMessage = 'Invalid response format: ${error.message}';
    } else {
      errorMessage = 'An unexpected error occurred: $error';
    }

    print('API error handled: $errorMessage');
    return {'success': false, 'message': errorMessage};
  }

  /// Get token directly from storage
  Future<String?> _getToken() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) {
      // Try to refresh the token
      return await _refreshToken();
    }
    return token;
  }

  /// Refresh token implementation that doesn't rely on AuthService
  Future<String?> _refreshToken() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken == null) return null;
    
    try {
      print('Attempting to refresh token directly from ApiClient');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Authorization': 'Bearer $refreshToken'},
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        final newToken = data['access_token'];
        await _storage.write(key: _tokenKey, value: newToken);
        print('Token refreshed successfully');
        return newToken;
      }
    } catch (e) {
      print('Token refresh error in ApiClient: $e');
    }
    
    return null;
  }
}