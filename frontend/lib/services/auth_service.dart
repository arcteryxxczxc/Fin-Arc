import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import '../api/endpoints/auth_api.dart';

class AuthService {
  final AuthApi _authApi = AuthApi();
  
  // Secure storage for tokens
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  
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
      final result = await _authApi.register(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      
      if (result['success']) {
        // Save token and user data to secure storage
        final data = result['data'];
        await _saveAuthData(data['access_token'], data['refresh_token'], data['user']);
      }
      
      return result;
    } catch (e) {
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
      
      if (result['success']) {
        // Save token and user data to secure storage
        final data = result['data'];
        await _saveAuthData(data['access_token'], data['refresh_token'], data['user']);
      }
      
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Service error: $e'};
    }
  }
  
  // Logout user
  Future<void> logout() async {
    try {
      // Call logout endpoint to invalidate token on server
      await _authApi.logout();
    } catch (e) {
      // Even if server logout fails, clear local storage
      print('Logout error: $e');
    } finally {
      // Clear tokens from secure storage
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _userKey);
    }
  }
  
  // Get current user data
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
      final result = await _authApi.refreshToken(refreshToken);
      
      if (result['success']) {
        final newToken = result['data']['access_token'];
        await _storage.write(key: _tokenKey, value: newToken);
        return newToken;
      }
    } catch (e) {
      print('Token refresh error: $e');
    }
    
    return null;
  }
  
  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    if (token == null) return false;
    
    try {
      final result = await _authApi.getUserProfile();
      return result['success'];
    } catch (e) {
      print('Authentication check error: $e');
      return false;
    }
  }
  
  // Helper to save auth data
  Future<void> _saveAuthData(String token, String refreshToken, Map<String, dynamic> userData) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.write(key: _userKey, value: jsonEncode(userData));
  }
  
  // Get user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final result = await _authApi.getUserProfile();
      
      if (result['success']) {
        // Update stored user data
        await _storage.write(key: _userKey, value: jsonEncode(result['data']));
      }
      
      return result;
    } catch (e) {
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
      
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Service error: $e'};
    }
  }
}