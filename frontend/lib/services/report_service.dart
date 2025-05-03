// lib/api/endpoints/report_api.dart
import '/api/client.dart';

class ReportApi {
  final ApiClient _client = ApiClient();

  /// Get dashboard data
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final response = await _client.get(
        endpoint: 'reports/dashboard',
      );

      return response;
    } catch (e) {
      return {'success': false, 'message': 'API error: $e'};
    }
  }

  /// Get monthly report data
  Future<Map<String, dynamic>> getMonthlyReport(int month, int year) async {
    try {
      final response = await _client.get(
        endpoint: 'reports/monthly',
        queryParams: {
          'month': month.toString(),
          'year': year.toString(),
        },
      );

      return response;
    } catch (e) {
      return {'success': false, 'message': 'API error: $e'};
    }
  }

  /// Get annual report data
  Future<Map<String, dynamic>> getAnnualReport(int year) async {
    try {
      final response = await _client.get(
        endpoint: 'reports/annual',
        queryParams: {
          'year': year.toString(),
        },
      );

      return response;
    } catch (e) {
      return {'success': false, 'message': 'API error: $e'};
    }
  }

  /// Get budget report data
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
      return {'success': false, 'message': 'API error: $e'};
    }
  }

  /// Get cashflow report data
  Future<Map<String, dynamic>> getCashflowReport({
    String? period,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (period != null) queryParams['period'] = period;
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final response = await _client.get(
        endpoint: 'reports/cashflow',
        queryParams: queryParams,
      );

      return response;
    } catch (e) {
      return {'success': false, 'message': 'API error: $e'};
    }
  }

  /// Export report data
  Future<Map<String, dynamic>> exportReport({
    required String reportType,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, String>{
        'report_type': reportType,
      };
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
        try {
          final data = response.body.isNotEmpty 
              ? await _client._handleResponse(response) 
              : {'message': 'Failed to export report'};
          return {'success': false, 'message': data['message'] ?? 'Failed to export report'};
        } catch (e) {
          return {'success': false, 'message': 'Failed to export report: $e'};
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'API error: $e'};
    }
  }

  // Helper method to extract filename from Content-Disposition header
  String? _getFilenameFromHeader(dynamic response) {
    final contentDisposition = response.headers['content-disposition'];
    if (contentDisposition != null && contentDisposition.contains('filename=')) {
      final filename = contentDisposition.split('filename=')[1];
      return filename.replaceAll('"', '').replaceAll(';', '');
    }
    return null;
  }
}