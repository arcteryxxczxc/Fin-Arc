import '../api/endpoints/expense_api.dart';
import '../models/expense.dart';

class ExpenseService {
  final ExpenseApi _expenseApi = ExpenseApi();

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
      final result = await _expenseApi.getExpenses(
        page: page,
        perPage: perPage,
        categoryId: categoryId,
        startDate: startDate,
        endDate: endDate,
        minAmount: minAmount,
        maxAmount: maxAmount,
        paymentMethod: paymentMethod,
        search: search,
      );

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Service error: $e'};
    }
  }

  // Get expense details
  Future<Map<String, dynamic>> getExpenseDetails(int expenseId) async {
    try {
      final result = await _expenseApi.getExpenseDetails(expenseId);
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Service error: $e'};
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
      final result = await _expenseApi.addExpense(
        amount: amount,
        date: date,
        description: description,
        categoryId: categoryId,
        paymentMethod: paymentMethod,
        location: location,
        time: time,
        isRecurring: isRecurring,
        recurringType: recurringType,
        notes: notes,
      );

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Service error: $e'};
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
      final result = await _expenseApi.updateExpense(
        expenseId: expenseId,
        amount: amount,
        date: date,
        description: description,
        categoryId: categoryId,
        paymentMethod: paymentMethod,
        location: location,
        time: time,
        isRecurring: isRecurring,
        recurringType: recurringType,
        notes: notes,
      );

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Service error: $e'};
    }
  }

  // Delete an expense
  Future<Map<String, dynamic>> deleteExpense(int expenseId) async {
    try {
      final result = await _expenseApi.deleteExpense(expenseId);
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Service error: $e'};
    }
  }

  // Bulk action on expenses
  Future<Map<String, dynamic>> bulkActionExpenses({
    required String action,
    required List<int> expenseIds,
    int? targetCategoryId,
  }) async {
    try {
      final result = await _expenseApi.bulkActionExpenses(
        action: action,
        expenseIds: expenseIds,
        targetCategoryId: targetCategoryId,
      );

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Service error: $e'};
    }
  }

  // Get expense statistics
  Future<Map<String, dynamic>> getExpenseStats({
    String period = 'month',
    String? startDate,
    String? endDate,
  }) async {
    try {
      final result = await _expenseApi.getExpenseStats(
        period: period,
        startDate: startDate,
        endDate: endDate,
      );

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Service error: $e'};
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
      final result = await _expenseApi.exportExpenses(
        ids: ids,
        categoryId: categoryId,
        startDate: startDate,
        endDate: endDate,
        minAmount: minAmount,
        maxAmount: maxAmount,
        paymentMethod: paymentMethod,
        search: search,
      );

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Service error: $e'};
    }
  }
}