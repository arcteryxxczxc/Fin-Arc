import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/category_provider.dart';
import '../../models/category.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_display.dart';
import 'category_detail_screen.dart';
import 'category_form_screen.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  _CategoryListScreenState createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _includeInactive = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Expense Categories'),
            Tab(text: 'Income Categories'),
          ],
        ),
        actions: [
          // Filter toggle
          IconButton(
            icon: Icon(_includeInactive ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                _includeInactive = !_includeInactive;
              });
              categoryProvider.fetchCategories(includeInactive: _includeInactive);
            },
            tooltip: _includeInactive ? 'Hide inactive' : 'Show inactive',
          ),
          // Sort menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              // Implement sorting logic
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sorting by $value')),
              );
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'name',
                child: Text('Sort by name'),
              ),
              const PopupMenuItem(
                value: 'budget',
                child: Text('Sort by budget'),
              ),
              const PopupMenuItem(
                value: 'spent',
                child: Text('Sort by spending'),
              ),
            ],
            tooltip: 'Sort categories',
          ),
        ],
      ),
      body: categoryProvider.isLoading
        ? const LoadingIndicator(message: 'Loading categories...')
        : categoryProvider.error != null
          ? ErrorDisplay(
              error: categoryProvider.error!,
              onRetry: () => categoryProvider.fetchCategories(includeInactive: _includeInactive),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // Expense Categories
                _buildCategoryList(
                  categoryProvider.expenseCategories,
                  theme,
                  isExpense: true,
                ),
                
                // Income Categories
                _buildCategoryList(
                  categoryProvider.incomeCategories,
                  theme,
                  isExpense: false,
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddCategoryDialog(context);
        },
        tooltip: 'Add category',
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildCategoryList(List<Category> categories, ThemeData theme, {required bool isExpense}) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.category_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${isExpense ? 'expense' : 'income'} categories found',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add a new category',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }
    
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final category = categories[index];
        
        // Parse color from hex string
        final categoryColor = Color(int.parse(category.colorCode.substring(1, 7), radix: 16) + 0xFF000000);
        
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CategoryDetailScreen(categoryId: category.id),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: categoryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            category.icon != null 
                              ? IconData(int.parse(category.icon!), fontFamily: 'MaterialIcons')
                              : isExpense ? Icons.shopping_cart : Icons.account_balance,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    category.name,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (!category.isActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'Inactive',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (category.description != null && category.description!.isNotEmpty)
                              Text(
                                category.description!,
                                style: theme.textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (isExpense && category.budgetLimit != null && category.budgetLimit! > 0) ...[
                    const SizedBox(height: 16),
                    _buildBudgetProgress(category, theme, currencyFormatter),
                  ],
                  const SizedBox(height: 8),
                  // Actions row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => CategoryFormScreen(category: category),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Delete'),
                        onPressed: () {
                          _showDeleteConfirmationDialog(context, category);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildBudgetProgress(Category category, ThemeData theme, NumberFormat currencyFormatter) {
    final budgetLimit = category.budgetLimit ?? 0;
    final spent = category.currentSpending ?? 0;
    final percentage = category.budgetPercentage ?? 0;
    
    // Determine color based on percentage
    Color progressColor;
    if (percentage >= 100) {
      progressColor = Colors.red;
    } else if (percentage >= 80) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.green;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Budget: ${currencyFormatter.format(budgetLimit)}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              '${percentage.toInt()}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: progressColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage / 100 > 1 ? 1 : percentage / 100,
          minHeight: 6,
          backgroundColor: theme.dividerColor.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Spent: ${currencyFormatter.format(spent)}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Remaining: ${currencyFormatter.format(budgetLimit - spent)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: budgetLimit - spent >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  void _showAddCategoryDialog(BuildContext context) {
    final currentTab = _tabController.index;
    final isExpense = currentTab == 0;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CategoryFormScreen(
          isExpense: isExpense,
        ),
      ),
    );
  }
  
  void _showDeleteConfirmationDialog(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${category.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              
              // Delete the category
              Provider.of<CategoryProvider>(context, listen: false)
                .deleteCategory(category.id)
                .then((success) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Category deleted successfully')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          Provider.of<CategoryProvider>(context, listen: false).error ?? 
                          'Failed to delete category',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                });
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}