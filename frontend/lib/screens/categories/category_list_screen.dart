// lib/screens/categories/updated_category_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';
import '../../models/category.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_display.dart';
import '../../widgets/categories/category_card.dart';
import '../../widgets/layout/screen_wrapper.dart';
import '../../routes/route_names.dart';
import 'category_detail_screen.dart';
import 'category_form_screen.dart';
import 'category_budget_screen.dart';

class UpdatedCategoryListScreen extends StatefulWidget {
  const UpdatedCategoryListScreen({super.key});

  @override
  _UpdatedCategoryListScreenState createState() => _UpdatedCategoryListScreenState();
}

class _UpdatedCategoryListScreenState extends State<UpdatedCategoryListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _includeInactive = false;
  String _sortBy = 'name'; // 'name', 'budget', 'spent'
  bool _sortAscending = true;
  
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
  
  // Sort categories based on current sort settings
  List<Category> _sortCategories(List<Category> categories) {
    switch (_sortBy) {
      case 'name':
        categories.sort((a, b) => _sortAscending 
          ? a.name.compareTo(b.name) 
          : b.name.compareTo(a.name));
        break;
      case 'budget':
        categories.sort((a, b) {
          final budgetA = a.budgetLimit ?? 0;
          final budgetB = b.budgetLimit ?? 0;
          return _sortAscending 
            ? budgetA.compareTo(budgetB) 
            : budgetB.compareTo(budgetA);
        });
        break;
      case 'spent':
        categories.sort((a, b) {
          final spentA = a.currentSpending ?? 0;
          final spentB = b.currentSpending ?? 0;
          return _sortAscending 
            ? spentA.compareTo(spentB) 
            : spentB.compareTo(spentA);
        });
        break;
    }
    return categories;
  }
  
  void _showSortMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sort Categories By',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSortOption(ctx, 'name', 'Name'),
            _buildSortOption(ctx, 'budget', 'Budget Amount'),
            _buildSortOption(ctx, 'spent', 'Spending'),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Sort Order:'),
                const SizedBox(width: 16),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      label: Text('Ascending'),
                      icon: Icon(Icons.arrow_upward),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text('Descending'),
                      icon: Icon(Icons.arrow_downward),
                    ),
                  ],
                  selected: {_sortAscending},
                  onSelectionChanged: (Set<bool> selected) {
                    setState(() {
                      _sortAscending = selected.first;
                    });
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSortOption(BuildContext context, String value, String label) {
    final isSelected = _sortBy == value;
    
    return ListTile(
      leading: Icon(
        Icons.sort,
        color: isSelected ? Theme.of(context).primaryColor : null,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).primaryColor : null,
        ),
      ),
      trailing: isSelected 
        ? Icon(
            _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
            color: Theme.of(context).primaryColor,
          )
        : null,
      onTap: () {
        setState(() {
          if (_sortBy == value) {
            // Toggle sort direction if same field
            _sortAscending = !_sortAscending;
          } else {
            // New sort field
            _sortBy = value;
            _sortAscending = true;
          }
        });
        Navigator.of(context).pop();
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    
    return ScreenWrapper(
      currentRoute: RouteNames.categoryList,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Categories'),
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
            // Budget management
            IconButton(
              icon: const Icon(Icons.account_balance_wallet),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CategoryBudgetScreen(),
                  ),
                );
              },
              tooltip: 'Manage budgets',
            ),
            // Sort menu
            IconButton(
              icon: const Icon(Icons.sort),
              onPressed: () => _showSortMenu(context),
              tooltip: 'Sort categories',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Expense Categories'),
              Tab(text: 'Income Categories'),
            ],
          ),
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
                    _sortCategories([...categoryProvider.expenseCategories]),
                    theme,
                    isExpense: true,
                  ),
                  
                  // Income Categories
                  _buildCategoryList(
                    _sortCategories([...categoryProvider.incomeCategories]),
                    theme,
                    isExpense: false,
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          heroTag: "addCategoryButton",
          onPressed: () {
            _showAddCategoryDialog(context);
          },
          tooltip: 'Add category',
          child: const Icon(Icons.add),
        ),
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
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: Text('Add ${isExpense ? 'Expense' : 'Income'} Category'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CategoryFormScreen(
                      isExpense: isExpense,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<CategoryProvider>(context, listen: false)
          .fetchCategories(includeInactive: _includeInactive);
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          
          return CategoryCard(
            category: category,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CategoryDetailScreen(categoryId: category.id),
                ),
              );
            },
            onEdit: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CategoryFormScreen(category: category),
                ),
              );
            },
            onDelete: () {
              _showDeleteConfirmationDialog(context, category);
            },
            showBudget: isExpense,
          );
        },
      ),
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