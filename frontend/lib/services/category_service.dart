import '../api/endpoints/category_api.dart';
import '../models/category.dart';

class CategoryService {
  final CategoryApi _categoryApi = CategoryApi();

  // Get all categories
  Future<Map<String, dynamic>> getCategories({
    bool includeInactive = false,
    bool onlyExpense = true,
  }) async {
    try {
      final result = await _categoryApi.getCategories(
        includeInactive: includeInactive,
        onlyExpense: onlyExpense,
      );

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Service error: $e'};
    }
  }

  // Get category details
  Future<Map<String, dynamic>> getCategoryDetails(int categoryId) async {
    try {
      final result = await _categoryApi.getCategoryDetails(categoryId);
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Service error: $e'};
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
      final result = await _categoryApi.addCategory(
        name: name,
        description: description,
        colorCode: colorCode,
        icon: icon,
        budgetLimit: budgetLimit,
        budgetStartDay: budgetStartDay,
        isIncome: isIncome,
        isActive: isActive,
      );

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Service error: $e'};
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
      final result = await _categoryApi.updateCategory(
        categoryId: categoryId,
        name: name,
        description: description,
        colorCode: colorCode,
        icon: icon,
        budgetLimit: budgetLimit,
        budgetStartDay: budgetStartDay,
        isIncome: isIncome,
        isActive: isActive,
      );

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Service error: $e'};
    }
  }

  // Delete a category
  Future<Map<String, dynamic>> deleteCategory(int categoryId) async {
    try {
      final result = await _categoryApi.deleteCategory(categoryId);
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Service error: $e'};
    }
  }

  // Update budget limits for multiple categories
  Future<Map<String, dynamic>> updateBudgets(Map<int, double> budgetLimits) async {
    try {
      final result = await _categoryApi.updateBudgets(budgetLimits);
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Service error: $e'};
    }
  }

  // Get expenses for a specific category
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
      final result = await _categoryApi.getCategoryExpenses(
        categoryId,
        page: page,
        perPage: perPage,
        startDate: startDate,
        endDate: endDate,
        sort: sort,
        order: order,
      );

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Service error: $e'};
    }
  }
}