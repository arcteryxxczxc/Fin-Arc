// lib/services/report_service.dart
import '/api/endpoints/report_api.dart';

class ReportService {
  final ReportApi _reportApi = ReportApi();

  // Get dashboard data
  Future<Map<String, dynamic>> getDashboardData() async {
    return await _reportApi.getDashboardData();
  }

  // Get monthly report data
  Future<Map<String, dynamic>> getMonthlyReport(int month, int year) async {
    return await _reportApi.getMonthlyReport(month, year);
  }

  // Get annual report data
  Future<Map<String, dynamic>> getAnnualReport({required int year}) async {
    return await _reportApi.getAnnualReport(year);
  }

  // Get budget report data
  Future<Map<String, dynamic>> getBudgetReport({int? month, int? year}) async {
    return await _reportApi.getBudgetReport(month: month, year: year);
  }

  // Get cashflow report data
  Future<Map<String, dynamic>> getCashFlowReport({
    String? period,
    String? startDate,
    String? endDate,
  }) async {
    return await _reportApi.getCashflowReport(
      period: period !,
      startDate: startDate,
      endDate: endDate,
    );
  }

  // Export report data
  Future<Map<String, dynamic>> exportReport({
    required String reportType,
    String? startDate,
    String? endDate,
  }) async {
    return await _reportApi.exportReport(
      reportType: reportType,
      startDate: startDate,
      endDate: endDate,
    );
  }
}