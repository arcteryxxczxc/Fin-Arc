// lib/state/category_notifier.dart
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/../models/category.dart';
import '/../services/category_service.dart';
import 'category_state.dart';

// Category notifier that manages category state
class CategoryNotifier extends StateNotifier<CategoryState> {
  final CategoryService _categoryService = CategoryService();

  CategoryNotifier() : super(const CategoryInitialState());

  // Initialize categories
  Future<void> fetchCategories({
    bool includeInactive = false,
  }) async {
    // Set state to loading
    state = CategoryLoadingState.from(state);

    try {
      // Fetch all categories (both expense and income)
      final result = await _categoryService.getCategories(
        includeInactive: includeInactive,
        onlyExpense: false, // Get both expense and income categories
      );

      if (result['success']) {
        // Convert raw data to Category objects
        List<Category> fetchedCategories = [];
        for (final item in result['data']) {
          fetchedCategories.add(Category.fromJson(item));
        }

        // Split into expense and income categories
        final expenseCategories = fetchedCategories.where((c) => !c.isIncome).toList();
        final incomeCategories = fetchedCategories.where((c) => c.isIncome).toList();

        // Update state with loaded categories
        state = CategoryLoadedState(
          categories: fetchedCategories,
          expenseCategories: expenseCategories,
          incomeCategories: incomeCategories,
        );
      } else {
        // Handle error
        state = CategoryErrorState.from(state, result['message'] ?? 'Failed to load categories');
      }
    } catch (e) {
      // Handle exception
      state = CategoryErrorState.from(state, e.toString());
    }
  }

  // Get category details
  Future<Category?> getCategoryDetails(int categoryId) async {
    try {
      final result = await _categoryService.getCategoryDetails(categoryId);

      if (result['success']) {
        return Category.fromJson(result['data']);
      } else {
        return null;
      }
    } catch (e) {
      return null;
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
    state = CategoryLoadingState.from(state);

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

      if (result['success']) {
        // Refresh categories to include the new one
        await fetchCategories();
        return true;
      } else {
        state = CategoryErrorState.from(state, result['message'] ?? 'Failed to add category');
        return false;
      }
    } catch (e) {
      state = CategoryErrorState.from(state, e.toString());
      return false;
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
    state = CategoryLoadingState.from(state);

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

      if (result['success']) {
        // Refresh categories to update the list
        await fetchCategories();
        return true;
      } else {
        state = CategoryErrorState.from(state, result['message'] ?? 'Failed to update category');
        return false;
      }
    } catch (e) {
      state = CategoryErrorState.from(state, e.toString());
      return false;
    }
  }

  // Delete a category
  Future<bool> deleteCategory(int categoryId) async {
    state = CategoryLoadingState.from(state);

    try {
      final result = await _categoryService.deleteCategory(categoryId);

      if (result['success']) {
        // Remove the deleted category from the current state
        final updatedCategories = state.categories.where((cat) => cat.id != categoryId).toList();
        final updatedExpenseCategories = state.expenseCategories.where((cat) => cat.id != categoryId).toList();
        final updatedIncomeCategories = state.incomeCategories.where((cat) => cat.id != categoryId).toList();

        state = CategoryLoadedState(
          categories: updatedCategories,
          expenseCategories: updatedExpenseCategories,
          incomeCategories: updatedIncomeCategories,
        );
        return true;
      } else {
        state = CategoryErrorState.from(state, result['message'] ?? 'Failed to delete category');
        return false;
      }
    } catch (e) {
      state = CategoryErrorState.from(state, e.toString());
      return false;
    }
  }

  // Update budget limits for multiple categories
  Future<bool> updateBudgets(Map<int, double> budgetLimits) async {
    state = CategoryLoadingState.from(state);

    try {
      final result = await _categoryService.updateBudgets(budgetLimits);

      if (result['success']) {
        // Refresh categories to update budget information
        await fetchCategories();
        return true;
      } else {
        state = CategoryErrorState.from(state, result['message'] ?? 'Failed to update budgets');
        return false;
      }
    } catch (e) {
      state = CategoryErrorState.from(state, e.toString());
      return false;
    }
  }

  // Clear error
  void clearError() {
    if (state.error != null) {
      state = CategoryLoadedState(
        categories: state.categories,
        expenseCategories: state.expenseCategories,
        incomeCategories: state.incomeCategories,
      );
    }
  }
}

// Provider for category state
final categoryProvider = StateNotifierProvider<CategoryNotifier, CategoryState>((ref) {
  return CategoryNotifier();
});