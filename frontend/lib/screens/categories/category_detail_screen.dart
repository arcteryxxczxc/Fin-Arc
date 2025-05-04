import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';
import '../../models/category.dart';
import '../../models/expense.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_display.dart';
import '../../widgets/layout/screen_wrapper.dart';
import '../../routes/route_names.dart';
import '../expenses/expense_detail_screen.dart';
import 'category_form_screen.dart';

/// Screen for viewing category details and associated expenses
class CategoryDetailScreen extends StatefulWidget {
  final int categoryId;
  
  const CategoryDetailScreen({super.key, required this.categoryId});
  
  @override
  _CategoryDetailScreenState createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  Category? _category;
  List<Expense> _expenses = [];
  bool _isLoading = true;
  String? _error;
  
  // Date range for filtering expenses
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    _loadCategoryDetails();
  }
  
  /// Load category details and associated expenses
  Future<void> _loadCategoryDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      
      // Get category details
      final category = await categoryProvider.getCategoryDetails(widget.categoryId);
      
      if (category == null) {
        setState(() {
          _error = 'Category not found';
          _isLoading = false;
        });
        return;
      }
      
      // Get category expenses
      final startDateStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final endDateStr = DateFormat('yyyy-MM-dd').format(_endDate);
      
      await expenseProvider.applyFilters(
        categoryId: widget.categoryId,
        startDate: startDateStr,
        endDate: endDateStr
      );
      
      if (mounted) {
        setState(() {
          _category = category;
          _expenses = expenseProvider.expenses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading category details: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  /// Show date range picker and refresh data with new date range
  void _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      
      // Refresh expenses with new date range
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      
      final startDateStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final endDateStr = DateFormat('yyyy-MM-dd').format(_endDate);
      
      await expenseProvider.applyFilters(
        categoryId: widget.categoryId,
        startDate: startDateStr,
        endDate: endDateStr
      );
      
      setState(() {
        _expenses = expenseProvider.expenses;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    
    return ScreenWrapper(
      currentRoute: RouteNames.categoryDetail,
      child: Scaffold(
        appBar: AppBar(title: Text(_category?.name ?? 'Category Details')),
        body: _isLoading 
          ? const LoadingIndicator(message: 'Loading category details...')
          : _error != null
            ? ErrorDisplay(
                error: _error!,
                onRetry: _loadCategoryDetails,
              )
            : _category == null
              ? const Center(child: Text('Category not found'))
              : RefreshIndicator(
                  onRefresh: _loadCategoryDetails,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category overview card
                        _buildCategoryOverview(theme, currencyFormatter),
                        const SizedBox(height: 24),
                        
                        // Budget progress if applicable
                        if (_category!.budgetLimit != null && _category!.budgetLimit! > 0)
                          _buildBudgetProgress(theme, currencyFormatter),
                        
                        const SizedBox(height: 24),
                        
                        // Date range selection
                        _buildDateRangeSelector(theme),
                        const SizedBox(height: 16),
                        
                        // Expense list
                        _buildExpenseList(theme, currencyFormatter),
                      ],
                    ),
                  ),
                ),
        floatingActionButton: _category != null
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CategoryFormScreen(category: _category),
                  ),
                ).then((_) => _loadCategoryDetails());
              },
              tooltip: 'Edit category',
              child: const Icon(Icons.edit),
            )
          : null,
      ),
    );
  }
  
  /// Build the category overview card
  Widget _buildCategoryOverview(ThemeData theme, NumberFormat currencyFormatter) {
    if (_category == null) return const SizedBox.shrink();
    
    // Parse color from hex string
    final categoryColor = Color(int.parse(_category!.colorCode.substring(1, 7), radix: 16) + 0xFF000000);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: categoryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _category!.icon != null 
                      ? IconData(int.parse(_category!.icon!), fontFamily: 'MaterialIcons') 
                      : Icons.category,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _category!.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_category!.description != null && _category!.description!.isNotEmpty)
                        Text(
                          _category!.description!,
                          style: theme.textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            
            // Stats grid
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    title: 'Total Expenses',
                    value: currencyFormatter.format(_category!.currentSpending ?? 0),
                    icon: Icons.account_balance_wallet,
                    color: theme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    title: 'Budget',
                    value: _category!.budgetLimit != null ? currencyFormatter.format(_category!.budgetLimit!) : 'Not set',
                    icon: Icons.attach_money,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    title: 'Expense Count',
                    value: '${_expenses.length}',
                    icon: Icons.receipt_long,
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    title: 'Budget Status',
                    value: _category!.budgetStatus ?? 'N/A',
                    icon: Icons.trending_up,
                    color: _getBudgetStatusColor(_category!.budgetStatus),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build a stat item for the overview card
  Widget _buildStatItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha((0.1 * 255).round()),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
  
  /// Get color for budget status
  Color _getBudgetStatusColor(String? status) {
    if (status == null) return Colors.grey;
    
    switch (status.toLowerCase()) {
      case 'good':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'over':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  /// Build budget progress card
  Widget _buildBudgetProgress(ThemeData theme, NumberFormat currencyFormatter) {
    if (_category == null) return const SizedBox.shrink();
    
    // Skip if no budget
    if (_category!.budgetLimit == null || _category!.budgetLimit! <= 0) {
      return const SizedBox.shrink();
    }
    
    final spent = _category!.currentSpending ?? 0;
    final budget = _category!.budgetLimit!;
    final remaining = budget - spent;
    final percentage = _category!.budgetPercentage ?? 0;
    
    // Determine color based on percentage
    Color progressColor;
    if (percentage >= 100) {
      progressColor = Colors.red;
    } else if (percentage >= 80) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.green;
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget Progress',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Progress bar and percentage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Budget Usage'),
                Text(
                  '${percentage.toInt()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentage / 100 > 1 ? 1 : percentage / 100,
              minHeight: 10,
              backgroundColor: theme.dividerColor.withAlpha((0.1 * 255).round()),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
            const SizedBox(height: 16),
            
            // Spent and remaining
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spent: ${currencyFormatter.format(spent)}',
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  'Remaining: ${currencyFormatter.format(remaining)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: remaining >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build date range selector card
  Widget _buildDateRangeSelector(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date Range',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('MMM d, yyyy').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _showDateRangePicker,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build the list of expenses for this category
  Widget _buildExpenseList(ThemeData theme, NumberFormat currencyFormatter) {
    if (_expenses.isEmpty) {
      return Center(
        child: Column(
          children: [
            const Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No expenses found',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Try changing the date range or add a new expense',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(RouteNames.addExpense);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
            )
          ],
        ),
      );
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Expenses',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_expenses.length} items',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Expense list
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _expenses.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final expense = _expenses[index];
                
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: theme.primaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.receipt,
                      color: theme.primaryColor,
                    ),
                  ),
                  title: Text(
                    expense.description ?? 'Expense',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${DateFormat('MMM d, yyyy').format(DateTime.parse(expense.date))} • ${expense.paymentMethod ?? 'Not specified'}',
                  ),
                  trailing: Text(
                    expense.formattedAmount,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.error,
                    ),
                  ),
                  onTap: () {
                    // Navigate to expense details
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ExpenseDetailScreen(expenseId: expense.id),
                      ),
                    ).then((_) => _loadCategoryDetails());
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}