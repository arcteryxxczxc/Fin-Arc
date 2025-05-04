import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';
import '../../models/category.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_display.dart';
import '../../widgets/categories/category_budget_card.dart';

/// Screen for managing budget limits for expense categories
class CategoryBudgetScreen extends StatefulWidget {
  const CategoryBudgetScreen({super.key});

  @override
  _CategoryBudgetScreenState createState() => _CategoryBudgetScreenState();
}

class _CategoryBudgetScreenState extends State<CategoryBudgetScreen> {
  final Map<int, double> _budgetChanges = {};
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    
    // Fetch categories when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
    });
  }

  /// Update budget for a specific category and track the change
  void _updateBudget(Category category, double newBudget) {
    setState(() {
      _budgetChanges[category.id] = newBudget;
      _hasChanges = true;
    });
  }

  /// Save all budget changes to the backend
  Future<void> _saveBudgets() async {
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    
    final result = await categoryProvider.updateBudgets(_budgetChanges);
    
    if (result && mounted) {
      setState(() {
        _budgetChanges.clear();
        _hasChanges = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget limits updated successfully')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(categoryProvider.error ?? 'Failed to update budget limits'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    
    // Get only active expense categories
    final expenseCategories = categoryProvider.expenseCategories
        .where((cat) => cat.isActive)
        .toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Budgets'),
        actions: [
          // Show save button only when there are changes to save
          if (_hasChanges)
            TextButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save'),
              onPressed: _saveBudgets,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
        ],
      ),
      body: categoryProvider.isLoading
        ? const LoadingIndicator(message: 'Loading categories...')
        : categoryProvider.error != null
          ? ErrorDisplay(
              error: categoryProvider.error!,
              onRetry: () => categoryProvider.fetchCategories(),
            )
          : expenseCategories.isEmpty
            ? _buildEmptyState()
            : _buildCategoriesList(expenseCategories),
    );
  }
  
  /// Build the empty state when no expense categories exist
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No expense categories found',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add expense categories to set budget limits',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Category'),
            onPressed: () {
              Navigator.of(context).pushNamed('/categories/add');
            },
          ),
        ],
      ),
    );
  }
  
  /// Build the list of categories with budget fields
  Widget _buildCategoriesList(List<Category> categories) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Set monthly budget limits for each category',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        ...categories.map((category) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: CategoryBudgetCard(
              category: category,
              onBudgetChanged: (newBudget) => _updateBudget(category, newBudget),
            ),
          );
        }).toList(),
        
        const SizedBox(height: 16),
        
        // Show save button at the bottom as well for convenience
        if (_hasChanges)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save Budget Changes'),
              onPressed: _saveBudgets,
            ),
          ),
      ],
    );
  }
}