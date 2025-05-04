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
  
  String get baseUrl => AppConstants.baseUrl;

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

      print('Making GET request to: ${uri.toString()}');

      // Set up headers
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (requiresAuth && token != null) 'Authorization': 'Bearer $token',
      };

      // Make request with timeout
      final response = await http.get(
        uri, 
        headers: headers
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          return http.Response('{"msg": "Request timed out"}', 408);
        }
      );
      
      print('GET response status: ${response.statusCode}');
      if (response.body.isNotEmpty) {
        print('GET response body preview: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...');
      }

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
        if (token == null && requiresAuth) {
          return {'success': false, 'message': 'Not authenticated'};
        }
      }

      // Build URI
      final uri = Uri.parse('$baseUrl/$endpoint');
      print('Making POST request to: ${uri.toString()}');
      if (body != null) {
        print('POST body: ${jsonEncode(body)}');
      }

      // Set up headers
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (requiresAuth && token != null) 'Authorization': 'Bearer $token',
      };

      // Make request with timeout
      final response = await http.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          return http.Response('{"msg": "Request timed out"}', 408);
        }
      );
      
      print('POST response status: ${response.statusCode}');
      if (response.body.isNotEmpty) {
        print('POST response body preview: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...');
      }

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
      print('Making PUT request to: ${uri.toString()}');
      if (body != null) {
        print('PUT body: ${jsonEncode(body)}');
      }

      // Set up headers
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (requiresAuth && token != null) 'Authorization': 'Bearer $token',
      };

      // Make request with timeout
      final response = await http.put(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          return http.Response('{"msg": "Request timed out"}', 408);
        }
      );
      
      print('PUT response status: ${response.statusCode}');
      if (response.body.isNotEmpty) {
        print('PUT response body preview: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...');
      }

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
      print('Making DELETE request to: ${uri.toString()}');

      // Set up headers
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (requiresAuth && token != null) 'Authorization': 'Bearer $token',
      };

      // Make request with timeout
      final response = await http.delete(
        uri, 
        headers: headers
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          return http.Response('{"msg": "Request timed out"}', 408);
        }
      );
      
      print('DELETE response status: ${response.statusCode}');
      if (response.body.isNotEmpty) {
        print('DELETE response body preview: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...');
      }

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

    print('Making raw GET request to: ${uri.toString()}');

    // Set up headers
    final headers = {
      'Accept': '*/*',
      if (requiresAuth && token != null) 'Authorization': 'Bearer $token',
    };

    // Make request and return raw response
    return await http.get(uri, headers: headers).timeout(
      const Duration(seconds: 60), // Longer timeout for file downloads
      onTimeout: () {
        return http.Response('Request timed out', 408);
      }
    );
  }

  /// Handle HTTP response and parse JSON
  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      // Handle specific status codes
      if (response.statusCode == 405) {
        print('405 Method Not Allowed Error - Endpoint might not exist or HTTP method not supported');
        return {
          'success': false,
          'statusCode': 405,
          'message': 'Method not allowed. The API endpoint does not support this request type.',
        };
      }

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
      
      // If data is null, return empty object
      if (data == null) {
        return {
          'success': response.statusCode >= 200 && response.statusCode < 300,
          'data': {},
        };
      }
      
      // If the response is a list, wrap it in a map
      if (data is List) {
        return {
          'success': true,
          'data': data,
        };
      }
      
      // Check if response is successful
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': data};
      } else {
        // Handle API error - check various possible error fields
        final errorMessage = data['msg'] ?? data['error'] ?? data['message'] ?? 'An error occurred';
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': errorMessage,
          'details': data,  // Include full response details for better debugging
        };
      }
    } catch (e) {
      print('Response parsing error: $e for body: ${response.body}');
      // If JSON parsing fails
      String previewBody = '';
      try {
        previewBody = response.body.substring(0, response.body.length > 100 ? 100 : response.body.length);
      } catch (_) {
        previewBody = 'Could not preview response body';
      }
      
      return {
        'success': false,
        'statusCode': response.statusCode,
        'message': 'Failed to parse response: $previewBody...',
        'parse_error': e.toString(),
      };
    }
  }

  /// Handle exceptions from HTTP requests
  Map<String, dynamic> _handleException(dynamic error) {
    // Format error message based on exception type
    String errorMessage;
    String errorType = 'unknown';
    
    if (error is http.ClientException) {
      errorMessage = 'Network connection error: ${error.message}';
      errorType = 'network';
    } else if (error is FormatException) {
      errorMessage = 'Invalid response format: ${error.message}';
      errorType = 'format';
    } else if (error.toString().contains('SocketException')) {
      errorMessage = 'Network connection error. Please check your internet connection.';
      errorType = 'socket';
    } else if (error.toString().contains('TimeoutException')) {
      errorMessage = 'Request timed out. The server is taking too long to respond.';
      errorType = 'timeout';
    } else {
      errorMessage = 'An unexpected error occurred: $error';
      errorType = 'unexpected';
    }

    print('API error handled: $errorMessage');
    return {
      'success': false, 
      'message': errorMessage,
      'error_type': errorType,
    };
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
    if (refreshToken == null) {
      print('No refresh token available');
      return null;
    }
    
    try {
      print('Attempting to refresh token');
      
      // Fixed URL for refresh endpoint
      final uri = Uri.parse('$baseUrl/auth/refresh');
      
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $refreshToken',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (!data.containsKey('access_token')) {
          print('Refresh token response missing access_token');
          return null;
        }
        
        final newToken = data['access_token'];
        await _storage.write(key: _tokenKey, value: newToken);
        
        // Also update refresh token if provided
        if (data.containsKey('refresh_token')) {
          await _storage.write(key: _refreshTokenKey, value: data['refresh_token']);
        }
        
        print('Token refreshed successfully');
        return newToken;
      } else {
        print('Token refresh failed with status: ${response.statusCode}');
        // Clear tokens on failed refresh
        await _storage.delete(key: _tokenKey);
        await _storage.delete(key: _refreshTokenKey);
      }
    } catch (e) {
      print('Token refresh error: $e');
    }
    
    return null;
  }
}