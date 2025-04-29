import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'auth_service.dart';

class CategoryService {
  final AuthService _authService = AuthService();
  final String baseUrl = AppConstants.baseUrl;

  // Get all categories
  Future<Map<String, dynamic>> getCategories({
    bool includeInactive = false,
    bool onlyExpense = true,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      // Build query parameters
      final queryParams = {
        'include_inactive': includeInactive.toString(),
        'only_expense': onlyExpense.toString(),
      };

      final uri = Uri.parse('$baseUrl/categories').replace(queryParameters: queryParams);
      
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
        return {'success': false, 'message': data['msg'] ?? 'Failed to fetch categories'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Add a new category
  Future<Map<String, dynamic>> addCategory({
    required String name,
    String? description,
    required String colorCode,
    String? icon,
    double? budgetLimit,
    int? budgetStartDay,
    bool isIncome = false,
    bool isActive = true,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final body = {
        'name': name,
        'color_code': colorCode,
        'is_income': isIncome,
        'is_active': isActive,
      };

      // Add optional fields if they exist
      if (description != null) body['description'] = description;
      if (icon != null) body['icon'] = icon;
      if (budgetLimit != null) body['budget_limit'] = budgetLimit;
      if (budgetStartDay != null) body['budget_start_day'] = budgetStartDay;

      final response = await http.post(
        Uri.parse('$baseUrl/categories'),
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
        return {'success': false, 'message': data['msg'] ?? 'Failed to add category'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get category details
  Future<Map<String, dynamic>> getCategoryDetails(int categoryId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/categories/$categoryId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['msg'] ?? 'Failed to get category details'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Update a category
  Future<Map<String, dynamic>> updateCategory({
    required int categoryId,
    String? name,
    String? description,
    String? colorCode,
    String? icon,
    double? budgetLimit,
    int? budgetStartDay,
    bool? isIncome,
    bool? isActive,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      // Only include fields that are being updated
      final Map<String, dynamic> body = {};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (colorCode != null) body['color_code'] = colorCode;
      if (icon != null) body['icon'] = icon;
      if (budgetLimit != null) body['budget_limit'] = budgetLimit;
      if (budgetStartDay != null) body['budget_start_day'] = budgetStartDay;
      if (isIncome != null) body['is_income'] = isIncome;
      if (isActive != null) body['is_active'] = isActive;

      final response = await http.put(
        Uri.parse('$baseUrl/categories/$categoryId'),
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
        return {'success': false, 'message': data['msg'] ?? 'Failed to update category'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Delete a category
  Future<Map<String, dynamic>> deleteCategory(int categoryId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/categories/$categoryId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'message': data['msg'] ?? 'Category deleted successfully'};
      } else {
        return {'success': false, 'message': data['msg'] ?? 'Failed to delete category'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Update budget limits for multiple categories
  Future<Map<String, dynamic>> updateBudgets(Map<int, double> budgetLimits) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/categories/budgets'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'budgets': budgetLimits}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'message': data['msg'] ?? 'Budgets updated successfully'};
      } else {
        return {'success': false, 'message': data['msg'] ?? 'Failed to update budgets'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}