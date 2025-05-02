import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _initialized = false; // Track initialization status
  
  // Getters
  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get initialized => _initialized;
  
  // Initialize auth state on app start
  Future<void> initAuth() async {
    // Skip if already initialized to prevent infinite loops
    if (_initialized && !_isLoading) return;
    
    print('Starting auth initialization');
    _isLoading = true;
    notifyListeners();
    
    try {
      print('Checking if authenticated');
      final isAuth = await _authService.isAuthenticated();
      print('isAuthenticated result: $isAuth');
      
      if (isAuth) {
        print('Getting current user info');
        _user = await _authService.getCurrentUser();
        print('User retrieved: ${_user?.username}');
      } else {
        print('User is not authenticated');
      }
      
      _initialized = true;
    } catch (e) {
      print('Auth initialization error: $e');
      _error = e.toString();
      _initialized = true; // Still mark as initialized even if there's an error
    } finally {
      _isLoading = false;
      notifyListeners();
      print('Auth initialization complete. Authenticated: ${_user != null}');
    }
  }
  
  // Register new user
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    print('Starting registration process for user: $username');
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _authService.register(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      
      print('Registration result: ${result['success']}');
      
      if (result['success']) {
        _user = await _authService.getCurrentUser();
        print('User successfully registered and logged in: ${_user?.username}');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['message'];
        print('Registration failed: $_error');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      print('Registration error: $_error');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Login user
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    print('Starting login process for user: $username');
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _authService.login(
        username: username,
        password: password,
      );
      
      print('Login result: ${result['success']}');
      
      if (result['success']) {
        _user = await _authService.getCurrentUser();
        print('User successfully logged in: ${_user?.username}');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['message'];
        print('Login failed: $_error');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      print('Login error: $_error');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Logout user
  Future<void> logout() async {
    print('Starting logout process');
    _isLoading = true;
    notifyListeners();
    
    try {
      await _authService.logout();
      _user = null;
      print('User successfully logged out');
    } catch (e) {
      print('Logout error: $e');
      // Still log out locally even if the server request fails
      _user = null;
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    print('Starting password change process');
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      
      _isLoading = false;
      
      if (result['success']) {
        print('Password changed successfully');
        notifyListeners();
        return true;
      } else {
        _error = result['message'];
        print('Password change failed: $_error');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      print('Password change error: $_error');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Get fresh user profile data
  Future<void> refreshUserProfile() async {
    print('Refreshing user profile');
    try {
      final result = await _authService.getUserProfile();
      
      if (result['success']) {
        _user = User.fromJson(result['data']);
        print('User profile refreshed successfully: ${_user?.username}');
        notifyListeners();
      } else {
        _error = result['message'];
        print('Failed to refresh profile: $_error');
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      print('Error refreshing profile: $_error');
      notifyListeners();
    }
  }
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // Reset initialization state (useful for testing)
  void resetInitialization() {
    _initialized = false;
  }
}