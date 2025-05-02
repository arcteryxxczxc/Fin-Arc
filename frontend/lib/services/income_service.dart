import '../api/endpoints/income_api.dart';

class IncomeService {
  final IncomeApi _incomeApi = IncomeApi();

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
      final result = await _incomeApi.getIncomes(
        page: page,
        perPage: perPage,
        categoryId: categoryId,
        startDate: startDate,
        endDate: endDate,
        minAmount: minAmount,
        maxAmount: maxAmount,
        source: source,
        isRecurring: isRecurring,
        search: search,
      );

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Service error: $e'};
    }
  }

  // Get income details
  Future<Map<String, dynamic>> getIncomeDetails(int incomeId) async {
    try {
      final result = await _incomeApi.getIncomeDetails(incomeId);
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Service error: $e'};
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
      final result = await _incomeApi.addIncome(
        amount: amount,
        source: source,
        date: date,
        description: description,
        categoryId: categoryId,
        isRecurring: isRecurring,
        recurringType: recurringType,
        recurringDay: recurringDay,
        isTaxable: isTaxable,
        taxRate: taxRate,
      );

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Service error: $e'};
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
      final result = await _incomeApi.updateIncome(
        incomeId: incomeId,
        amount: amount,
        source: source,
        date: date,
        description: description,
        categoryId: categoryId,
        isRecurring: isRecurring,
        recurringType: recurringType,
        recurringDay: recurringDay,
        isTaxable: isTaxable,
        taxRate: taxRate,
      );

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Service error: $e'};
    }
  }

  // Delete an income entry
  Future<Map<String, dynamic>> deleteIncome(int incomeId) async {
    try {
      final result = await _incomeApi.deleteIncome(incomeId);
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Service error: $e'};
    }
  }

  // Get income statistics
  Future<Map<String, dynamic>> getIncomeStats({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final result = await _incomeApi.getIncomeStats(
        startDate: startDate,
        endDate: endDate,
      );

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Service error: $e'};
    }
  }

  // Bulk action on income entries
  Future<Map<String, dynamic>> bulkActionIncomes({
    required String action,
    required List<int> incomeIds,
    int? targetCategoryId,
  }) async {
    try {
      final result = await _incomeApi.bulkActionIncomes(
        action: action,
        incomeIds: incomeIds,
        targetCategoryId: targetCategoryId,
      );

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Service error: $e'};
    }
  }

  // Export income as CSV
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
      final result = await _incomeApi.exportIncome(
        ids: ids,
        categoryId: categoryId,
        startDate: startDate,
        endDate: endDate,
        minAmount: minAmount,
        maxAmount: maxAmount,
        source: source,
        isRecurring: isRecurring,
        search: search,
      );

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Service error: $e'};
    }
  }
}