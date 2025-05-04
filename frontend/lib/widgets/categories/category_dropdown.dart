import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category.dart';
import '../../providers/category_provider.dart';

/// A dropdown widget for selecting categories in forms
class CategoryDropdown extends StatefulWidget {
  final int? initialCategoryId;
  final bool isIncome;
  final String labelText;
  final Function(Category?) onChanged;
  final bool required;

  const CategoryDropdown({
    super.key,
    this.initialCategoryId,
    required this.isIncome,
    this.labelText = 'Category',
    required this.onChanged,
    this.required = true,
  });

  @override
  State<CategoryDropdown> createState() => _CategoryDropdownState();
}

class _CategoryDropdownState extends State<CategoryDropdown> {
  Category? _selectedCategory;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (!_isInitialized) {
      _initializeSelectedCategory();
      _isInitialized = true;
    }
  }

  /// Initialize selected category based on the provided ID
  void _initializeSelectedCategory() {
    if (widget.initialCategoryId != null) {
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      final categoryList = widget.isIncome 
        ? categoryProvider.incomeCategories 
        : categoryProvider.expenseCategories;
      
      _selectedCategory = categoryList.firstWhere(
        (cat) => cat.id == widget.initialCategoryId,
        orElse: () => categoryList.isNotEmpty ? categoryList.first : null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    
    final categories = widget.isIncome 
      ? categoryProvider.incomeCategories 
      : categoryProvider.expenseCategories;
    
    // Filter out inactive categories
    final activeCategories = categories.where((cat) => cat.isActive).toList();
    
    return DropdownButtonFormField<Category>(
      value: _selectedCategory,
      isDense: false,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: widget.labelText,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        suffixIcon: IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () {
            // Navigate to add category screen
            Navigator.of(context).pushNamed(
              '/categories/add',
              arguments: {'isExpense': !widget.isIncome},
            ).then((_) {
              // Refresh categories when returning
              Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
            });
          },
          tooltip: 'Add new category',
        ),
      ),
      hint: Text('Select ${widget.labelText}'),
      validator: widget.required ? (value) {
        if (value == null) {
          return 'Please select a category';
        }
        return null;
      } : null,
      items: activeCategories.map((category) {
        // Parse color from hex string
        final categoryColor = Color(int.parse(category.colorCode.substring(1, 7), radix: 16) + 0xFF000000);
        
        return DropdownMenuItem<Category>(
          value: category,
          child: Row(
            children: [
              Container(
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
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (Category? newValue) {
        setState(() {
          _selectedCategory = newValue;
        });
        widget.onChanged(newValue);
      },
    );
  }
}