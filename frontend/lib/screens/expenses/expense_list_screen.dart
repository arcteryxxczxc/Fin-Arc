import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/expense.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_display.dart';
import 'expense_detail_screen.dart';
import 'add_expense_screen.dart';
import '../../widgets/layout/screen_wrapper.dart';
import '../../routes/route_names.dart';

class ExpenseListScreen extends StatefulWidget {
  @override
  _ExpenseListScreenState createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final _scrollController = ScrollController();
  String? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _searchQuery;
  String _sortBy = 'date'; // 'date', 'amount', 'category'
  bool _sortAscending = false;
  
  @override
  void initState() {
    super.initState();
    
    // Set default date range to current month
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
    
    // Load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExpenses();
      Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
    });
    
    // Add scroll listener for pagination
    _scrollController.addListener(_scrollListener);
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreExpenses();
    }
  }
  
  Future<void> _loadExpenses() async {
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    
    // Convert category name to ID if selected
    int? categoryId;
    if (_selectedCategory != null) {
      final categories = Provider.of<CategoryProvider>(context, listen: false).categories;
      final category = categories.firstWhere(
        (c) => c.name == _selectedCategory,
        orElse: () => null,
      );
      if (category != null) {
        categoryId = category.id;
      }
    }
    
    // Format dates
    String? startDateStr, endDateStr;
    if (_startDate != null) {
      startDateStr = DateFormat('yyyy-MM-dd').format(_startDate!);
    }
    if (_endDate != null) {
      endDateStr = DateFormat('yyyy-MM-dd').format(_endDate!);
    }
    
    await expenseProvider.fetchExpenses(
      refresh: true,
      categoryId: categoryId,
      startDate: startDateStr,
      endDate: endDateStr,
      search: _searchQuery,
    );
    
    // Apply sorting
    _sortExpenses();
  }
  
  Future<void> _loadMoreExpenses() async {
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    
    // Only load more if there are more pages
    if (expenseProvider.hasMorePages) {
      await expenseProvider.loadMoreExpenses();
      
      // Apply sorting to the new data
      _sortExpenses();
    }
  }
  
  void _sortExpenses() {
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final expenses = List<Expense>.from(expenseProvider.expenses);
    
    switch (_sortBy) {
      case 'date':
        expenses.sort((a, b) {
          final dateA = DateTime.parse(a.date);
          final dateB = DateTime.parse(b.date);
          return _sortAscending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
        });
        break;
      case 'amount':
        expenses.sort((a, b) {
          return _sortAscending ? a.amount.compareTo(b.amount) : b.amount.compareTo(a.amount);
        });
        break;
      case 'category':
        expenses.sort((a, b) {
          final categoryA = a.categoryName ?? 'Uncategorized';
          final categoryB = b.categoryName ?? 'Uncategorized';
          return _sortAscending ? categoryA.compareTo(categoryB) : categoryB.compareTo(categoryA);
        });
        break;
    }
    
    setState(() {}); // Refresh UI with sorted data
  }
  
  void _showFilterDialog() {
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final categories = categoryProvider.expenseCategories;
    
    // Create a temporary copy of the current filters
    String? tempCategory = _selectedCategory;
    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Filter Expenses'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category filter
                Text(
                  'Category',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  value: tempCategory,
                  onChanged: (value) {
                    setState(() {
                      tempCategory = value;
                    });
                  },
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Categories'),
                    ),
                    ...categories.map((category) => DropdownMenuItem<String?>(
                      value: category.name,
                      child: Text(category.name),
                    )).toList(),
                  ],
                ),
                SizedBox(height: 16),
                
                // Date range filter
                Text(
                  'Date Range',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: tempStartDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              tempStartDate = picked;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            labelText: 'From',
                          ),
                          child: Text(
                            tempStartDate != null
                                ? DateFormat('MM/dd/yyyy').format(tempStartDate!)
                                : 'Select Date',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: tempEndDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              tempEndDate = picked;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            labelText: 'To',
                          ),
                          child: Text(
                            tempEndDate != null
                                ? DateFormat('MM/dd/yyyy').format(tempEndDate!)
                                : 'Select Date',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                // Quick date range buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _quickDateRangeButton(
                      label: 'This Month',
                      onTap: () {
                        final now = DateTime.now();
                        setState(() {
                          tempStartDate = DateTime(now.year, now.month, 1);
                          tempEndDate = DateTime(now.year, now.month + 1, 0);
                        });
                      },
                    ),
                    _quickDateRangeButton(
                      label: 'Last Month',
                      onTap: () {
                        final now = DateTime.now();
                        setState(() {
                          tempStartDate = DateTime(now.year, now.month - 1, 1);
                          tempEndDate = DateTime(now.year, now.month, 0);
                        });
                      },
                    ),
                    _quickDateRangeButton(
                      label: 'This Year',
                      onTap: () {
                        final now = DateTime.now();
                        setState(() {
                          tempStartDate = DateTime(now.year, 1, 1);
                          tempEndDate = DateTime(now.year, 12, 31);
                        });
                      },
                    ),
                    _quickDateRangeButton(
                      label: 'Clear',
                      onTap: () {
                        setState(() {
                          tempStartDate = null;
                          tempEndDate = null;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = tempCategory;
                  _startDate = tempStartDate;
                  _endDate = tempEndDate;
                });
                Navigator.of(ctx).pop();
                _loadExpenses();
              },
              child: Text('Apply Filters'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _quickDateRangeButton({required String label, required VoidCallback onTap}) {
    return ElevatedButton(
      onPressed: onTap,
      child: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
  
  void _showSortDialog() {
    final options = {
      'date': 'Date',
      'amount': 'Amount',
      'category': 'Category',
    };
    
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Sort By'),
        children: options.entries.map((entry) {
          final isSelected = _sortBy == entry.key;
          
          return ListTile(
            title: Text(entry.value),
            trailing: isSelected
                ? Icon(
                    _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    color: Theme.of(context).primaryColor,
                  )
                : null,
            selected: isSelected,
            onTap: () {
              setState(() {
                if (_sortBy == entry.key) {
                  // Toggle direction if the same field
                  _sortAscending = !_sortAscending;
                } else {
                  // Reset direction for new field
                  _sortBy = entry.key;
                  _sortAscending = entry.key != 'date'; // Default: date DESC, others ASC
                }
              });
              Navigator.of(ctx).pop();
              _sortExpenses();
            },
          );
        }).toList(),
      ),
    );
  }
  
  void _showSearchBar() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Search Expenses'),
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter search term',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            _searchQuery = value.isNotEmpty ? value : null;
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _loadExpenses();
            },
            child: Text('Search'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final expenses = expenseProvider.expenses;
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Expenses'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: _showSearchBar,
            tooltip: 'Search expenses',
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter expenses',
          ),
          IconButton(
            icon: Icon(Icons.sort),
            onPressed: _showSortDialog,
            tooltip: 'Sort expenses',
          ),
        ],
      ),
      body: Column(
        children: [
          // Active filters display
          if (_selectedCategory != null || _startDate != null || _endDate != null || _searchQuery != null) 
            _buildActiveFilters(),
          
          // Expenses list
          Expanded(
            child: _buildExpensesList(theme, expenseProvider, expenses, currencyFormatter),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddExpenseScreen(),
            ),
          ).then((_) => _loadExpenses());
        },
        child: Icon(Icons.add),
        tooltip: 'Add expense',
      ),
    );
  }
  
  Widget _buildActiveFilters() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Filters:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_selectedCategory != null)
                _buildFilterChip(
                  label: 'Category: $_selectedCategory',
                  onRemove: () {
                    setState(() {
                      _selectedCategory = null;
                    });
                    _loadExpenses();
                  },
                ),
              if (_startDate != null && _endDate != null)
                _buildFilterChip(
                  label: 'Date: ${DateFormat('MM/dd/yyyy').format(_startDate!)} - ${DateFormat('MM/dd/yyyy').format(_endDate!)}',
                  onRemove: () {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                    });
                    _loadExpenses();
                  },
                ),
              if (_searchQuery != null)
                _buildFilterChip(
                  label: 'Search: $_searchQuery',
                  onRemove: () {
                    setState(() {
                      _searchQuery = null;
                    });
                    _loadExpenses();
                  },
                ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedCategory = null;
                    _startDate = null;
                    _endDate = null;
                    _searchQuery = null;
                  });
                  _loadExpenses();
                },
                child: Text('Clear All'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: Size(0, 0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip({required String label, required VoidCallback onRemove}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            customBorder: CircleBorder(),
            child: Icon(
              Icons.close,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildExpensesList(
    ThemeData theme, 
    ExpenseProvider expenseProvider, 
    List<Expense> expenses,
    NumberFormat currencyFormatter,
  ) {
    if (expenseProvider.isLoading && expenses.isEmpty) {
      return LoadingIndicator(message: 'Loading expenses...');
    }
    
    if (expenseProvider.error != null && expenses.isEmpty) {
      return ErrorDisplay(
        error: expenseProvider.error!,
        onRetry: _loadExpenses,
      );
    }
    
    if (expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No expenses found',
              style: theme.textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            Text(
              'Add your first expense or change filters',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadExpenses,
      child: ListView.separated(
        controller: _scrollController,
        padding: EdgeInsets.all(16),
        itemCount: expenses.length + (expenseProvider.hasMorePages ? 1 : 0),
        separatorBuilder: (context, index) => Divider(),
        itemBuilder: (context, index) {
          // Show loading indicator at the bottom
          if (index == expenses.length) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          final expense = expenses[index];
          
          // Get category color if available
          Color categoryColor = theme.primaryColor;
          if (expense.categoryColor != null && expense.categoryColor!.isNotEmpty) {
            categoryColor = Color(int.parse(expense.categoryColor!.substring(1, 7), radix: 16) + 0xFF000000);
          }
          
          return ListTile(
            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
            leading: CircleAvatar(
              backgroundColor: expense.categoryId != null ? categoryColor.withOpacity(0.2) : Colors.grey[300],
              child: Icon(
                Icons.receipt,
                color: expense.categoryId != null ? categoryColor : Colors.grey,
              ),
            ),
            title: Text(
              expense.description ?? 'Expense',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMM d, yyyy').format(DateTime.parse(expense.date)),
                ),
                if (expense.categoryName != null)
                  Text(
                    expense.categoryName!,
                    style: TextStyle(
                      color: categoryColor,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            trailing: Text(
              expense.formattedAmount,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.error,
              ),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ExpenseDetailScreen(expenseId: expense.id),
                ),
              ).then((_) => _loadExpenses());
            },
          );
        },
      ),
    );
  }
}