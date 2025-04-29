import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import 'constants.dart';

/// Utility class for making API requests with error handling and authentication
class ApiUtils {
  static final AuthService _authService = AuthService();
  
  /// Make a GET request to the API
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    bool requiresAuth = true,
  }) async {
    try {
      // Build URI with query parameters
      final uri = Uri.parse('${AppConstants.baseUrl}/$endpoint').replace(
        queryParameters: queryParams?.map((key, value) => 
          MapEntry(key, value.toString())
        ),
      );
      
      // Get auth token if authentication is required
      String? token;
      if (requiresAuth) {
        token = await _authService.getToken();
        if (token == null) {
          return {'success': false, 'message': 'Not authenticated'};
        }
      }
      
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
  static Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/$endpoint');
      
      // Get auth token if authentication is required
      String? token;
      if (requiresAuth) {
        token = await _authService.getToken();
        if (token == null) {
          return {'success': false, 'message': 'Not authenticated'};
        }
      }
      
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
  static Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/$endpoint');
      
      // Get auth token if authentication is required
      String? token;
      if (requiresAuth) {
        token = await _authService.getToken();
        if (token == null) {
          return {'success': false, 'message': 'Not authenticated'};
        }
      }
      
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
  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/$endpoint');
      
      // Get auth token if authentication is required
      String? token;
      if (requiresAuth) {
        token = await _authService.getToken();
        if (token == null) {
          return {'success': false, 'message': 'Not authenticated'};
        }
      }
      
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
  
  /// Handle HTTP response and parse JSON
  static Map<String, dynamic> _handleResponse(http.Response response) {
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
          'message': data['msg'] ?? 'An error occurred',
        };
      }
    } catch (e) {
      // If JSON parsing fails
      return {
        'success': false,
        'statusCode': response.statusCode,
        'message': 'Failed to parse response',
      };
    }
  }
  
  /// Handle exceptions from HTTP requests
  static Map<String, dynamic> _handleException(dynamic error) {
    if (kDebugMode) {
      print('API Error: $error');
    }
    
    // Format error message based on exception type
    String errorMessage;
    if (error is http.ClientException) {
      errorMessage = 'Network connection error';
    } else if (error is FormatException) {
      errorMessage = 'Invalid response format';
    } else {
      errorMessage = 'An unexpected error occurred';
    }
    
    return {'success': false, 'message': errorMessage};
  }
  
  /// Check if the user is authenticated
  static Future<bool> isAuthenticated() async {
    return await _authService.isAuthenticated();
  }
  
  /// Log out the user
  static Future<void> logout() async {
    await _authService.logout();
  }
}