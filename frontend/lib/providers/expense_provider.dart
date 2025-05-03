// lib/providers/expense_provider.dart
import 'package:flutter/foundation.dart';
import '../services/expense_service.dart';
import '../models/expense.dart';

class ExpenseProvider with ChangeNotifier {
  final ExpenseService _expenseService = ExpenseService();
  
  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  bool _hasMoreToLoad = true;
  
  // Getters
  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMoreToLoad => _hasMoreToLoad;
  bool get hasMorePages => _currentPage < _totalPages;
  
  // Filter state
  int? _categoryId;
  String? _startDate;
  String? _endDate;
  double? _minAmount;
  double? _maxAmount;
  String? _paymentMethod;
  String? _searchQuery;
  
  // Fetch expenses with optional refresh
  Future<void> fetchExpenses({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreToLoad = true;
    }
    
    if (!_hasMoreToLoad && !refresh) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _expenseService.getExpenses(
        page: _currentPage,
        perPage: 15,
        categoryId: _categoryId,
        startDate: _startDate,
        endDate: _endDate,
        minAmount: _minAmount,
        maxAmount: _maxAmount,
        paymentMethod: _paymentMethod,
        search: _searchQuery,
      );
      
      if (result['success']) {
        if (!result.containsKey('data') || result['data'] == null) {
          _error = 'Invalid response format';
        } else {
          final data = result['data'];
          
          // Parse expenses with validation
          List<Expense> fetchedExpenses = [];
          if (data.containsKey('expenses') && data['expenses'] is List) {
            for (final item in data['expenses']) {
              try {
                fetchedExpenses.add(Expense.fromJson(item));
              } catch (e) {
                print('Error parsing expense: $e');
                // Continue with other items
              }
            }
          } else {
            _error = 'Invalid expense data format';
          }
          
          // Update data
          if (refresh) {
            _expenses = fetchedExpenses;
          } else {
            _expenses.addAll(fetchedExpenses);
          }
          
          // Update pagination data
          if (data.containsKey('pagination') && data['pagination'] is Map) {
            _totalPages = data['pagination']['total_pages'] ?? 1;
            _totalItems = data['pagination']['total_items'] ?? 0;
            _hasMoreToLoad = _currentPage < _totalPages;
            _currentPage++;
          } else {
            _totalPages = 1;
            _totalItems = fetchedExpenses.length;
            _hasMoreToLoad = false;
          }
        }
      } else {
        _error = result['message'] ?? 'Unknown error occurred';
      }
    } catch (e) {
      _error = 'Error fetching expenses: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Load more expenses (pagination support)
  Future<void> loadMoreExpenses() async {
    if (_isLoading || !hasMorePages) return;
    
    await fetchExpenses(refresh: false);
  }
  
  // Apply filters and reload data
  Future<void> applyFilters({
    int? categoryId,
    String? startDate,
    String? endDate,
    double? minAmount,
    double? maxAmount,
    String? paymentMethod,
    String? searchQuery,
  }) async {
    _categoryId = categoryId;
    _startDate = startDate;
    _endDate = endDate;
    _minAmount = minAmount;
    _maxAmount = maxAmount;
    _paymentMethod = paymentMethod;
    _searchQuery = searchQuery;
    
    await fetchExpenses(refresh: true);
  }
  
  // Clear all filters
  Future<void> clearFilters() async {
    _categoryId = null;
    _startDate = null;
    _endDate = null;
    _minAmount = null;
    _maxAmount = null;
    _paymentMethod = null;
    _searchQuery = null;
    
    await fetchExpenses(refresh: true);
  }
  
  // Get a single expense
  Future<Map<String, dynamic>> getExpenseDetails(int expenseId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _expenseService.getExpenseDetails(expenseId);
      
      _isLoading = false;
      
      if (result['success']) {
        if (!result.containsKey('data') || !result['data'].containsKey('expense')) {
          _error = 'Invalid response format';
          notifyListeners();
          return {'success': false, 'message': 'Invalid response format'};
        }
        
        final expenseData = result['data']['expense'];
        final expense = Expense.fromJson(expenseData);
        notifyListeners();
        return {'success': true, 'expense': expense};
      } else {
        _error = result['message'] ?? 'Failed to fetch expense details';
        notifyListeners();
        return {'success': false, 'message': _error};
      }
    } catch (e) {
      _error = 'Error fetching expense details: $e';
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _error};
    }
  }
  
  // Add a new expense
  Future<bool> addExpense({
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
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _expenseService.addExpense(
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
      
      _isLoading = false;
      
      if (result['success']) {
        // Refresh expense list
        await fetchExpenses(refresh: true);
        return true;
      } else {
        _error = result['message'] ?? 'Failed to add expense';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error adding expense: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Update an expense
  Future<bool> updateExpense({
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
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _expenseService.updateExpense(
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
      
      _isLoading = false;
      
      if (result['success']) {
        // Update the expense in the local list
        if (result.containsKey('data') && result['data'].containsKey('expense')) {
          final updatedExpense = Expense.fromJson(result['data']['expense']);
          final index = _expenses.indexWhere((e) => e.id == expenseId);
          if (index != -1) {
            _expenses[index] = updatedExpense;
          }
        } else {
          // Refresh from the server if we don't have the updated expense
          await fetchExpenses(refresh: true);
        }
        
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Failed to update expense';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error updating expense: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Delete an expense
  Future<bool> deleteExpense(int expenseId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _expenseService.deleteExpense(expenseId);
      
      _isLoading = false;
      
      if (result['success']) {
        // Remove the expense from the local list
        _expenses.removeWhere((e) => e.id == expenseId);
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Failed to delete expense';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error deleting expense: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}