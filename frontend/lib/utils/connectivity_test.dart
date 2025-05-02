// lib/utils/connectivity_test.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';

/// Utility class for testing API connectivity and debugging CORS issues
class ConnectivityTest {
  /// Test basic connectivity to the backend API
  static Future<Map<String, dynamic>> testApiConnectivity() async {
    final results = <String, dynamic>{};
    
    try {
      // Test 1: Basic GET request to health endpoint
      results['health_test'] = await _testHealthEndpoint();
      
      // Test 2: Check if CORS is properly configured
      results['cors_test'] = await _testCorsConfig();
      
      // Test 3: Test authentication endpoints
      results['auth_test'] = await _testAuthEndpoints();
      
      // Overall result
      results['success'] = results.values.every((test) => 
        test is Map && test['success'] == true
      );
    } catch (e) {
      print('Connection test error: $e');
      results['success'] = false;
      results['error'] = e.toString();
    }
    
    return results;
  }

  /// Test the health endpoint
  static Future<Map<String, dynamic>> _testHealthEndpoint() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/health'),
        headers: {'Accept': 'application/json'},
      );
      
      return {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'status_code': response.statusCode,
        'body': response.body,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Test CORS configuration
  static Future<Map<String, dynamic>> _testCorsConfig() async {
    try {
      // Simulate preflight with a normal request since http package doesn't have OPTIONS
      // We'll check for CORS headers in the response
      
      // First, create a request that will receive CORS headers
      final corsTestUrl = '${AppConstants.baseUrl}/auth/login';
      
      // Using POST to simulate what would happen after preflight
      final response = await http.post(
        Uri.parse(corsTestUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Origin': 'http://localhost:8080',
        },
        // Send an empty body to avoid validation errors
        body: jsonEncode({}),
      );
      
      // Check for CORS headers
      final hasCorsHeaders = response.headers.containsKey('access-control-allow-origin') ||
                          response.headers.containsKey('Access-Control-Allow-Origin');
      
      return {
        'success': hasCorsHeaders,
        'test_status': response.statusCode,
        'has_cors_headers': hasCorsHeaders,
        'cors_headers': response.headers,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Test authentication endpoints
  static Future<Map<String, dynamic>> _testAuthEndpoints() async {
    try {
      // Simple POST to login endpoint (will fail but should return proper error)
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': 'test_user',
          'password': 'wrong_password'
        }),
      );
      
      // We expect a 401 Unauthorized or at minimum a valid JSON response
      bool isValidJson = false;
      try {
        final data = jsonDecode(response.body);
        isValidJson = data != null;
      } catch (_) {
        isValidJson = false;
      }
      
      return {
        'success': isValidJson,
        'status_code': response.statusCode,
        'is_valid_json': isValidJson,
        'response_size': response.body.length,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Run all tests and return a formatted report
  static Future<String> generateReport() async {
    final results = await testApiConnectivity();
    final buffer = StringBuffer();
    
    buffer.writeln('CONNECTIVITY TEST REPORT');
    buffer.writeln('========================');
    buffer.writeln('API URL: ${AppConstants.baseUrl}');
    buffer.writeln('Timestamp: ${DateTime.now()}');
    buffer.writeln('');
    
    buffer.writeln('OVERALL RESULT: ${results['success'] ? 'SUCCESS ✅' : 'FAILED ❌'}');
    if (results.containsKey('error')) {
      buffer.writeln('Error: ${results['error']}');
    }
    buffer.writeln('');
    
    // Health Endpoint Test
    if (results.containsKey('health_test')) {
      final healthTest = results['health_test'];
      buffer.writeln('Health Endpoint Test: ${healthTest['success'] ? 'SUCCESS ✅' : 'FAILED ❌'}');
      if (healthTest.containsKey('status_code')) {
        buffer.writeln('  Status Code: ${healthTest['status_code']}');
      }
      if (healthTest.containsKey('error')) {
        buffer.writeln('  Error: ${healthTest['error']}');
      }
      buffer.writeln('');
    }
    
    // CORS Test
    if (results.containsKey('cors_test')) {
      final corsTest = results['cors_test'];
      buffer.writeln('CORS Configuration Test: ${corsTest['success'] ? 'SUCCESS ✅' : 'FAILED ❌'}');
      if (corsTest.containsKey('test_status')) {
        buffer.writeln('  Response Status: ${corsTest['test_status']}');
      }
      if (corsTest.containsKey('has_cors_headers')) {
        buffer.writeln('  Has CORS Headers: ${corsTest['has_cors_headers']}');
      }
      if (corsTest.containsKey('error')) {
        buffer.writeln('  Error: ${corsTest['error']}');
      }
      buffer.writeln('');
    }
    
    // Auth Test
    if (results.containsKey('auth_test')) {
      final authTest = results['auth_test'];
      buffer.writeln('Authentication Endpoints Test: ${authTest['success'] ? 'SUCCESS ✅' : 'FAILED ❌'}');
      if (authTest.containsKey('status_code')) {
        buffer.writeln('  Status Code: ${authTest['status_code']}');
      }
      if (authTest.containsKey('is_valid_json')) {
        buffer.writeln('  Valid JSON Response: ${authTest['is_valid_json']}');
      }
      if (authTest.containsKey('error')) {
        buffer.writeln('  Error: ${authTest['error']}');
      }
      buffer.writeln('');
    }
    
    // Recommendations
    buffer.writeln('RECOMMENDATIONS:');
    if (!results['success']) {
      if (results.containsKey('health_test') && !results['health_test']['success']) {
        buffer.writeln('- Check if backend server is running at ${AppConstants.baseUrl}');
        buffer.writeln('- Verify network connectivity between frontend and backend');
        buffer.writeln('- Check for firewall or proxy blocking requests');
      }
      
      if (results.containsKey('cors_test') && !results['cors_test']['success']) {
        buffer.writeln('- Backend CORS configuration needs to be fixed:');
        buffer.writeln('  * Ensure Flask-CORS is properly installed and configured');
        buffer.writeln('  * Add your frontend origin to the allowed origins list');
        buffer.writeln('  * Make sure OPTIONS requests are handled correctly');
        buffer.writeln('  * Add appropriate CORS headers to responses');
      }
      
      if (results.containsKey('auth_test') && !results['auth_test']['success']) {
        buffer.writeln('- Authentication endpoints are not responding correctly:');
        buffer.writeln('  * Check request format and content type');
        buffer.writeln('  * Verify JSON schemas match between frontend and backend');
        buffer.writeln('  * Look for server-side errors in backend logs');
      }
    } else {
      buffer.writeln('- All tests passed! The API appears to be configured correctly.');
    }
    
    return buffer.toString();
  }
}