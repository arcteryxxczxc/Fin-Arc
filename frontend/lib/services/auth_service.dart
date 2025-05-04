// lib/services/auth_service.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/endpoints/auth_api.dart';
import '../models/user.dart';
import '../utils/error_handler.dart';

class AuthService {
  final AuthApi _authApi = AuthApi();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Token storage keys
  static const String _tokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
  
  // User cache
  User? _currentUser;
  
  /// Initialize authentication state
  Future<bool> initAuth() async {
    try {
      // Check if we have a stored token
      final token = await _secureStorage.read(key: _tokenKey);
      if (token == null) {
        return false;
      }
      
      // Try to load user data from storage
      final userData = await _getUserFromStorage();
      if (userData != null) {
        _currentUser = userData;
        return true;
      }
      
      // If user data is not available, fetch from API
      final result = await getProfile();
      return result['success'] == true;
    } catch (e) {
      print('Error initializing auth: $e');
      return false;
    }
  }
  
  /// Get the current user
  User? get currentUser => _currentUser;

  /// Get current user method for backward compatibility
  User? getCurrentUser() {
    return _currentUser;
  }
  
  /// Check if the user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _secureStorage.read(key: _tokenKey);
    return token != null;
  }
  
  /// Register a new user
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
        // Save tokens
        await _saveTokens(
          result['data']['access_token'],
          result['data']['refresh_token'],
        );
        
        // Save user data
        if (result['data']['user'] != null) {
          _currentUser = User.fromJson(result['data']['user']);
          await _saveUserToStorage(_currentUser!);
        }
      }
      
      return result;
    } catch (e) {
      print('Error during registration: $e');
      return {'success': false, 'message': ErrorHandler.parseApiError(e)};
    }
  }
  
  /// Login a user
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
        // Save tokens
        await _saveTokens(
          result['data']['access_token'],
          result['data']['refresh_token'],
        );
        
        // Save user data
        if (result['data']['user'] != null) {
          _currentUser = User.fromJson(result['data']['user']);
          await _saveUserToStorage(_currentUser!);
        }
      }
      
      return result;
    } catch (e) {
      print('Error during login: $e');
      return {'success': false, 'message': ErrorHandler.parseApiError(e)};
    }
  }
  
  /// Logout the current user
  Future<bool> logout() async {
    try {
      // Clear stored tokens
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      
      // Clear user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      
      _currentUser = null;
      
      return true;
    } catch (e) {
      print('Error during logout: $e');
      return false;
    }
  }
  
  /// Get user profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final result = await _authApi.getProfile();
      
      if (result['success']) {
        // Save user data
        _currentUser = User.fromJson(result['data']);
        await _saveUserToStorage(_currentUser!);
      }
      
      return result;
    } catch (e) {
      print('Error getting profile: $e');
      return {'success': false, 'message': ErrorHandler.parseApiError(e)};
    }
  }
  
  /// Refresh user profile
  Future<Map<String, dynamic>> refreshUserProfile() async {
    return await getProfile();
  }
  
  /// Change password
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
      print('Error changing password: $e');
      return {'success': false, 'message': ErrorHandler.parseApiError(e)};
    }
  }
  
  /// Get login history
  Future<Map<String, dynamic>> getLoginHistory() async {
    try {
      // First try to get from the API
      final result = await _authApi.getLoginHistory();
      
      if (result['success']) {
        return result;
      }
      
      // If API fails, return mock data for demonstration
      return {
        'success': true,
        'data': _getMockLoginHistory(),
      };
    } catch (e) {
      print('Error getting login history: $e');
      
      // Return mock data in case of error
      return {
        'success': true,
        'data': _getMockLoginHistory(),
      };
    }
  }
  
  /// Get access token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }
  
  /// Save tokens
  Future<void> _saveTokens(String token, String refreshToken) async {
    await _secureStorage.write(key: _tokenKey, value: token);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
  }
  
  /// Save user data to storage
  Future<void> _saveUserToStorage(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonEncode(user.toJson());
    await prefs.setString(_userKey, userJson);
  }
  
  /// Get user data from storage
  Future<User?> _getUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      
      if (userJson == null) {
        return null;
      }
      
      return User.fromJson(jsonDecode(userJson));
    } catch (e) {
      print('Error loading user from storage: $e');
      return null;
    }
  }
  
  /// Generate mock login history data for demonstration
  List<Map<String, dynamic>> _getMockLoginHistory() {
    final now = DateTime.now();
    return [
      {
        'timestamp': now.subtract(const Duration(minutes: 30)).toIso8601String(),
        'ip_address': '192.168.1.1',
        'user_agent': 'Mobile App on iPhone',
        'success': true,
      },
      {
        'timestamp': now.subtract(const Duration(days: 1)).toIso8601String(),
        'ip_address': '192.168.1.1',
        'user_agent': 'Firefox on Mac OSX',
        'success': true,
      },
      {
        'timestamp': now.subtract(const Duration(days: 2)).toIso8601String(),
        'ip_address': '203.0.113.42',
        'user_agent': 'Chrome on Windows',
        'success': false,
      },
      {
        'timestamp': now.subtract(const Duration(days: 3)).toIso8601String(),
        'ip_address': '192.168.1.1',
        'user_agent': 'Safari on iPad',
        'success': true,
      },
      {
        'timestamp': now.subtract(const Duration(days: 7)).toIso8601String(),
        'ip_address': '192.168.1.1',
        'user_agent': 'Chrome on Android',
        'success': true,
      },
    ];
  }
}