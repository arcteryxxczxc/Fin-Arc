import 'package:flutter/foundation.dart';
import '../services/expense_service.dart';
import '../models/expense.dart';

class ExpenseProvider with ChangeNotifier {
  final ExpenseService _expenseService = ExpenseService();
  
  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _expenseStats;
  
  // Pagination data
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  bool _hasMorePages = false;
  
  // Filters
  int? _categoryId;
  String? _startDate;
  String? _endDate;
  double? _minAmount;
  double? _maxAmount;
  String? _paymentMethod;
  String? _search;
  
  // Getters
  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get expenseStats => _expenseStats;
  
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  bool get hasMorePages => _hasMorePages;
  
  // Initialize expenses
  Future<void> fetchExpenses({
    bool refresh = false,
    int? categoryId,
    String? startDate,
    String? endDate,
    double? minAmount,
    double? maxAmount,
    String? paymentMethod,
    String? search,
  }) async {
    // Update filters if provided
    _categoryId = categoryId ?? _categoryId;
    _startDate = startDate ?? _startDate;
    _endDate = endDate ?? _endDate;
    _minAmount = minAmount ?? _minAmount;
    _maxAmount = maxAmount ?? _maxAmount;
    _paymentMethod = paymentMethod ?? _paymentMethod;
    _search = search ?? _search;
    
    // Reset to first page if refreshing
    if (refresh) {
      _currentPage = 1;
      _expenses = [];
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _expenseService.getExpenses(
        page: _currentPage,
        perPage: 10,
        categoryId: _categoryId,
        startDate: _startDate,
        endDate: _endDate,
        minAmount: _minAmount,
        maxAmount: _maxAmount,
        paymentMethod: _paymentMethod,
        search: _search,
      );
      
      if (result['success']) {
        final data = result['data'];
        
        // Parse expenses
        List<Expense> fetchedExpenses = [];
        for (final item in data['expenses']) {
          fetchedExpenses.add(Expense.fromJson(item));
        }
        
        // Update pagination data
        if (refresh) {
          _expenses = fetchedExpenses;
        } else {
          _expenses.addAll(fetchedExpenses);
        }
        
        _totalPages = data['pagination']['total_pages'];
        _totalItems = data['pagination']['total_items'];
        _hasMorePages = _currentPage < _totalPages;
        
      } else {
        _error = result['message'];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Load next page
  Future<void> loadMoreExpenses() async {
    if (_isLoading || !_hasMorePages) return;
    
    _currentPage++;
    await fetchExpenses();
  }
  
  // Get expense details by ID
  Future<Map<String, dynamic>> getExpenseDetails(int expenseId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _expenseService.getExpenseDetails(expenseId);
      
      _isLoading = false;
      
      if (result['success']) {
        // Parse expense data
        final expenseData = result['data']['expense'];
        final expense = Expense.fromJson(expenseData);
        
        return {
          'success': true,
          'expense': expense,
        };
      } else {
        _error = result['message'];
        notifyListeners();
        return {
          'success': false,
          'message': _error,
        };
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': _error,
      };
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
        // Refresh expenses to include the new one
        await fetchExpenses(refresh: true);
        notifyListeners();
        return true;
      } else {
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
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
        // Refresh expenses to update the list
        await fetchExpenses(refresh: true);
        notifyListeners();
        return true;
      } else {
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
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