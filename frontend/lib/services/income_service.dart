import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'auth_service.dart';

class IncomeService {
  final AuthService _authService = AuthService();
  final String baseUrl = AppConstants.baseUrl;

  // Get all income entries with optional filters
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
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

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

      final uri = Uri.parse('$baseUrl/income').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['msg'] ?? 'Failed to fetch income entries'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Add a new income entry
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
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

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

      final response = await http.post(
        Uri.parse('$baseUrl/income'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['msg'] ?? 'Failed to add income'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get income details
  Future<Map<String, dynamic>> getIncomeDetails(int incomeId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/income/$incomeId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['msg'] ?? 'Failed to get income details'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Update an income entry
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
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

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

      final response = await http.put(
        Uri.parse('$baseUrl/income/$incomeId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['msg'] ?? 'Failed to update income'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Delete an income entry
  Future<Map<String, dynamic>> deleteIncome(int incomeId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/income/$incomeId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'message': data['msg'] ?? 'Income deleted successfully'};
      } else {
        return {'success': false, 'message': data['msg'] ?? 'Failed to delete income'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get income statistics
  Future<Map<String, dynamic>> getIncomeStats({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      // Build query parameters
      final queryParams = <String, String>{};
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final uri = Uri.parse('$baseUrl/income/stats').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['msg'] ?? 'Failed to fetch income statistics'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}