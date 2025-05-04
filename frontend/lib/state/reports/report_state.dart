// lib/state/reports/report_state.dart
import 'package:flutter/foundation.dart' hide Category;
import '../../models/report.dart';

/// Base state for reports
@immutable
abstract class ReportState {
  final List<Report> reports;
  final bool isLoading;
  final String? error;

  const ReportState({
    required this.reports,
    required this.isLoading,
    this.error,
  });
}

/// Initial state when the app starts
class ReportInitialState extends ReportState {
  const ReportInitialState()
      : super(
          reports: const [],
          isLoading: false,
        );
}

/// Loading state while fetching reports
class ReportLoadingState extends ReportState {
  const ReportLoadingState({
    required List<Report> reports,
  }) : super(
          reports: reports,
          isLoading: true,
        );

  /// Factory constructor to create from another state
  factory ReportLoadingState.from(ReportState state) {
    return ReportLoadingState(
      reports: state.reports,
    );
  }
}

/// Loaded state when reports are successfully fetched
class ReportLoadedState extends ReportState {
  const ReportLoadedState({
    required List<Report> reports,
  }) : super(
          reports: reports,
          isLoading: false,
        );
}

/// Error state when there's an issue fetching or manipulating reports
class ReportErrorState extends ReportState {
  const ReportErrorState({
    required List<Report> reports,
    required String error,
  }) : super(
          reports: reports,
          isLoading: false,
          error: error,
        );

  /// Factory constructor to create from another state
  factory ReportErrorState.from(ReportState state, String error) {
    return ReportErrorState(
      reports: state.reports,
      error: error,
    );
  }
}

/// State representing specific report data
class ReportDetailState extends ReportState {
  final Map<String, dynamic> reportData;
  final String reportType;

  const ReportDetailState({
    required List<Report> reports,
    required this.reportData,
    required this.reportType,
    bool isLoading = false,
    String? error,
  }) : super(
          reports: reports,
          isLoading: isLoading,
          error: error,
        );
}