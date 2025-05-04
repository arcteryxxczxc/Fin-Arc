// lib/services/report_service.dart
import 'dart:typed_data';
import '../api/endpoints/report_api.dart';

class ReportService {
  final ReportApi _reportApi = ReportApi();

  /// Get dashboard data
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final result = await _reportApi.getDashboardData();
      
      // Debug output for response format
      print('Dashboard data response: ${result.toString().substring(0, 
            result.toString().length > 200 ? 200 : result.toString().length)}...');
      
      return result;
    } catch (e) {
      print('Error getting dashboard data: $e');
      return {'success': false, 'message': 'Service error: $e'};
    }
  }

  /// Get monthly report data
  Future<Map<String, dynamic>> getMonthlyReport(int month, int year) async {
    try {
      final result = await _reportApi.getMonthlyReport(month, year);
      
      // Debug output for response format
      print('Monthly report response: ${result.toString().substring(0, 
            result.toString().length > 200 ? 200 : result.toString().length)}...');
            
      return result;
    } catch (e) {
      print('Error getting monthly report: $e');
      return {'success': false, 'message': 'Service error: $e'};
    }
  }

  /// Get annual report data
  Future<Map<String, dynamic>> getAnnualReport({required int year}) async {
    try {
      final result = await _reportApi.getAnnualReport(year);
      
      // Debug output for response format
      print('Annual report response: ${result.toString().substring(0, 
            result.toString().length > 200 ? 200 : result.toString().length)}...');
            
      return result;
    } catch (e) {
      print('Error getting annual report: $e');
      return {'success': false, 'message': 'Service error: $e'};
    }
  }

  /// Get budget report data
  Future<Map<String, dynamic>> getBudgetReport({int? month, int? year}) async {
    try {
      final result = await _reportApi.getBudgetReport(month: month, year: year);
      
      // Debug output for response format
      print('Budget report response: ${result.toString().substring(0, 
            result.toString().length > 200 ? 200 : result.toString().length)}...');
            
      return result;
    } catch (e) {
      print('Error getting budget report: $e');
      return {'success': false, 'message': 'Service error: $e'};
    }
  }

  /// Get cashflow report data
  Future<Map<String, dynamic>> getCashFlowReport({
    String period = 'month',
    String? startDate,
    String? endDate,
  }) async {
    try {
      final result = await _reportApi.getCashflowReport(
        period: period,
        startDate: startDate,
        endDate: endDate,
      );
      
      // Debug output for response format
      print('Cashflow report response: ${result.toString().substring(0, 
            result.toString().length > 200 ? 200 : result.toString().length)}...');
            
      return result;
    } catch (e) {
      print('Error getting cashflow report: $e');
      return {'success': false, 'message': 'Service error: $e'};
    }
  }

  /// Export report data
  Future<Map<String, dynamic>> exportReport({
    required String reportType,
    String? startDate,
    String? endDate,
  }) async {
    try {
      print('Exporting report of type: $reportType');
      if (startDate != null && endDate != null) {
        print('Date range: $startDate to $endDate');
      }
      
      final result = await _reportApi.exportReport(
        reportType: reportType,
        startDate: startDate,
        endDate: endDate,
      );
      
      // Process the result
      if (result['success']) {
        // If export was successful
        print('Export successful');
        
        // Verify data is available and is Uint8List
        if (!result.containsKey('data')) {
          print('No data returned in successful export');
          return {'success': false, 'message': 'No data returned from server'};
        }
        
        final data = result['data'];
        if (data is! Uint8List) {
          print('Returned data is not Uint8List: ${data.runtimeType}');
          return {'success': false, 'message': 'Invalid data format returned'};
        }
        
        // Return the full result
        return result;
      } else {
        // Log the error details
        if (result.containsKey('message')) {
          print('Export failed: ${result['message']}');
        } else {
          print('Export failed with no error message');
        }
        
        return result;
      }
    } catch (e) {
      print('Error exporting report: $e');
      return {'success': false, 'message': 'Service error: $e'};
    }
  }
}