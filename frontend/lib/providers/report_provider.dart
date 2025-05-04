// lib/providers/report_provider.dart
import 'package:flutter/foundation.dart';
import '../services/report_service.dart';

class ReportProvider with ChangeNotifier {
  final ReportService _reportService = ReportService();
  
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _monthlyData;
  Map<String, dynamic>? _annualData;
  Map<String, dynamic>? _budgetData;
  Map<String, dynamic>? _cashflowData;
  
  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get dashboardData => _dashboardData;
  Map<String, dynamic>? get monthlyData => _monthlyData;
  Map<String, dynamic>? get annualData => _annualData;
  Map<String, dynamic>? get budgetData => _budgetData;
  Map<String, dynamic>? get cashflowData => _cashflowData;
  
  // Get dashboard data
  Future<void> fetchDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _reportService.getDashboardData();
      
      if (result['success']) {
        _dashboardData = result['data'];
      } else {
        _error = result['message'];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get monthly report
  Future<void> fetchMonthlyReport(int month, int year) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _reportService.getMonthlyReport(month, year);
      
      if (result['success']) {
        _monthlyData = result['data'];
      } else {
        _error = result['message'];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get annual report
  Future<void> fetchAnnualReport(int year) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _reportService.getAnnualReport(year: year);
      
      if (result['success']) {
        _annualData = result['data'];
      } else {
        _error = result['message'];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get budget report
  Future<void> fetchBudgetReport({int? month, int? year}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _reportService.getBudgetReport(month: month, year: year);
      
      if (result['success']) {
        _budgetData = result['data'];
      } else {
        _error = result['message'];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get cashflow report
  Future<void> fetchCashflowReport({
    String period = 'month',
    String? startDate,
    String? endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _reportService.getCashFlowReport(
        period: period,
        startDate: startDate,
        endDate: endDate,
      );
      
      if (result['success']) {
        _cashflowData = result['data'];
      } else {
        _error = result['message'];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Export report
  Future<Map<String, dynamic>> exportReport({
    required String reportType,
    String? startDate,
    String? endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _reportService.exportReport(
        reportType: reportType,
        startDate: startDate,
        endDate: endDate,
      );
      
      _isLoading = false;
      
      if (!result['success']) {
        _error = result['message'];
      }
      
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}