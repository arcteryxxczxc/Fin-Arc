// lib/api/endpoints/income_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';
import '../client.dart';

class IncomeApi {
  final ApiClient _client = ApiClient();
  final String baseUrl = AppConstants.baseUrl;

  /// Get all income entries with optional filters
  Future<Map<String, dynamic>> getIncomes({
    int page = 1,
    int perPage = 10,
    int? categoryId,
    String? startDate,
    String? endDate,
    double? minAmount,
    double? maxAmount,
    String? source,
    bool? isRecurring,
    String? search,
  }) async {
    try {
      // Build query parameters
      final queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (categoryId != null) queryParams['category_id'] = categoryId.toString();
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      if (minAmount != null) queryParams['min_amount'] = minAmount.toString();
      if (maxAmount != null) queryParams['max_amount'] = maxAmount.toString();
      if (source != null) queryParams['source'] = source;
      if (isRecurring != null) queryParams['is_recurring'] = isRecurring.toString();
      if (search != null) queryParams['search'] = search;

      final response = await _client.get(
        endpoint: 'income',
        queryParams: queryParams,
      );

      return response;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Get income details by ID
  Future<Map<String, dynamic>> getIncomeDetails(int incomeId) async {
    try {
      final response = await _client.get(
        endpoint: 'income/$incomeId',
      );

      return response;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Add a new income entry
  Future<Map<String, dynamic>> addIncome({
    required double amount,
    required String source,
    required String date,
    String? description,
    int? categoryId,
    bool isRecurring = false,
    String? recurringType,
    int? recurringDay,
    bool isTaxable = false,
    double? taxRate,
  }) async {
    try {
      final body = {
        'amount': amount,
        'source': source,
        'date': date,
        'is_recurring': isRecurring,
        'is_taxable': isTaxable,
      };

      // Add optional fields if they exist
      if (description != null) body['description'] = description;
      if (categoryId != null) body['category_id'] = categoryId;
      if (isRecurring) {
        if (recurringType != null) body['recurring_type'] = recurringType;
        if (recurringDay != null) body['recurring_day'] = recurringDay;
      }
      if (isTaxable && taxRate != null) body['tax_rate'] = taxRate;

      final response = await _client.post(
        endpoint: 'income',
        body: body,
      );

      return response;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Update an income entry
  Future<Map<String, dynamic>> updateIncome({
    required int incomeId,
    double? amount,
    String? source,
    String? date,
    String? description,
    int? categoryId,
    bool? isRecurring,
    String? recurringType,
    int? recurringDay,
    bool? isTaxable,
    double? taxRate,
  }) async {
    try {
      // Only include fields that are being updated
      final Map<String, dynamic> body = {};
      if (amount != null) body['amount'] = amount;
      if (source != null) body['source'] = source;
      if (date != null) body['date'] = date;
      if (description != null) body['description'] = description;
      if (categoryId != null) body['category_id'] = categoryId;
      if (isRecurring != null) body['is_recurring'] = isRecurring;
      if (recurringType != null) body['recurring_type'] = recurringType;
      if (recurringDay != null) body['recurring_day'] = recurringDay;
      if (isTaxable != null) body['is_taxable'] = isTaxable;
      if (taxRate != null) body['tax_rate'] = taxRate;

      final response = await _client.put(
        endpoint: 'income/$incomeId',
        body: body,
      );

      return response;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Delete an income entry
  Future<Map<String, dynamic>> deleteIncome(int incomeId) async {
    try {
      final response = await _client.delete(
        endpoint: 'income/$incomeId',
      );

      return response;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Get income statistics
  Future<Map<String, dynamic>> getIncomeStats({
    String? startDate,
    String? endDate,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final response = await _client.get(
        endpoint: 'income/stats',
        queryParams: queryParams,
      );

      return response;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Bulk action on income entries
  Future<Map<String, dynamic>> bulkActionIncomes({
    required String action,
    required List<int> incomeIds,
    int? targetCategoryId,
  }) async {
    try {
      final body = {
        'action': action,
        'income_ids': incomeIds,
      };

      // Add target category ID if action is "change_category"
      if (action == 'change_category' && targetCategoryId != null) {
        body['target_category_id'] = targetCategoryId;
      }

      final response = await _client.post(
        endpoint: 'income/bulk',
        body: body,
      );

      return response;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Export income as CSV
  Future<Map<String, dynamic>> exportIncome({
    List<int>? ids,
    int? categoryId,
    String? startDate,
    String? endDate,
    double? minAmount,
    double? maxAmount,
    String? source,
    bool? isRecurring,
    String? search,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (ids != null && ids.isNotEmpty) queryParams['ids'] = ids.join(',');
      if (categoryId != null) queryParams['category_id'] = categoryId.toString();
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      if (minAmount != null) queryParams['min_amount'] = minAmount.toString();
      if (maxAmount != null) queryParams['max_amount'] = maxAmount.toString();
      if (source != null) queryParams['source'] = source;
      if (isRecurring != null) queryParams['is_recurring'] = isRecurring.toString();
      if (search != null) queryParams['search'] = search;

      final response = await _client.getRaw(
        endpoint: 'income/export',
        queryParams: queryParams,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': response.bodyBytes,
          'content-type': response.headers['content-type'] ?? 'application/json',
          'filename': _getFilenameFromHeader(response) ?? 'income.json',
        };
      } else {
        Map<String, dynamic> data;
        try {
          data = jsonDecode(response.body);
        } catch (_) {
          data = {'msg': 'Failed to export income'};
        }
        return {'success': false, 'message': data['msg'] ?? 'Failed to export income'};
      }
    } catch (e) {
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