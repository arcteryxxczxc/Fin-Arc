import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/report_service.dart';
import '../widgets/common/loading_indicator.dart';
import '../widgets/common/error_display.dart';
import '../widgets/common/drawer.dart';
import '../routes/route_names.dart';
import '../utils/error_handler.dart';

class BudgetReportScreen extends StatefulWidget {
  const BudgetReportScreen({super.key});

  @override
  _BudgetReportScreenState createState() => _BudgetReportScreenState();
}

class _BudgetReportScreenState extends State<BudgetReportScreen> {
  final ReportService _reportService = ReportService();
  
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _budgetData;
  
  // Selected date
  late DateTime _selectedDate;
  
  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _fetchBudgetReport();
  }
  
  Future<void> _fetchBudgetReport() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final result = await _reportService.getBudgetReport(
        month: _selectedDate.month,
        year: _selectedDate.year,
      );
      
      if (!mounted) return;
      
      if (result['success']) {
        setState(() {
          _budgetData = result['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _error = 'Failed to load budget report: $e';
        _isLoading = false;
      });
    }
  }
  
  // Navigate to previous month
  void _previousMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
    });
    _fetchBudgetReport();
  }
  
  // Navigate to next month
  void _nextMonth() {
    // Don't allow going to future months
    if (_selectedDate.year == DateTime.now().year && 
        _selectedDate.month == DateTime.now().month) {
      return;
    }
    
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
    });
    _fetchBudgetReport();
  }
  
  // Allow user to pick a month/year
  void _showMonthPicker(BuildContext context) {
    final now = DateTime.now();
    const firstYear = 2020; // First available year
    
    final years = List<int>.generate(now.year - firstYear + 1, (i) => firstYear + i);
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    int selectedYear = _selectedDate.year;
    int selectedMonth = _selectedDate.month;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Select Month'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Year selection
                DropdownButton<int>(
                  isExpanded: true,
                  value: selectedYear,
                  items: years.map((year) {
                    return DropdownMenuItem<int>(
                      value: year,
                      child: Text('$year'),
                    );
                  }).toList(),
                  onChanged: (year) {
                    if (year != null) {
                      setDialogState(() {
                        selectedYear = year;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Month grid
                GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final month = index + 1;
                    final isSelected = selectedMonth == month;
                    final isAfterCurrentMonth = selectedYear == now.year && month > now.month;
                    
                    return InkWell(
                      onTap: isAfterCurrentMonth ? null : () {
                        setDialogState(() {
                          selectedMonth = month;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Theme.of(context).primaryColor.withOpacity(0.2)
                              : null,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey.withOpacity(0.3),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          months[index].substring(0, 3),
                          style: TextStyle(
                            color: isAfterCurrentMonth
                                ? Colors.grey
                                : isSelected
                                    ? Theme.of(context).primaryColor
                                    : null,
                            fontWeight: isSelected ? FontWeight.bold : null,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _selectedDate = DateTime(selectedYear, selectedMonth, 1);
                });
                _fetchBudgetReport();
              },
              child: const Text('SELECT'),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _showMonthPicker(context),
            tooltip: 'Choose Month',
          ),
        ],
      ),
      drawer: AppDrawer(currentRoute: RouteNames.budgetReport),
      body: _isLoading 
        ? LoadingIndicator(message: 'Loading budget report...')
        : _error != null
          ? ErrorDisplay(
              error: _error!,
              onRetry: _fetchBudgetReport,
            )
          : _budgetData == null
            ? const Center(child: Text('No budget data available'))
            : RefreshIndicator(
                onRefresh: _fetchBudgetReport,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Month selector
                      _buildMonthSelector(theme),
                      const SizedBox(height: 24),
                      
                      // Budget summary
                      _buildBudgetSummary(theme, currencyFormatter),
                      const SizedBox(height: 24),
                      
                      // Categories with budget
                      _buildBudgetCategoriesList(theme, currencyFormatter),
                      const SizedBox(height: 24),
                      
                      // Categories without budget
                      _buildNonBudgetCategoriesList(theme, currencyFormatter),
                    ],
                  ),
                ),
              ),
    );
  }
  
  Widget _buildMonthSelector(ThemeData theme) {
    // Get month name and year
    final monthName = _budgetData?['month_name'] as String? ?? 
                      DateFormat('MMMM').format(_selectedDate);
    final year = _budgetData?['year'] as int? ?? _selectedDate.year;
    
    // Check if we can go to next month (not beyond current month)
    final now = DateTime.now();
    final canGoNext = _selectedDate.year < now.year || 
                     (_selectedDate.year == now.year && _selectedDate.month < now.month);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _previousMonth,
              tooltip: 'Previous month',
            ),
            GestureDetector(
              onTap: () => _showMonthPicker(context),
              child: Text(
                '$monthName $year',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: canGoNext ? _nextMonth : null,
              tooltip: canGoNext ? 'Next month' : 'Cannot go to future months',
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBudgetSummary(ThemeData theme, NumberFormat currencyFormatter) {
    final summary = _budgetData!['budget_summary'] as Map<String, dynamic>;
    final totalBudget = (summary['total_budget'] as num?)?.toDouble() ?? 0.0;
    final totalSpent = (summary['total_spent'] as num?)?.toDouble() ?? 0.0;
    final remaining = (summary['remaining'] as num?)?.toDouble() ?? 0.0;
    final percentage = (summary['percentage'] as num?)?.toDouble() ?? 0.0;
    
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
              'Budget Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Progress bar and percentage
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Budget Usage'),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100 > 1 ? 1 : percentage / 100,
                    minHeight: 10,
                    backgroundColor: theme.dividerColor.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Budget stats
            Row(
              children: [
                Expanded(
                  child: _buildBudgetStatItem(
                    title: 'Total Budget',
                    amount: totalBudget,
                    currencyFormatter: currencyFormatter,
                    color: theme.primaryColor,
                    icon: Icons.account_balance_wallet,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBudgetStatItem(
                    title: 'Spent',
                    amount: totalSpent,
                    currencyFormatter: currencyFormatter,
                    color: Colors.red,
                    icon: Icons.arrow_downward,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBudgetStatItem(
                    title: 'Remaining',
                    amount: remaining,
                    currencyFormatter: currencyFormatter,
                    color: remaining >= 0 ? Colors.green : Colors.red,
                    icon: remaining >= 0 ? Icons.check_circle : Icons.warning,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBudgetStatItem({
    required String title,
    required double amount,
    required NumberFormat currencyFormatter,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
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
        ),
        const SizedBox(height: 4),
        Text(
          currencyFormatter.format(amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
  
  Widget _buildBudgetCategoriesList(ThemeData theme, NumberFormat currencyFormatter) {
    final budgetCategories = _budgetData!['budget_categories'] as List<dynamic>? ?? [];
    
    if (budgetCategories.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Categories with Budget',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('No budget categories found for this month'),
                ),
              ),
            ],
          ),
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
            Text(
              'Categories with Budget',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: budgetCategories.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final category = budgetCategories[index];
                final name = category['name'] as String;
                final colorCode = category['color_code'] as String;
                final budget = (category['budget'] as num).toDouble();
                final spent = (category['spent'] as num).toDouble();
                final remaining = (category['remaining'] as num).toDouble();
                final percentage = (category['percentage'] as num).toDouble();
                final status = category['status'] as String? ?? '';
                
                // Determine color based on status
                Color progressColor;
                if (status == 'over') {
                  progressColor = Colors.red;
                } else if (status == 'warning' || percentage > 80) {
                  progressColor = Colors.orange;
                } else {
                  progressColor = Colors.green;
                }
                
                // Parse color from hex string
                final color = Color(int.parse(colorCode.replaceFirst('#', '0xFF')));
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Budget: ${currencyFormatter.format(budget)}'),
                        Text(
                          '${percentage.toInt()}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: progressColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100 > 1 ? 1 : percentage / 100,
                        minHeight: 8,
                        backgroundColor: theme.dividerColor.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Spent: ${currencyFormatter.format(spent)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          'Remaining: ${currencyFormatter.format(remaining)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: remaining >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNonBudgetCategoriesList(ThemeData theme, NumberFormat currencyFormatter) {
    final nonBudgetCategories = _budgetData!['non_budget_categories'] as List<dynamic>? ?? [];
    final uncategorizedExpenses = (_budgetData!['uncategorized_expenses'] as num?)?.toDouble() ?? 0.0;
    
    if (nonBudgetCategories.isEmpty && uncategorizedExpenses <= 0) {
      return const SizedBox.shrink();
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
              'Categories without Budget',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Categories without budget
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: nonBudgetCategories.length,
              itemBuilder: (context, index) {
                final category = nonBudgetCategories[index];
                final name = category['name'] as String;
                final colorCode = category['color_code'] as String;
                final spent = (category['spent'] as num).toDouble();
                
                // Skip categories with no spending
                if (spent <= 0) return const SizedBox.shrink();
                
                // Parse color from hex string
                final color = Color(int.parse(colorCode.replaceFirst('#', '0xFF')));
                
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(name),
                  trailing: Text(
                    currencyFormatter.format(spent),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
            
            // Uncategorized expenses
            if (uncategorizedExpenses > 0) ...[
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                title: const Text('Uncategorized'),
                trailing: Text(
                  currencyFormatter.format(uncategorizedExpenses),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}