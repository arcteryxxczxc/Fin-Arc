// lib/state/reports/report_notifier.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/report_service.dart';
import '../../models/report.dart';
import 'report_state.dart';

/// Report notifier that manages report state
class ReportNotifier extends StateNotifier<ReportState> {
  final ReportService _reportService = ReportService();

  ReportNotifier() : super(const ReportInitialState());

  /// Get dashboard data
  Future<void> getDashboardData() async {
    // Set state to loading
    state = ReportLoadingState.from(state);

    try {
      final result = await _reportService.getDashboardData();

      if (result['success']) {
        // Update state with dashboard data
        state = ReportDetailState(
          reports: state.reports,
          reportData: result['data'],
          reportType: 'dashboard',
        );
      } else {
        // Handle error
        state = ReportErrorState.from(state, result['message'] ?? 'Failed to load dashboard data');
      }
    } catch (e) {
      // Handle exception
      state = ReportErrorState.from(state, e.toString());
    }
  }

  /// Get monthly report
  Future<void> getMonthlyReport(int month, int year) async {
    state = ReportLoadingState.from(state);

    try {
      final result = await _reportService.getMonthlyReport(month, year);

      if (result['success']) {
        state = ReportDetailState(
          reports: state.reports,
          reportData: result['data'],
          reportType: 'monthly',
        );
      } else {
        state = ReportErrorState.from(state, result['message'] ?? 'Failed to load monthly report');
      }
    } catch (e) {
      state = ReportErrorState.from(state, e.toString());
    }
  }

  /// Get annual report
  Future<void> getAnnualReport(int year) async {
    state = ReportLoadingState.from(state);

    try {
      final result = await _reportService.getAnnualReport(year: year);

      if (result['success']) {
        state = ReportDetailState(
          reports: state.reports,
          reportData: result['data'],
          reportType: 'annual',
        );
      } else {
        state = ReportErrorState.from(state, result['message'] ?? 'Failed to load annual report');
      }
    } catch (e) {
      state = ReportErrorState.from(state, e.toString());
    }
  }

  /// Get budget report
  Future<void> getBudgetReport({int? month, int? year}) async {
    state = ReportLoadingState.from(state);

    try {
      final result = await _reportService.getBudgetReport(month: month, year: year);

      if (result['success']) {
        state = ReportDetailState(
          reports: state.reports,
          reportData: result['data'],
          reportType: 'budget',
        );
      } else {
        state = ReportErrorState.from(state, result['message'] ?? 'Failed to load budget report');
      }
    } catch (e) {
      state = ReportErrorState.from(state, e.toString());
    }
  }

  /// Get cashflow report
  Future<void> getCashflowReport({
    String period = 'month',
    String? startDate,
    String? endDate,
  }) async {
    state = ReportLoadingState.from(state);

    try {
      final result = await _reportService.getCashFlowReport(
        period: period,
        startDate: startDate,
        endDate: endDate,
      );

      if (result['success']) {
        state = ReportDetailState(
          reports: state.reports,
          reportData: result['data'],
          reportType: 'cashflow',
        );
      } else {
        state = ReportErrorState.from(state, result['message'] ?? 'Failed to load cashflow report');
      }
    } catch (e) {
      state = ReportErrorState.from(state, e.toString());
    }
  }

  /// Export report data
  Future<Map<String, dynamic>> exportReport({
    required String reportType,
    String? startDate,
    String? endDate,
  }) async {
    state = ReportLoadingState.from(state);

    try {
      final result = await _reportService.exportReport(
        reportType: reportType,
        startDate: startDate,
        endDate: endDate,
      );

      if (result['success']) {
        // We don't update state since we're just exporting data
        state = ReportLoadedState(reports: state.reports);
        return result;
      } else {
        state = ReportErrorState.from(state, result['message'] ?? 'Failed to export report');
        return result;
      }
    } catch (e) {
      state = ReportErrorState.from(state, e.toString());
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Clear error
  void clearError() {
    if (state.error != null) {
      state = ReportLoadedState(
        reports: state.reports,
      );
    }
  }
}

// Provider for report state 
final reportProvider = StateNotifierProvider<ReportNotifier, ReportState>((ref) {
  return ReportNotifier();
});