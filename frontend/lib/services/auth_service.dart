// lib/services/auth_service.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
        
        // Validate response data
        if (!_validateAuthResponse(data)) {
          return {
            'success': false, 
            'message': 'Invalid authentication response from server'
          };
        }
        
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
        
        // Validate response data
        if (!_validateAuthResponse(data)) {
          return {
            'success': false, 
            'message': 'Invalid authentication response from server'
          };
        }
        
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
  
  // Validate authentication response
  bool _validateAuthResponse(Map<String, dynamic> data) {
    // Check required fields
    if (!data.containsKey('access_token') || 
        !data.containsKey('refresh_token') || 
        !data.containsKey('user')) {
      print('Invalid auth response: missing required fields');
      return false;
    }
    
    // Verify user data is a map
    if (!(data['user'] is Map)) {
      print('Invalid auth response: user is not a map');
      return false;
    }
    
    // Verify token values are strings
    if (!(data['access_token'] is String) || !(data['refresh_token'] is String)) {
      print('Invalid auth response: tokens are not strings');
      return false;
    }
    
    return true;
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
        final userMap = jsonDecode(userData);
        if (userMap is Map<String, dynamic>) {
          return User.fromJson(userMap);
        } else {
          print('User data is not a valid map: $userMap');
          return null;
        }
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
    if (refreshToken == null) {
      print('No refresh token available');
      return null;
    }
    
    try {
      print('Attempting to refresh token');
      
      final result = await _authApi.refreshToken(refreshToken);
      
      print('Token refresh result: ${result['success']}');
      
      if (result['success']) {
        final data = result['data'];
        if (!data.containsKey('access_token')) {
          print('Refresh token response missing access_token');
          return null;
        }
        
        final newToken = data['access_token'];
        await _storage.write(key: _tokenKey, value: newToken);
        
        // Update refresh token if provided
        if (data.containsKey('refresh_token')) {
          await _storage.write(key: _refreshTokenKey, value: data['refresh_token']);
        }
        
        // Update user data if provided
        if (data.containsKey('user')) {
          await _storage.write(key: _userKey, value: jsonEncode(data['user']));
        }
        
        print('Token refreshed successfully');
        return newToken;
      } else {
        print('Token refresh failed: ${result['message']}');
        // Clear tokens if refresh explicitly failed (not for network errors)
        if (result.containsKey('statusCode')) {
          await _storage.delete(key: _tokenKey);
          await _storage.delete(key: _refreshTokenKey);
        }
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
      
      if (result['success']) {
        // Update stored user data if profile call succeeds
        if (result.containsKey('data') && result['data'] != null) {
          await _storage.write(key: _userKey, value: jsonEncode(result['data']));
        }
        return true;
      }
      
      return false;
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
        if (result.containsKey('data') && result['data'] != null) {
          await _storage.write(key: _userKey, value: jsonEncode(result['data']));
          return {'success': true, 'data': result['data']};
        } else {
          return {'success': false, 'message': 'Invalid profile data received'};
        }
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