// lib/api/endpoints/report_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';
import '../client.dart';

class ReportApi {
  final ApiClient _client = ApiClient();
  final String baseUrl = AppConstants.baseUrl;

  /// Get dashboard data
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final response = await _client.get(
        endpoint: 'reports/dashboard',
      );

      return response;
    } catch (e) {
      print('API error getting dashboard data: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Get monthly report
  Future<Map<String, dynamic>> getMonthlyReport(int month, int year) async {
    try {
      final queryParams = {
        'month': month.toString(),
        'year': year.toString(),
      };

      final response = await _client.get(
        endpoint: 'reports/monthly',
        queryParams: queryParams,
      );

      // Log the response for debugging
      print('Monthly report API response: ${response.toString().substring(0, 
            response.toString().length > 200 ? 200 : response.toString().length)}...');

      return response;
    } catch (e) {
      print('API error getting monthly report: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Get annual report
  Future<Map<String, dynamic>> getAnnualReport(int year) async {
    try {
      final queryParams = {
        'year': year.toString(),
      };

      final response = await _client.get(
        endpoint: 'reports/annual',
        queryParams: queryParams,
      );

      return response;
    } catch (e) {
      print('API error getting annual report: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Get budget report
  Future<Map<String, dynamic>> getBudgetReport({int? month, int? year}) async {
    try {
      final queryParams = <String, String>{};
      if (month != null) queryParams['month'] = month.toString();
      if (year != null) queryParams['year'] = year.toString();

      final response = await _client.get(
        endpoint: 'reports/budget',
        queryParams: queryParams,
      );

      return response;
    } catch (e) {
      print('API error getting budget report: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Get cashflow report
  Future<Map<String, dynamic>> getCashflowReport({
    String period = 'month',
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = {
        'period': period,
      };

      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final response = await _client.get(
        endpoint: 'reports/cashflow',
        queryParams: queryParams,
      );

      return response;
    } catch (e) {
      print('API error getting cashflow report: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Export report data
  Future<Map<String, dynamic>> exportReport({
    required String reportType,
    String? startDate,
    String? endDate,
  }) async {
    try {
      // Build query parameters
      final queryParams = {'type': reportType};
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      print('Exporting report with params: $queryParams');

      try {
        final response = await _client.getRaw(
          endpoint: 'reports/export',
          queryParams: queryParams,
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          // Get filename from header or use default
          final filename = _getFilenameFromHeader(response) ?? 'report_$reportType.csv';
          
          // Return success with binary data
          return {
            'success': true,
            'data': response.bodyBytes,
            'content-type': response.headers['content-type'] ?? 'application/octet-stream',
            'filename': filename,
          };
        } else {
          // Try to parse error message from JSON response
          Map<String, dynamic> errorData;
          try {
            errorData = jsonDecode(response.body);
            return {'success': false, 'message': errorData['message'] ?? errorData['msg'] ?? 'Export failed'};
          } catch (_) {
            // If not JSON, return the status code and preview of the response
            final preview = response.body.length > 100 
                ? response.body.substring(0, 100) 
                : response.body;
            return {
              'success': false, 
              'message': 'Export failed with status ${response.statusCode}: $preview'
            };
          }
        }
      } catch (e) {
        print('HTTP error during export: $e');
        return {'success': false, 'message': 'Network error during export: $e'};
      }
    } catch (e) {
      print('API error exporting report: $e');
      return {'success': false, 'message': 'Error preparing export request: $e'};
    }
  }

  // Helper method to extract filename from Content-Disposition header
  String? _getFilenameFromHeader(http.Response response) {
    final contentDisposition = response.headers['content-disposition'];
    if (contentDisposition != null) {
      // Try different formats of Content-Disposition
      if (contentDisposition.contains('filename=')) {
        final parts = contentDisposition.split('filename=');
        if (parts.length > 1) {
          final filename = parts[1].trim()
                          .replaceAll('"', '')
                          .replaceAll("'", '')
                          .replaceAll(';', '');
          return filename;
        }
      } else if (contentDisposition.contains('filename*=')) {
        // Handle extended format: filename*=UTF-8''filename.ext
        final parts = contentDisposition.split("filename*=");
        if (parts.length > 1) {
          final filenameEncoded = parts[1].split("''");
          if (filenameEncoded.length > 1) {
            return Uri.decodeComponent(filenameEncoded[1].replaceAll(';', ''));
          }
        }
      }
    }
    return null;
  }
}