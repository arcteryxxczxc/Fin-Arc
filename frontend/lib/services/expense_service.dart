import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'auth_service.dart';

class ExpenseService {
  final AuthService _authService = AuthService();
  final String baseUrl = AppConstants.baseUrl;

  // Get all expenses with optional filters
  Future<Map<String, dynamic>> getExpenses({
    int page = 1,
    int perPage = 10,
    int? categoryId,
    String? startDate,
    String? endDate,
    double? minAmount,
    double? maxAmount,
    String? paymentMethod,
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
      if (paymentMethod != null) queryParams['payment_method'] = paymentMethod;
      if (search != null) queryParams['search'] = search;

      final uri = Uri.parse('$baseUrl/expenses').replace(queryParameters: queryParams);
      
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
        return {'success': false, 'message': data['error'] ?? 'Failed to fetch expenses'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get expense details
  Future<Map<String, dynamic>> getExpenseDetails(int expenseId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/expenses/$expenseId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['error'] ?? 'Failed to get expense details'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Add a new expense
  Future<Map<String, dynamic>> addExpense({
    required double amount,
    required String date,
    String? description,
    int? categoryId,
    String? paymentMethod,
    String? location,
    String? time,
    bool isRecurring = false,
    String? recurringType,
    String? notes,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final body = {
        'amount': amount,
        'date': date,
      };

      // Add optional fields if they exist
      if (description != null) body['description'] = description;
      if (categoryId != null) body['category_id'] = categoryId;
      if (paymentMethod != null) body['payment_method'] = paymentMethod;
      if (location != null) body['location'] = location;
      if (time != null) body['time'] = time;
      if (isRecurring) {
        body['is_recurring'] = true;
        if (recurringType != null) body['recurring_type'] = recurringType;
      }
      if (notes != null) body['notes'] = notes;

      final response = await http.post(
        Uri.parse('$baseUrl/expenses'),
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
        return {'success': false, 'message': data['error'] ?? 'Failed to add expense'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Update an expense
  Future<Map<String, dynamic>> updateExpense({
    required int expenseId,
    double? amount,
    String? date,
    String? description,
    int? categoryId,
    String? paymentMethod,
    String? location,
    String? time,
    bool? isRecurring,
    String? recurringType,
    String? notes,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      // Only include fields that are being updated
      final Map<String, dynamic> body = {};
      if (amount != null) body['amount'] = amount;
      if (date != null) body['date'] = date;
      if (description != null) body['description'] = description;
      if (categoryId != null) body['category_id'] = categoryId;
      if (paymentMethod != null) body['payment_method'] = paymentMethod;
      if (location != null) body['location'] = location;
      if (time != null) body['time'] = time;
      if (isRecurring != null) {
        body['is_recurring'] = isRecurring;
        if (isRecurring && recurringType != null) body['recurring_type'] = recurringType;
      }
      if (notes != null) body['notes'] = notes;

      final response = await http.put(
        Uri.parse('$baseUrl/expenses/$expenseId'),
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
        return {'success': false, 'message': data['error'] ?? 'Failed to update expense'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Delete an expense
  Future<Map<String, dynamic>> deleteExpense(int expenseId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/expenses/$expenseId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'message': data['message'] ?? 'Expense deleted successfully'};
      } else {
        return {'success': false, 'message': data['error'] ?? 'Failed to delete expense'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Bulk action on expenses
  Future<Map<String, dynamic>> bulkActionExpenses({
    required String action,
    required List<int> expenseIds,
    int? targetCategoryId,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final body = {
        'action': action,
        'expense_ids': expenseIds,
      };

      // Add target category ID if action is "change_category"
      if (action == 'change_category' && targetCategoryId != null) {
        body['target_category_id'] = targetCategoryId;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/expenses/bulk'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'message': data['message'] ?? 'Bulk action completed successfully'};
      } else {
        return {'success': false, 'message': data['error'] ?? 'Failed to perform bulk action'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get expense statistics
  Future<Map<String, dynamic>> getExpenseStats({
    String period = 'month',
    String? startDate,
    String? endDate,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      // Build query parameters
      final queryParams = {'period': period};
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final uri = Uri.parse('$baseUrl/expenses/stats').replace(queryParameters: queryParams);
      
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
        return {'success': false, 'message': data['error'] ?? 'Failed to fetch expense statistics'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
  
  // Export expenses as CSV
  Future<Map<String, dynamic>> exportExpenses({
    List<int>? ids,
    int? categoryId,
    String? startDate,
    String? endDate,
    double? minAmount,
    double? maxAmount,
    String? paymentMethod,
    String? search,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      // Build query parameters
      final queryParams = <String, String>{};
      if (ids != null && ids.isNotEmpty) queryParams['ids'] = ids.join(',');
      if (categoryId != null) queryParams['category_id'] = categoryId.toString();
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      if (minAmount != null) queryParams['min_amount'] = minAmount.toString();
      if (maxAmount != null) queryParams['max_amount'] = maxAmount.toString();
      if (paymentMethod != null) queryParams['payment_method'] = paymentMethod;
      if (search != null) queryParams['search'] = search;

      final uri = Uri.parse('$baseUrl/expenses/export').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // For file download, we return the response directly
        return {
          'success': true,
          'data': response.bodyBytes,
          'content-type': response.headers['content-type'] ?? 'text/csv',
          'filename': _getFilenameFromHeader(response) ?? 'expenses.csv',
        };
      } else {
        Map<String, dynamic> data;
        try {
          data = jsonDecode(response.body);
        } catch (_) {
          data = {'error': 'Failed to export expenses'};
        }
        return {'success': false, 'message': data['error'] ?? 'Failed to export expenses'};
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