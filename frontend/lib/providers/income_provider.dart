import 'package:flutter/foundation.dart';
import '../services/income_service.dart';
import '../models/income.dart';
import 'package:intl/intl.dart';

class IncomeProvider with ChangeNotifier {
  final IncomeService _incomeService = IncomeService();
  
  List<Income> _incomes = [];
  List<Income> _recurringIncomes = []; // Specifically for recurring incomes
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _incomeStats;
  
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
  String? _source;
  bool? _isRecurring;
  String? _search;
  
  // Getters
  List<Income> get incomes => _incomes;
  List<Income> get recurringIncomes => _recurringIncomes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get incomeStats => _incomeStats;
  
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  bool get hasMorePages => _hasMorePages;
  
  // Monthly and yearly totals
  double get currentMonthTotal {
    if (_incomes.isEmpty) return 0;
    
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    
    return _incomes
        .where((income) {
          final incomeDate = DateTime.parse(income.date);
          return incomeDate.isAfter(firstDayOfMonth.subtract(Duration(days: 1))) && 
                 incomeDate.isBefore(lastDayOfMonth.add(Duration(days: 1)));
        })
        .fold(0, (sum, income) => sum + income.amount);
  }
  
  double get currentYearTotal {
    if (_incomes.isEmpty) return 0;
    
    final now = DateTime.now();
    final firstDayOfYear = DateTime(now.year, 1, 1);
    final lastDayOfYear = DateTime(now.year, 12, 31);
    
    return _incomes
        .where((income) {
          final incomeDate = DateTime.parse(income.date);
          return incomeDate.isAfter(firstDayOfYear.subtract(Duration(days: 1))) && 
                 incomeDate.isBefore(lastDayOfYear.add(Duration(days: 1)));
        })
        .fold(0, (sum, income) => sum + income.amount);
  }
  
  // Initialize incomes
  Future<void> fetchIncomes({
    bool refresh = false,
    int? categoryId,
    String? startDate,
    String? endDate,
    double? minAmount,
    double? maxAmount,
    String? source,
    bool? isRecurring,
    String? search,
  }) async {
    // Update filters if provided
    _categoryId = categoryId ?? _categoryId;
    _startDate = startDate ?? _startDate;
    _endDate = endDate ?? _endDate;
    _minAmount = minAmount ?? _minAmount;
    _maxAmount = maxAmount ?? _maxAmount;
    _source = source ?? _source;
    _isRecurring = isRecurring ?? _isRecurring;
    _search = search ?? _search;
    
    // Reset to first page if refreshing
    if (refresh) {
      _currentPage = 1;
      _incomes = [];
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _incomeService.getIncomes(
        page: _currentPage,
        perPage: 10,
        categoryId: _categoryId,
        startDate: _startDate,
        endDate: _endDate,
        minAmount: _minAmount,
        maxAmount: _maxAmount,
        source: _source,
        isRecurring: _isRecurring,
        search: _search,
      );
      
      if (result['success']) {
        final data = result['data'];
        
        // Parse incomes
        List<Income> fetchedIncomes = [];
        for (final item in data['incomes']) {
          fetchedIncomes.add(Income.fromJson(item));
        }
        
        // Update pagination data
        if (refresh) {
          _incomes = fetchedIncomes;
        } else {
          _incomes.addAll(fetchedIncomes);
        }
        
        _totalPages = data['pagination']['total_pages'];
        _totalItems = data['pagination']['total_items'];
        _hasMorePages = _currentPage < _totalPages;
        
        // If we're on the first page and just refreshed, update recurring incomes list
        if (refresh && _currentPage == 1) {
          _recurringIncomes = _incomes.where((income) => income.isRecurring).toList();
        }
        
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
  Future<void> loadMoreIncomes() async {
    if (_isLoading || !_hasMorePages) return;
    
    _currentPage++;
    await fetchIncomes();
  }
  
  // Add a new income
  Future<bool> addIncome({
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
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _incomeService.addIncome(
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
      
      _isLoading = false;
      
      if (result['success']) {
        // Refresh incomes to include the new one
        await fetchIncomes(refresh: true);
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
  
  // Get income details
  Future<Map<String, dynamic>> getIncomeDetails(int incomeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _incomeService.getIncomeDetails(incomeId);
      
      _isLoading = false;
      
      if (result['success']) {
        notifyListeners();
        return result;
      } else {
        _error = result['message'];
        notifyListeners();
        return {'success': false, 'message': _error};
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _error};
    }
  }
  
  // Update an income
  Future<bool> updateIncome({
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
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _incomeService.updateIncome(
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
      
      _isLoading = false;
      
      if (result['success']) {
        // Refresh incomes to update the list
        await fetchIncomes(refresh: true);
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
  
  // Delete an income
  Future<bool> deleteIncome(int incomeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _incomeService.deleteIncome(incomeId);
      
      _isLoading = false;
      
      if (result['success']) {
        // Remove the income from the list
        _incomes.removeWhere((income) => income.id == incomeId);
        _recurringIncomes.removeWhere((income) => income.id == incomeId);
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
  
  // Get income statistics
  Future<void> fetchIncomeStats({
    String? startDate,
    String? endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _incomeService.getIncomeStats(
        startDate: startDate,
        endDate: endDate,
      );
      
      if (result['success']) {
        _incomeStats = result['data'];
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
  
  // Get only recurring incomes
  Future<void> fetchRecurringIncomes() async {
    await fetchIncomes(refresh: true, isRecurring: true);
  }
  
  // Get income by source
  Future<void> fetchIncomeBySource(String source) async {
    await fetchIncomes(refresh: true, source: source);
  }
  
  // Get income by date range with custom formatting
  Future<void> fetchIncomeByDateRange(DateTime startDate, DateTime endDate) async {
    final formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);
    final formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate);
    
    await fetchIncomes(
      refresh: true,
      startDate: formattedStartDate,
      endDate: formattedEndDate,
    );
  }
  
  // Get income for current month
  Future<void> fetchCurrentMonthIncome() async {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    
    await fetchIncomeByDateRange(firstDayOfMonth, lastDayOfMonth);
  }
  
  // Get income for current year
  Future<void> fetchCurrentYearIncome() async {
    final now = DateTime.now();
    final firstDayOfYear = DateTime(now.year, 1, 1);
    final lastDayOfYear = DateTime(now.year, 12, 31);
    
    await fetchIncomeByDateRange(firstDayOfYear, lastDayOfYear);
  }
  
  // Get income grouped by category
  List<Map<String, dynamic>> getIncomeByCategory() {
    if (_incomes.isEmpty) return [];
    
    // Group incomes by category
    final Map<String?, double> categoryTotals = {};
    
    for (final income in _incomes) {
      final categoryName = income.categoryName ?? 'Uncategorized';
      categoryTotals[categoryName] = (categoryTotals[categoryName] ?? 0) + income.amount;
    }
    
    // Convert to list of maps
    return categoryTotals.entries
        .map((entry) => {
              'category': entry.key,
              'amount': entry.value,
              'percentage': entry.value / _incomes.fold(0, (sum, income) => sum + income.amount) * 100,
            })
        .toList();
  }
  
  // Get income grouped by month
  List<Map<String, dynamic>> getMonthlyIncome(int months) {
    if (_incomes.isEmpty) return [];
    
    // Get today's date
    final now = DateTime.now();
    
    // Create result list
    final List<Map<String, dynamic>> result = [];
    
    // Calculate months range
    for (int i = 0; i < months; i++) {
      final year = now.year;
      final month = now.month - i;
      
      // Adjust for previous year
      final DateTime date = month > 0
          ? DateTime(year, month, 1)
          : DateTime(year - 1, month + 12, 1);
      
      // Format month name
      final monthName = DateFormat('MMM yyyy').format(date);
      
      // Calculate income for this month
      final monthIncome = _incomes
          .where((income) {
            final incomeDate = DateTime.parse(income.date);
            return incomeDate.year == date.year && incomeDate.month == date.month;
          })
          .fold(0.0, (sum, income) => sum + income.amount);
      
      // Add to result
      result.add({
        'month': monthName,
        'amount': monthIncome,
      });
    }
    
    // Reverse to get oldest first
    return result.reversed.toList();
  }
  
  // Compare current month's income to previous month
  Map<String, dynamic> compareToLastMonth() {
    final now = DateTime.now();
    
    // Current month
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final currentMonthEnd = DateTime(now.year, now.month + 1, 0);
    
    // Previous month
    final prevMonthStart = DateTime(now.year, now.month - 1, 1);
    final prevMonthEnd = DateTime(now.year, now.month, 0);
    
    // Calculate income for current month
    final currentMonthIncome = _incomes
        .where((income) {
          final incomeDate = DateTime.parse(income.date);
          return incomeDate.isAfter(currentMonthStart.subtract(Duration(days: 1))) && 
                 incomeDate.isBefore(currentMonthEnd.add(Duration(days: 1)));
        })
        .fold(0.0, (sum, income) => sum + income.amount);
    
    // Calculate income for previous month
    final prevMonthIncome = _incomes
        .where((income) {
          final incomeDate = DateTime.parse(income.date);
          return incomeDate.isAfter(prevMonthStart.subtract(Duration(days: 1))) && 
                 incomeDate.isBefore(prevMonthEnd.add(Duration(days: 1)));
        })
        .fold(0.0, (sum, income) => sum + income.amount);
    
    // Calculate change
    final difference = currentMonthIncome - prevMonthIncome;
    final percentChange = prevMonthIncome > 0 
        ? (difference / prevMonthIncome) * 100 
        : (currentMonthIncome > 0 ? 100 : 0);
    
    return {
      'current_month': currentMonthIncome,
      'previous_month': prevMonthIncome,
      'difference': difference,
      'percent_change': percentChange,
      'increased': difference >= 0,
    };
  }
  
  // Reset filters
  void resetFilters() {
    _categoryId = null;
    _startDate = null;
    _endDate = null;
    _minAmount = null;
    _maxAmount = null;
    _source = null;
    _isRecurring = null;
    _search = null;
    
    fetchIncomes(refresh: true);
  }
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}