// lib/services/report_service.dart
import '../api/endpoints/report_api.dart';

class ReportService {
  final ReportApi _reportApi = ReportApi();

  /// Get dashboard data
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      return await _reportApi.getDashboardData();
    } catch (e) {
      print('Error getting dashboard data: $e');
      return {'success': false, 'message': 'Service error: $e'};
    }
  }

  /// Get monthly report data
  Future<Map<String, dynamic>> getMonthlyReport(int month, int year) async {
    try {
      return await _reportApi.getMonthlyReport(month, year);
    } catch (e) {
      print('Error getting monthly report: $e');
      return {'success': false, 'message': 'Service error: $e'};
    }
  }

  /// Get annual report data
  Future<Map<String, dynamic>> getAnnualReport({required int year}) async {
    try {
      return await _reportApi.getAnnualReport(year);
    } catch (e) {
      print('Error getting annual report: $e');
      return {'success': false, 'message': 'Service error: $e'};
    }
  }

  /// Get budget report data
  Future<Map<String, dynamic>> getBudgetReport({int? month, int? year}) async {
    try {
      return await _reportApi.getBudgetReport(month: month, year: year);
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
      return await _reportApi.getCashflowReport(
        period: period,
        startDate: startDate,
        endDate: endDate,
      );
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
      final result = await _reportApi.exportReport(
        reportType: reportType,
        startDate: startDate,
        endDate: endDate,
      );
      
      return result;
    } catch (e) {
      print('Error exporting report: $e');
      return {'success': false, 'message': 'Service error: $e'};
    }
  }
}