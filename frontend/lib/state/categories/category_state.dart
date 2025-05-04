// lib/state/category_state.dart
import 'package:flutter/foundation.dart' hide Category;
import '/../models/category.dart';

// Base state for categories
@immutable
abstract class CategoryState {
  final List<Category> categories;
  final List<Category> expenseCategories;
  final List<Category> incomeCategories;
  final bool isLoading;
  final String? error;

  const CategoryState({
    required this.categories,
    required this.expenseCategories,
    required this.incomeCategories,
    required this.isLoading,
    this.error,
  });
}

// Initial state when the app starts
class CategoryInitialState extends CategoryState {
  const CategoryInitialState()
      : super(
          categories: const [],
          expenseCategories: const [],
          incomeCategories: const [],
          isLoading: false,
        );
}

// Loading state while fetching categories
class CategoryLoadingState extends CategoryState {
  const CategoryLoadingState({
    required List<Category> categories,
    required List<Category> expenseCategories,
    required List<Category> incomeCategories,
  }) : super(
          categories: categories,
          expenseCategories: expenseCategories,
          incomeCategories: incomeCategories,
          isLoading: true,
        );

  // Factory constructor to create from another state
  factory CategoryLoadingState.from(CategoryState state) {
    return CategoryLoadingState(
      categories: state.categories,
      expenseCategories: state.expenseCategories,
      incomeCategories: state.incomeCategories,
    );
  }
}

// Loaded state when categories are successfully fetched
class CategoryLoadedState extends CategoryState {
  const CategoryLoadedState({
    required List<Category> categories,
    required List<Category> expenseCategories,
    required List<Category> incomeCategories,
  }) : super(
          categories: categories,
          expenseCategories: expenseCategories,
          incomeCategories: incomeCategories,
          isLoading: false,
        );
}

// Error state when there's an issue fetching or manipulating categories
class CategoryErrorState extends CategoryState {
  const CategoryErrorState({
    required List<Category> categories,
    required List<Category> expenseCategories,
    required List<Category> incomeCategories,
    required String error,
  }) : super(
          categories: categories,
          expenseCategories: expenseCategories,
          incomeCategories: incomeCategories,
          isLoading: false,
          error: error,
        );

  // Factory constructor to create from another state
  factory CategoryErrorState.from(CategoryState state, String error) {
    return CategoryErrorState(
      categories: state.categories,
      expenseCategories: state.expenseCategories,
      incomeCategories: state.incomeCategories,
      error: error,
    );
  }
}