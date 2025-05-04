import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category.dart';
import '../../providers/category_provider.dart';
import '../common/loading_indicator.dart';
import '../../screens/categories/category_form_screen.dart';

/// Used for expense and income forms to pick a category
class CategorySelector extends StatefulWidget {
  final Category? initialCategory;
  final bool isIncome;
  final Function(Category) onCategorySelected;
  
  const CategorySelector({
    super.key,
    this.initialCategory,
    required this.isIncome,
    required this.onCategorySelected,
  });

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  Category? _selectedCategory;
  
  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    
    // Fetch categories if empty
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      if ((widget.isIncome ? categoryProvider.incomeCategories : categoryProvider.expenseCategories).isEmpty) {
        categoryProvider.fetchCategories();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    
    // Get the appropriate categories list
    final categories = widget.isIncome 
        ? categoryProvider.incomeCategories
        : categoryProvider.expenseCategories;
    
    // Only show active categories
    final activeCategories = categories.where((cat) => cat.isActive).toList();
    
    if (categoryProvider.isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: LoadingIndicator(message: 'Loading categories...'),
        ),
      );
    }
    
    if (activeCategories.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Category',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'No ${widget.isIncome ? 'income' : 'expense'} categories found.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: Text('Add ${widget.isIncome ? 'Income' : 'Expense'} Category'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CategoryFormScreen(
                        isExpense: !widget.isIncome,
                      ),
                    ),
                  ).then((_) {
                    // Refresh categories
                    Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
                  });
                },
              ),
            ],
          ),
        ),
      );
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...activeCategories.map((category) {
                  // Parse color from hex string
                  final categoryColor = Color(int.parse(category.colorCode.substring(1, 7), radix: 16) + 0xFF000000);
                  final isSelected = _selectedCategory?.id == category.id;
                  
                  return ChoiceChip(
                    label: Text(category.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                        widget.onCategorySelected(category);
                      }
                    },
                    avatar: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: categoryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          category.icon != null 
                            ? IconData(int.parse(category.icon!), fontFamily: 'MaterialIcons')
                            : widget.isIncome ? Icons.account_balance : Icons.shopping_cart,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                    backgroundColor: theme.cardColor,
                    selectedColor: categoryColor.withOpacity(0.2),
                    checkmarkColor: categoryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? categoryColor : null,
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                  );
                }).toList(),
                
                // Add category chip
                ActionChip(
                  label: const Text('Add New'),
                  avatar: const Icon(Icons.add),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CategoryFormScreen(
                          isExpense: !widget.isIncome,
                        ),
                      ),
                    ).then((_) {
                      // Refresh categories
                      Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}