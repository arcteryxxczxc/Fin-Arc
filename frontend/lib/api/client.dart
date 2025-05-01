// lib/api/client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../utils/constants.dart';

class ApiClient {
  final AuthService _authService = AuthService();
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
        token = await _authService.getToken();
        if (token == null) {
          return {'success': false, 'message': 'Not authenticated'};
        }
      }

      // Build URI with query parameters
      final uri = Uri.parse('$baseUrl/$endpoint').replace(
        queryParameters: queryParams,
      );

      // Set up headers
      final headers = {
        'Content-Type': 'application/json',
        if (requiresAuth && token != null) 'Authorization': 'Bearer $token',
      };

      // Make request
      final response = await http.get(uri, headers: headers);

      // Handle response
      return _handleResponse(response);
    } catch (e) {
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
        token = await _authService.getToken();
        if (token == null) {
          return {'success': false, 'message': 'Not authenticated'};
        }
      }

      // Build URI
      final uri = Uri.parse('$baseUrl/$endpoint');

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

      // Handle response
      return _handleResponse(response);
    } catch (e) {
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
        token = await _authService.getToken();
        if (token == null) {
          return {'success': false, 'message': 'Not authenticated'};
        }
      }

      // Build URI
      final uri = Uri.parse('$baseUrl/$endpoint');

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

      // Handle response
      return _handleResponse(response);
    } catch (e) {
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
        token = await _authService.getToken();
        if (token == null) {
          return {'success': false, 'message': 'Not authenticated'};
        }
      }

      // Build URI
      final uri = Uri.parse('$baseUrl/$endpoint');

      // Set up headers
      final headers = {
        'Content-Type': 'application/json',
        if (requiresAuth && token != null) 'Authorization': 'Bearer $token',
      };

      // Make request
      final response = await http.delete(uri, headers: headers);

      // Handle response
      return _handleResponse(response);
    } catch (e) {
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
      token = await _authService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }
    }

    // Build URI with query parameters
    final uri = Uri.parse('$baseUrl/$endpoint').replace(
      queryParameters: queryParams,
    );

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
      // If JSON parsing fails
      return {
        'success': false,
        'statusCode': response.statusCode,
        'message': 'Failed to parse response: ${response.body}',
      };
    }
  }

  /// Handle exceptions from HTTP requests
  Map<String, dynamic> _handleException(dynamic error) {
    // Format error message based on exception type
    String errorMessage;
    if (error is http.ClientException) {
      errorMessage = 'Network connection error';
    } else if (error is FormatException) {
      errorMessage = 'Invalid response format';
    } else {
      errorMessage = 'An unexpected error occurred: $error';
    }

    return {'success': false, 'message': errorMessage};
  }
}