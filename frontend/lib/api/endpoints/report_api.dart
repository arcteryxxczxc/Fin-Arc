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

      final response = await _client.getRaw(
        endpoint: 'reports/export',
        queryParams: queryParams,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': response.bodyBytes,
          'content-type': response.headers['content-type'] ?? 'application/json',
          'filename': _getFilenameFromHeader(response) ?? 'report.json',
        };
      } else {
        Map<String, dynamic> data;
        try {
          data = jsonDecode(response.body);
        } catch (_) {
          data = {'msg': 'Failed to export report'};
        }
        return {'success': false, 'message': data['msg'] ?? 'Failed to export report'};
      }
    } catch (e) {
      print('API error exporting report: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Helper method to extract filename from Content-Disposition header
  String? _getFilenameFromHeader(http.Response response) {
    final contentDisposition = response.headers['content-disposition'];
    if (contentDisposition != null && contentDisposition.contains('filename=')) {
      final filename = contentDisposition.split('filename=')[1];
      return filename.replaceAll('"', '').replaceAll(';', '');
    }
    return null;
  }
}