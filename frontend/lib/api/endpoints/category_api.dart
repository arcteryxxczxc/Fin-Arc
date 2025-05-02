// lib/api/endpoints/category_api.dart
import '../../utils/constants.dart';
import '../client.dart';

class CategoryApi {
  final ApiClient _client = ApiClient();
  final String baseUrl = AppConstants.baseUrl;

  /// Get all categories
  Future<Map<String, dynamic>> getCategories({
    bool includeInactive = false,
    bool onlyExpense = true,
  }) async {
    try {
      // Build query parameters
      final queryParams = {
        'include_inactive': includeInactive.toString(),
        'only_expense': onlyExpense.toString(),
      };

      final response = await _client.get(
        endpoint: 'categories',
        queryParams: queryParams,
      );

      return response;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Get category details
  Future<Map<String, dynamic>> getCategoryDetails(int categoryId) async {
    try {
      final response = await _client.get(
        endpoint: 'categories/$categoryId',
      );

      return response;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Add a new category
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

      final response = await _client.post(
        endpoint: 'categories',
        body: body,
      );

      return response;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Update a category
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

      final response = await _client.put(
        endpoint: 'categories/$categoryId',
        body: body,
      );

      return response;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Delete a category
  Future<Map<String, dynamic>> deleteCategory(int categoryId) async {
    try {
      final response = await _client.delete(
        endpoint: 'categories/$categoryId',
      );

      return response;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Update budget limits for multiple categories
  Future<Map<String, dynamic>> updateBudgets(Map<int, double> budgetLimits) async {
    try {
      final response = await _client.post(
        endpoint: 'categories/budgets',
        body: {'budgets': budgetLimits},
      );

      return response;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Get expenses for a specific category
  Future<Map<String, dynamic>> getCategoryExpenses(
    int categoryId, {
    int page = 1,
    int perPage = 10,
    String? startDate,
    String? endDate,
    String sort = 'date',
    String order = 'desc',
  }) async {
    try {
      // Build query parameters
      final queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
        'sort': sort,
        'order': order,
      };

      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final response = await _client.get(
        endpoint: 'categories/$categoryId/expenses',
        queryParams: queryParams,
      );

      return response;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}