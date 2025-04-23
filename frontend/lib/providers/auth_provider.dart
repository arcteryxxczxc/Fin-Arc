import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:finarc/utils/constants.dart';
import 'package:finarc/models/user.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  User? _user;
  final _storage = FlutterSecureStorage();
  
  bool get isAuth => _token != null;
  String? get token => _token;
  User? get user => _user;
  
  Future<bool> tryAutoLogin() async {
    final storedToken = await _storage.read(key: AppConstants.tokenKey);
    final storedUser = await _storage.read(key: AppConstants.userKey);
    
    if (storedToken == null || storedUser == null) {
      return false;
    }
    
    _token = storedToken;
    _user = User.fromJson(json.decode(storedUser));
    notifyListeners();
    return true;
  }
  
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );
      
      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200) {
        _token = responseData['access_token'];
        _user = User.fromJson(responseData['user']);
        
        await _storage.write(key: AppConstants.tokenKey, value: _token);
        await _storage.write(key: AppConstants.userKey, value: json.encode(_user!.toJson()));
        
        notifyListeners();
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': responseData['msg'] ?? 'Authentication failed'
        };
      }
    } catch (error) {
      return {
        'success': false,
        'message': 'Could not connect to server. Please check your internet connection.'
      };
    }
  }
  
  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );
      
      final responseData = json.decode(response.body);
      
      if (response.statusCode == 201) {
        _token = responseData['access_token'];
        _user = User.fromJson(responseData['user']);
        
        await _storage.write(key: AppConstants.tokenKey, value: _token);
        await _storage.write(key: AppConstants.userKey, value: json.encode(_user!.toJson()));
        
        notifyListeners();
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': responseData['msg'] ?? 'Registration failed'
        };
      }
    } catch (error) {
      return {
        'success': false,
        'message': 'Could not connect to server. Please check your internet connection.'
      };
    }
  }
  
  Future<void> logout() async {
    _token = null;
    _user = null;
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.userKey);
    notifyListeners();
  }
}