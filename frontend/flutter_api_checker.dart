import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// A utility class to verify API connectivity for the Fin-Arc app
class ApiConnectionChecker {
  final String baseUrl;
  
  ApiConnectionChecker(this.baseUrl);
  
  Future<void> checkApiConnection() async {
    print('\n========== API Connection Test ==========\n');
    print('Testing connection to: $baseUrl');
    
    try {
      // 1. Test basic connectivity
      await _testServerConnectivity();
      
      // 2. Test authentication endpoints
      await _testAuthEndpoints();
      
      print('\n✅ API connection tests completed successfully!\n');
    } catch (e) {
      print('\n❌ API connection tests failed: $e\n');
      _printTroubleshootingGuide();
    }
  }
  
  Future<void> _testServerConnectivity() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl'));
      
      print('Basic connectivity: ${response.statusCode}');
      if (response.statusCode == 404) {
        print('✅ Base endpoint returns 404 as expected');
      } else {
        print('⚠️ Base endpoint returned ${response.statusCode}, expected 404');
      }
    } catch (e) {
      print('❌ Failed to connect to server: $e');
      throw Exception('Server connectivity test failed. Is the server running?');
    }
  }
  
  Future<void> _testAuthEndpoints() async {
    try {
      // Test registration
      final testUsername = 'flutter_test_${DateTime.now().millisecondsSinceEpoch}';
      
      print('\nTesting user registration...');
      final registerResponse = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': testUsername,
          'email': '$testUsername@gmail.com',
          'password': 'Test12345!',
          'first_name': 'Flutter',
          'last_name': 'Tester'
        }),
      );
      
      if (registerResponse.statusCode == 201) {
        print('✅ Registration endpoint working');
        
        // Extract tokens
        final registerData = jsonDecode(registerResponse.body);
        final accessToken = registerData['access_token'];
        final refreshToken = registerData['refresh_token'];
        
        if (accessToken == null || refreshToken == null) {
          throw Exception('Missing tokens in registration response');
        }
        
        // Test profile
        print('\nTesting profile endpoint...');
        final profileResponse = await http.get(
          Uri.parse('$baseUrl/auth/profile'),
          headers: {'Authorization': 'Bearer $accessToken'},
        );
        
        if (profileResponse.statusCode == 200) {
          print('✅ Profile endpoint working');
          
          // Test token refresh
          print('\nTesting token refresh...');
          final refreshResponse = await http.post(
            Uri.parse('$baseUrl/auth/refresh'),
            headers: {'Authorization': 'Bearer $refreshToken'},
          );
          
          if (refreshResponse.statusCode == 200) {
            print('✅ Token refresh endpoint working');
            
            // Test logout
            print('\nTesting logout endpoint...');
            final logoutResponse = await http.post(
              Uri.parse('$baseUrl/auth/logout'),
              headers: {'Authorization': 'Bearer $accessToken'},
            );
            
            if (logoutResponse.statusCode == 200) {
              print('✅ Logout endpoint working');
            } else {
              print('❌ Logout endpoint returned ${logoutResponse.statusCode}');
              print('Response: ${logoutResponse.body}');
              throw Exception('Logout test failed');
            }
          } else {
            print('❌ Token refresh endpoint returned ${refreshResponse.statusCode}');
            print('Response: ${refreshResponse.body}');
            throw Exception('Token refresh test failed');
          }
        } else {
          print('❌ Profile endpoint returned ${profileResponse.statusCode}');
          print('Response: ${profileResponse.body}');
          throw Exception('Profile test failed');
        }
      } else if (registerResponse.statusCode == 409) {
        print('⚠️ User already exists (status 409) - this is acceptable');
        print('Testing login endpoint...');
        
        // Test login
        final loginResponse = await http.post(
          Uri.parse('$baseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': 'test_user',
            'password': 'password123'
          }),
        );
        
        if (loginResponse.statusCode == 200) {
          print('✅ Login endpoint working');
        } else {
          print('❌ Login endpoint returned ${loginResponse.statusCode}');
          print('Response: ${loginResponse.body}');
          throw Exception('Login test failed');
        }
      } else {
        print('❌ Registration endpoint returned ${registerResponse.statusCode}');
        print('Response: ${registerResponse.body}');
        throw Exception('Registration test failed');
      }
    } catch (e) {
      print('❌ Auth endpoints test failed: $e');
      throw Exception('Authentication endpoints test failed');
    }
  }
  
  void _printTroubleshootingGuide() {
    print('\n========== Troubleshooting Guide ==========\n');
    print('1. Make sure the Flask server is running:');
    print('   - Navigate to the backend directory');
    print('   - Run: python run.py');
    print('\n2. Check your baseUrl in constants.dart:');
    print('   - For Android emulator: http://10.0.2.2:5000/api');
    print('   - For iOS simulator or web: http://localhost:5000/api');
    print('\n3. Check CORS settings in the Flask app:');
    print('   - Make sure your Flutter app origin is allowed');
    print('\n4. Make sure PostgreSQL is running and configured correctly:');
    print('   - Check your .env file in the backend directory');
    print('   - Verify your PostgreSQL credentials');
    print('\n5. Run the backend diagnostic script:');
    print('   - python flask_diagnostic.py');
    print('\n=========================================\n');
  }
}

void main() async {
  // Test with different base URLs
  final urls = [
    'http://localhost:5000/api',
    'http://10.0.2.2:5000/api'
  ];
  
  bool success = false;
  
  for (final url in urls) {
    try {
      final checker = ApiConnectionChecker(url);
      await checker.checkApiConnection();
      success = true;
      print('\n✅ Successfully connected to: $url');
      print('Use this URL in your app configuration.');
      break;
    } catch (e) {
      print('\n❌ Failed to connect to: $url');
      print('Error: $e');
    }
  }
  
  if (!success) {
    print('\n❌ Could not connect to any API server.');
    print('Please make sure your backend is running and properly configured.');
  }
  
  exit(success ? 0 : 1);
}