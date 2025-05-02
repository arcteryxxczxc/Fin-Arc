// lib/services/auth_service.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../utils/constants.dart';
import '../api/endpoints/auth_api.dart';

class AuthService {
  // Secure storage for tokens
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  
  // Token storage keys
  static const String _tokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
  
  // Create API client instance
  final AuthApi _authApi = AuthApi();
  
  // Register a new user
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final result = await _authApi.register(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );

      print('Registration service result: ${result['success']}');
      
      if (result['success']) {
        final data = result['data'];
        // Save token and user data to secure storage
        await _saveAuthData(data['access_token'], data['refresh_token'], data['user']);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': result['message'] ?? 'Registration failed'};
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
      final result = await _authApi.login(
        username: username,
        password: password,
      );

      print('Login service result: ${result['success']}');
      
      if (result['success']) {
        final data = result['data'];
        // Save token and user data to secure storage
        await _saveAuthData(data['access_token'], data['refresh_token'], data['user']);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': result['message'] ?? 'Login failed'};
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
        await _authApi.logout();
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
      
      final result = await _authApi.refreshToken(refreshToken);
      
      print('Token refresh result: ${result['success']}');
      
      if (result['success']) {
        final data = result['data'];
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
      
      final result = await _authApi.getUserProfile();
      print('Auth check result: ${result['success']}');
      
      return result['success'] == true;
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
      final result = await _authApi.getUserProfile();
      
      print('Profile API result: ${result['success']}');
      
      if (result['success']) {
        // Update stored user data
        await _storage.write(key: _userKey, value: jsonEncode(result['data']));
        return {'success': true, 'data': result['data']};
      } else {
        return {'success': false, 'message': result['message'] ?? 'Failed to get profile'};
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
      final result = await _authApi.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      
      print('Password change result: ${result['success']}');
      
      return result;
    } catch (e) {
      print('Password change service error: $e');
      return {'success': false, 'message': 'Service error: $e'};
    }
  }
}