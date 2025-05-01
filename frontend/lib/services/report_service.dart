import '../api/endpoints/report_api.dart';

class ReportService {
  final ReportApi _reportApi = ReportApi();

  // Get dashboard data with summary and trends
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final result = await _reportApi.getDashboardData();
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Service error: $e'};
    }
  }

  // Get monthly report data
  Future<Map<String, dynamic>> getMonthlyReport(int month, int year) async {
    try {
      final result = await _reportApi.getMonthlyReport(month, year);
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Service error: $e'};
    }
  }

  // Get annual report data
  Future<Map<String, dynamic>> getAnnualReport(int year) async {
    try {
      final result = await _reportApi.getAnnualReport(year);
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Service error: $e'};
    }
  }

  // Get budget report data
  Future<Map<String, dynamic>> getBudgetReport({int? month, int? year}) async {
    try {
      final result = await _reportApi.getBudgetReport(
        month: month,
        year: year,
      );
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Service error: $e'};
    }
  }

  // Get cash flow report data
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
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Service error: $e'};
    }
  }

  // Export report data as CSV or PDF
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
      return {'success': false, 'message': 'Service error: $e'};
    }
  }
}