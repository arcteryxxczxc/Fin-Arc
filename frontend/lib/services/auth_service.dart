// lib/services/auth_service.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../utils/constants.dart';

class AuthService {
  // Secure storage for tokens
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  
  // Token storage keys
  static const String _tokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
  
  // Register a new user
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

      print('Making register API call to ${AppConstants.baseUrl}/auth/register');
      
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      
      print('Register API response status: ${response.statusCode}');
      print('Register API response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Save token and user data to secure storage
        await _saveAuthData(data['access_token'], data['refresh_token'], data['user']);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['error'] ?? 'Registration failed'};
      }
    } catch (e) {
      print('Registration service error: $e');
      return {'success': false, 'message': 'Service error: $e'};
    }
  }
  
  // Login user
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final body = {
        'username': username,
        'password': password,
      };

      print('Making login API call to ${AppConstants.baseUrl}/auth/login');
      
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      
      print('Login API response status: ${response.statusCode}');
      print('Login API response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Save token and user data to secure storage
        await _saveAuthData(data['access_token'], data['refresh_token'], data['user']);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['error'] ?? 'Login failed'};
      }
    } catch (e) {
      print('Login service error: $e');
      return {'success': false, 'message': 'Service error: $e'};
    }
  }
  
  // Logout user
  Future<void> logout() async {
    String? token = await _storage.read(key: _tokenKey);
    
    try {
      // Only call the API if we have a token
      if (token != null) {
        print('Making logout API call');
        
        await http.post(
          Uri.parse('${AppConstants.baseUrl}/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
          },
        );
      }
    } catch (e) {
      // Even if server logout fails, continue to clear local storage
      print('Logout error: $e');
    } finally {
      // Clear tokens from secure storage
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _userKey);
      print('Local auth data cleared');
    }
  }
  
  // Get current user data from storage
  Future<User?> getCurrentUser() async {
    final userData = await _storage.read(key: _userKey);
    if (userData != null) {
      try {
        return User.fromJson(jsonDecode(userData));
      } catch (e) {
        print('Error parsing user data: $e');
        return null;
      }
    }
    return null;
  }
  
  // Get auth token
  Future<String?> getToken() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) {
      // Try to refresh the token if we have a refresh token
      return await _refreshToken();
    }
    return token;
  }
  
  // Try to refresh the access token
  Future<String?> _refreshToken() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken == null) return null;
    
    try {
      print('Attempting to refresh token');
      
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/refresh'),
        headers: {'Authorization': 'Bearer $refreshToken'},
      );
      
      print('Token refresh response status: ${response.statusCode}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        final newToken = data['access_token'];
        await _storage.write(key: _tokenKey, value: newToken);
        print('Token refreshed successfully');
        return newToken;
      }
    } catch (e) {
      print('Token refresh error: $e');
    }
    
    return null;
  }
  
  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      final token = await getToken();
      if (token == null) {
        print('No auth token found');
        return false;
      }
      
      print('Making profile API call to check authentication');
      
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/auth/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      print('Auth check response status: ${response.statusCode}');
      
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Authentication check error: $e');
      return false;
    }
  }
  
  // Helper to save auth data
  Future<void> _saveAuthData(String token, String refreshToken, Map<String, dynamic> userData) async {
    print('Saving auth data to secure storage');
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.write(key: _userKey, value: jsonEncode(userData));
  }
  
  // Get user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }
      
      print('Making API call to get user profile');
      
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/auth/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      print('Profile API response status: ${response.statusCode}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        // Update stored user data
        await _storage.write(key: _userKey, value: jsonEncode(data));
        return {'success': true, 'data': data};
      } else {
        final data = jsonDecode(response.body);
        return {'success': false, 'message': data['msg'] ?? data['error'] ?? 'Failed to get profile'};
      }
    } catch (e) {
      print('Profile service error: $e');
      return {'success': false, 'message': 'Service error: $e'};
    }
  }
  
  // Change password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }
      
      final body = {
        'current_password': currentPassword,
        'new_password': newPassword,
      };
      
      print('Making API call to change password');
      
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(body),
      );
      
      print('Password change API response status: ${response.statusCode}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final data = jsonDecode(response.body);
        return {'success': false, 'message': data['msg'] ?? data['error'] ?? 'Password change failed'};
      }
    } catch (e) {
      print('Password change service error: $e');
      return {'success': false, 'message': 'Service error: $e'};
    }
  }
}