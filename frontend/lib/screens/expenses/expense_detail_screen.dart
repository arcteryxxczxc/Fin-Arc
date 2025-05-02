import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/expense.dart';
import '../../models/category.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_display.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final int expenseId;
  
  const ExpenseDetailScreen({super.key, required this.expenseId});
  
  @override
  _ExpenseDetailScreenState createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  Expense? _expense;
  Category? _category;
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadExpenseDetails();
  }
  
  Future<void> _loadExpenseDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      
      // Get expense details
      final result = await expenseProvider.getExpenseDetails(widget.expenseId);
      if (result['success']) {
        final expense = result['expense'] as Expense;
        
        // Get category if available
        Category? category;
        if (expense.categoryId != null) {
          final categories = categoryProvider.categories;
          if (categories.isNotEmpty) {
            category = categories.firstWhere(
              (c) => c.id == expense.categoryId,
              orElse: () => null,
            );
          }
          
          // If category not found in local cache, fetch it
          category ??= await categoryProvider.getCategoryDetails(expense.categoryId!);
        }
        
        if (mounted) {
          setState(() {
            _expense = expense;
            _category = category;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to load expense details';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading expense details: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  void _editExpense() {
    // Navigate to edit expense screen
    // This will be implemented in a future PR
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit expense feature coming soon')),
    );
  }
  
  void _deleteExpense() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text(
          'Are you sure you want to delete this expense? This action cannot be undone.',
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
            onPressed: () async {
              Navigator.of(ctx).pop();
              
              // Delete the expense
              final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
              final success = await expenseProvider.deleteExpense(widget.expenseId);
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Expense deleted successfully')),
                );
                Navigator.of(context).pop(); // Return to previous screen
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(expenseProvider.error ?? 'Failed to delete expense'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Expense Details')),
        body: const LoadingIndicator(message: 'Loading expense details...'),
      );
    }
    
    if (_error != null || _expense == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Expense Details')),
        body: ErrorDisplay(
          error: _error ?? 'Failed to load expense',
          onRetry: _loadExpenseDetails,
        ),
      );
    }
    
    // Parse category color if available
    Color categoryColor = theme.primaryColor;
    if (_category != null && _category!.colorCode.isNotEmpty) {
      categoryColor = Color(int.parse(_category!.colorCode.substring(1, 7), radix: 16) + 0xFF000000);
    }
    
    // Format date and time
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final formattedDate = dateFormat.format(DateTime.parse(_expense!.date));
    
    String formattedTime = '';
    if (_expense!.time != null && _expense!.time!.isNotEmpty) {
      final timeComponents = _expense!.time!.split(':');
      if (timeComponents.length >= 2) {
        final hour = int.tryParse(timeComponents[0]) ?? 0;
        final minute = int.tryParse(timeComponents[1]) ?? 0;
        formattedTime = DateFormat('h:mm a').format(
          DateTime(2022, 1, 1, hour, minute)
        );
      } else {
        formattedTime = _expense!.time!;
      }
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editExpense,
            tooltip: 'Edit expense',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteExpense,
            tooltip: 'Delete expense',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount and category card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Amount
                    Text(
                      _expense!.formattedAmount,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Category
                    if (_category != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: categoryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _category!.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ] else if (_expense!.categoryName != null) ...[
                      Text(
                        _expense!.categoryName!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ] else ...[
                      Text(
                        'No Category',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Main details
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailItem(
                      icon: Icons.description,
                      title: 'Description',
                      value: _expense!.description ?? 'No description',
                    ),
                    const Divider(),
                    _buildDetailItem(
                      icon: Icons.calendar_today,
                      title: 'Date',
                      value: formattedDate,
                    ),
                    if (_expense!.time != null && _expense!.time!.isNotEmpty) ...[
                      const Divider(),
                      _buildDetailItem(
                        icon: Icons.access_time,
                        title: 'Time',
                        value: formattedTime,
                      ),
                    ],
                    if (_expense!.paymentMethod != null) ...[
                      const Divider(),
                      _buildDetailItem(
                        icon: Icons.payment,
                        title: 'Payment Method',
                        value: _expense!.paymentMethod!,
                      ),
                    ],
                    if (_expense!.location != null && _expense!.location!.isNotEmpty) ...[
                      const Divider(),
                      _buildDetailItem(
                        icon: Icons.location_on,
                        title: 'Location',
                        value: _expense!.location!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Additional information
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recurring info
                    if (_expense!.isRecurring) ...[
                      _buildDetailItem(
                        icon: Icons.repeat,
                        title: 'Recurring Expense',
                        value: _expense!.recurringType != null
                            ? 'Repeats ${_formatRecurringType(_expense!.recurringType!)}'
                            : 'Recurring',
                        valueColor: theme.primaryColor,
                      ),
                      const Divider(),
                    ],
                    
                    // Notes
                    if (_expense!.notes != null && _expense!.notes!.isNotEmpty) ...[
                      _buildDetailItem(
                        icon: Icons.note,
                        title: 'Notes',
                        value: _expense!.notes!,
                        isMultiLine: true,
                      ),
                      const Divider(),
                    ],
                    
                    // Receipt
                    if (_expense!.hasReceipt) ...[
                      _buildDetailItem(
                        icon: Icons.receipt,
                        title: 'Receipt',
                        value: 'Receipt available',
                        valueColor: theme.primaryColor,
                      ),
                      const Divider(),
                    ],
                    
                    // Created/Updated dates
                    _buildDetailItem(
                      icon: Icons.access_time,
                      title: 'Created',
                      value: _formatTimestamp(_expense!.createdAt),
                      valueStyle: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (_expense!.updatedAt != _expense!.createdAt) ...[
                      const Divider(),
                      _buildDetailItem(
                        icon: Icons.update,
                        title: 'Last Updated',
                        value: _formatTimestamp(_expense!.updatedAt),
                        valueStyle: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
    Color? iconColor,
    Color? valueColor,
    TextStyle? valueStyle,
    bool isMultiLine = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? Theme.of(context).primaryColor).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor ?? Theme.of(context).primaryColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: valueStyle ?? TextStyle(
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatRecurringType(String type) {
    switch (type.toLowerCase()) {
      case 'daily':
        return 'daily';
      case 'weekly':
        return 'weekly';
      case 'monthly':
        return 'monthly';
      case 'yearly':
        return 'yearly';
      default:
        return type;
    }
  }
  
  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return DateFormat('MMM d, yyyy • h:mm a').format(dateTime);
    } catch (e) {
      return timestamp;
    }
  }
}