import 'package:flutter/foundation.dart' hide Category;
import '../services/category_service.dart';
import '../models/category.dart' as model;

class CategoryProvider with ChangeNotifier {
  final CategoryService _categoryService = CategoryService();
  
  List<model.Category> _categories = [];
  List<model.Category> _expenseCategories = [];
  List<model.Category> _incomeCategories = []; 
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<model.Category> get categories => _categories;
  List<model.Category> get expenseCategories => _expenseCategories;
  List<model.Category> get incomeCategories => _incomeCategories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Initialize categories
  Future<void> fetchCategories({
    bool includeInactive = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Fetch all categories
      final result = await _categoryService.getCategories(
        includeInactive: includeInactive,
        onlyExpense: false, // Get both expense and income categories
      );
      
      if (result['success']) {
        // Convert raw data to Category objects
        List<model.Category> fetchedCategories = [];
        final data = result['data'];
        
        // Handle different response formats
        if (data is List) {
          // If data is already a list
          for (final item in data) {
            fetchedCategories.add(model.Category.fromJson(item));
          }
        } else if (data is Map) {
          // If data is a map with categories under a key
          if (data.containsKey('categories')) {
            final categoryList = data['categories'];
            if (categoryList is List) {
              for (final item in categoryList) {
                fetchedCategories.add(model.Category.fromJson(item));
              }
            }
          } else {
            // If it's just a map, consider it as a single category
            fetchedCategories.add(model.Category.fromJson(Map<String, dynamic>.from(data)));
          }
        }
        
        // Update lists
        _categories = fetchedCategories;
        _expenseCategories = _categories.where((c) => !c.isIncome).toList();
        _incomeCategories = _categories.where((c) => c.isIncome).toList();
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
  
  // Add a new category
  Future<bool> addCategory({
    required String name,
    String? description,
    required String colorCode,
    String? icon,
    double? budgetLimit,
    int? budgetStartDay,
    bool isIncome = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _categoryService.addCategory(
        name: name,
        description: description,
        colorCode: colorCode,
        icon: icon,
        budgetLimit: budgetLimit,
        budgetStartDay: budgetStartDay,
        isIncome: isIncome,
      );
      
      _isLoading = false;
      
      if (result['success']) {
        // Refresh categories to include the new one
        await fetchCategories();
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
  
  // Get category details
  Future<model.Category?> getCategoryDetails(int categoryId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _categoryService.getCategoryDetails(categoryId);
      
      _isLoading = false;
      
      if (result['success']) {
        final category = model.Category.fromJson(result['data']);
        notifyListeners();
        return category;
      } else {
        _error = result['message'];
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  // Update a category
  Future<bool> updateCategory({
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
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _categoryService.updateCategory(
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
      
      _isLoading = false;
      
      if (result['success']) {
        // Refresh categories to update the list
        await fetchCategories();
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
  
  // Delete a category
  Future<bool> deleteCategory(int categoryId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _categoryService.deleteCategory(categoryId);
      
      _isLoading = false;
      
      if (result['success']) {
        // Remove the category from the lists
        _categories.removeWhere((cat) => cat.id == categoryId);
        _expenseCategories.removeWhere((cat) => cat.id == categoryId);
        _incomeCategories.removeWhere((cat) => cat.id == categoryId);
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
  
  // Update budget limits for multiple categories
  Future<bool> updateBudgets(Map<int, double> budgetLimits) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _categoryService.updateBudgets(budgetLimits);
      
      _isLoading = false;
      
      if (result['success']) {
        // Refresh categories to update budget information
        await fetchCategories();
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
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}