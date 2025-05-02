import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/income_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/income.dart';
import '../../models/category.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_display.dart';
import 'edit_income_screen.dart';

class IncomeDetailScreen extends StatefulWidget {
  final int incomeId;
  
  const IncomeDetailScreen({super.key, required this.incomeId});
  
  @override
  _IncomeDetailScreenState createState() => _IncomeDetailScreenState();
}

class _IncomeDetailScreenState extends State<IncomeDetailScreen> {
  Income? _income;
  Category? _category;
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadIncomeDetails();
  }
  
  Future<void> _loadIncomeDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Access providers
      final incomeProvider = Provider.of<IncomeProvider>(context, listen: false);
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      
      // Get income details from API
      final result = await incomeProvider.getIncomeDetails(widget.incomeId);
      
      if (result['success']) {
        final income = Income.fromJson(result['data']['income']);
        
        // Get category if available
        Category? category;
        if (income.categoryId != null) {
          // Check if categories are already loaded
          if (categoryProvider.categories.isNotEmpty) {
            category = categoryProvider.categories.firstWhere(
              (cat) => cat.id == income.categoryId,
              orElse: () => null,
            );
          }
          
          // If not found in local cache, fetch from API
          category ??= await categoryProvider.getCategoryDetails(income.categoryId!);
        }
        
        if (mounted) {
          setState(() {
            _income = income;
            _category = category;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to load income details';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading income details: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  void _editIncome() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditIncomeScreen(incomeId: widget.incomeId),
      ),
    ).then((_) => _loadIncomeDetails());
  }
  
  void _deleteIncome() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Income'),
        content: const Text(
          'Are you sure you want to delete this income entry? This action cannot be undone.',
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
            child: const Text('Delete'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              
              // Delete the income
              final incomeProvider = Provider.of<IncomeProvider>(context, listen: false);
              final success = await incomeProvider.deleteIncome(widget.incomeId);
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Income deleted successfully')),
                );
                Navigator.of(context).pop(); // Return to previous screen
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(incomeProvider.error ?? 'Failed to delete income'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Income Details')),
        body: const LoadingIndicator(message: 'Loading income details...'),
      );
    }
    
    if (_error != null || _income == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Income Details')),
        body: ErrorDisplay(
          error: _error ?? 'Failed to load income details',
          onRetry: _loadIncomeDetails,
        ),
      );
    }
    
    // Parse category color if available
    Color categoryColor = theme.primaryColor;
    if (_category != null && _category!.colorCode.isNotEmpty) {
      categoryColor = Color(int.parse(_category!.colorCode.substring(1, 7), radix: 16) + 0xFF000000);
    } else if (_income!.categoryColor != null && _income!.categoryColor!.isNotEmpty) {
      categoryColor = Color(int.parse(_income!.categoryColor!.substring(1, 7), radix: 16) + 0xFF000000);
    }
    
    // Format date
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final formattedDate = dateFormat.format(DateTime.parse(_income!.date));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Income Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editIncome,
            tooltip: 'Edit income',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteIncome,
            tooltip: 'Delete income',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Income amount and source card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Amount
                    Text(
                      _income!.formattedAmount,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Source
                    Text(
                      _income!.source,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Category
                    if (_income!.categoryName != null) ...[
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
                            _income!.categoryName!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
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
                      icon: Icons.calendar_today,
                      title: 'Date',
                      value: formattedDate,
                    ),
                    const Divider(),
                    
                    _buildDetailItem(
                      icon: Icons.account_balance,
                      title: 'Source',
                      value: _income!.source,
                    ),
                    
                    if (_income!.description != null && _income!.description!.isNotEmpty) ...[
                      const Divider(),
                      _buildDetailItem(
                        icon: Icons.description,
                        title: 'Description',
                        value: _income!.description!,
                        isMultiLine: true,
                      ),
                    ],
                    
                    if (_income!.isTaxable) ...[
                      const Divider(),
                      _buildDetailItem(
                        icon: Icons.receipt,
                        title: 'Tax Information',
                        value: _income!.taxRate != null 
                          ? 'Taxable at ${_income!.taxRate!.toStringAsFixed(1)}%'
                          : 'Taxable income',
                      ),
                      const Divider(),
                      _buildDetailItem(
                        icon: Icons.account_balance_wallet,
                        title: 'After-Tax Amount',
                        value: currencyFormatter.format(_income!.afterTaxAmount),
                        valueColor: Colors.green,
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
                    if (_income!.isRecurring) ...[
                      _buildDetailItem(
                        icon: Icons.repeat,
                        title: 'Recurring Income',
                        value: _income!.recurringType != null
                            ? 'Repeats ${_formatRecurringType(_income!.recurringType!)}'
                            : 'Recurring',
                        valueColor: theme.primaryColor,
                      ),
                      
                      if (_income!.recurringDay != null) ...[
                        const Divider(),
                        _buildDetailItem(
                          icon: Icons.event,
                          title: 'Recurring Day',
                          value: _formatRecurringDay(_income!.recurringType, _income!.recurringDay),
                        ),
                      ],
                      const Divider(),
                    ],
                    
                    // Created/Updated dates
                    if (_income!.createdAt != null) ...[
                      _buildDetailItem(
                        icon: Icons.access_time,
                        title: 'Created',
                        value: _formatTimestamp(_income!.createdAt!),
                        valueStyle: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    
                    if (_income!.updatedAt != null && _income!.updatedAt != _income!.createdAt) ...[
                      const Divider(),
                      _buildDetailItem(
                        icon: Icons.update,
                        title: 'Last Updated',
                        value: _formatTimestamp(_income!.updatedAt!),
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
              size: 20,
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
  
  String _formatRecurringDay(String? type, int? day) {
    if (day == null) return 'Not specified';
    
    if (type?.toLowerCase() == 'monthly') {
      return 'Day $day of each month';
    } else if (type?.toLowerCase() == 'yearly') {
      return 'Day $day of the month each year';
    } else {
      return 'Day $day';
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