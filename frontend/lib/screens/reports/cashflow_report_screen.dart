import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/report_service.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_display.dart';
import '../../widgets/common/drawer.dart';
import '../../routes/route_names.dart';
import '../../utils/data_utils.dart';

class CashflowReportScreen extends StatefulWidget {
  @override
  _CashflowReportScreenState createState() => _CashflowReportScreenState();
}

class _CashflowReportScreenState extends State<CashflowReportScreen> {
  final ReportService _reportService = ReportService();
  
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _reportData;
  
  // Selected period
  String _selectedPeriod = 'month'; // 'month', 'year', 'custom'
  DateTime? _startDate;
  DateTime? _endDate;
  
  @override
  void initState() {
    super.initState();
    // Set default date range to current month
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
    
    _fetchCashflowReport();
  }
  
  Future<void> _fetchCashflowReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Format dates if using custom period
      String? startDateStr, endDateStr;
      if (_selectedPeriod == 'custom' && _startDate != null && _endDate != null) {
        startDateStr = DateFormat('yyyy-MM-dd').format(_startDate!);
        endDateStr = DateFormat('yyyy-MM-dd').format(_endDate!);
      }
      
      final result = await _reportService.getCashFlowReport(
        period: _selectedPeriod,
        startDate: startDateStr,
        endDate: endDateStr,
      );
      
      if (result['success']) {
        setState(() {
          _reportData = result['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load cashflow report: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate ?? DateTime.now().subtract(Duration(days: 30)),
        end: _endDate ?? DateTime.now(),
      ),
    );
    
    if (picked != null) {
      setState(() {
        _selectedPeriod = 'custom';
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchCashflowReport();
    }
  }
  
  void _changePeriod(String period) {
    if (period == _selectedPeriod) return;
    
    setState(() {
      _selectedPeriod = period;
      
      // Update date range based on period
      final now = DateTime.now();
      if (period == 'month') {
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
      } else if (period == 'year') {
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, 12, 31);
      }
      // For custom, keep the existing dates or set defaults
      else if (period == 'custom' && (_startDate == null || _endDate == null)) {
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
      }
    });
    
    _fetchCashflowReport();
  }
  
  Future<void> _refreshData() async {
    await _fetchCashflowReport();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(symbol: '\
      }
      
      final result = await _reportService.getCashFlowReport(
        period: _selectedPeriod,
        startDate: startDateStr,
        endDate: endDateStr,
      );
      
      if (result['success']) {
        setState(() {
          _reportData = result['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load cashflow report: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate ?? DateTime.now().subtract(Duration(days: 30)),
        end: _endDate ?? DateTime.now(),
      ),
    );
    
    if (picked != null) {
      setState(() {
        _selectedPeriod = 'custom';
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchCashflowReport();
    }
  }
  
  void _changePeriod(String period) {
    if (period == _selectedPeriod) return;
    
    setState(() {
      _selectedPeriod = period;
      
      // Update date range based on period
      final now = DateTime.now();
      if (period == 'month') {
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
      } else if (period == 'year') {
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, 12, 31);
      }
      // For custom, keep the existing dates or set defaults
      else if (period == 'custom' && (_startDate == null || _endDate == null)) {
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
      }
    });
    
    _fetchCashflowReport();
  }
  
  Future<void> _refreshData() async {
    await _fetchCashflowReport();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(symbol: '\);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Cashflow Report'),
      ),
      body: _isLoading 
        ? LoadingIndicator(message: 'Loading cashflow report...')
        : _error != null
          ? ErrorDisplay(
              error: _error!,
              onRetry: _fetchCashflowReport,
            )
          : _reportData == null
            ? Center(child: Text('No report data available'))
            : RefreshIndicator(
                onRefresh: _refreshData,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Period selector
                      _buildPeriodSelector(theme),
                      SizedBox(height: 24),
                      
                      // Cashflow summary
                      _buildCashflowSummary(theme, currencyFormatter),
                      SizedBox(height: 24),
                      
                      // Daily cashflow chart
                      _buildDailyCashflowChart(theme),
                      SizedBox(height: 24),
                      
                      // Transactions lists
                      _buildTransactionLists(theme, currencyFormatter),
                    ],
                  ),
                ),
              ),
    );
  }
  
  Widget _buildPeriodSelector(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report Period',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            // Period buttons
            Row(
              children: [
                Expanded(
                  child: _buildPeriodButton(
                    label: 'This Month',
                    isSelected: _selectedPeriod == 'month',
                    onTap: () => _changePeriod('month'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildPeriodButton(
                    label: 'This Year',
                    isSelected: _selectedPeriod == 'year',
                    onTap: () => _changePeriod('year'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildPeriodButton(
                    label: 'Custom',
                    isSelected: _selectedPeriod == 'custom',
                    onTap: () => _selectDateRange(context),
                  ),
                ),
              ],
            ),
            
            // Date range (only show for custom)
            if (_selectedPeriod == 'custom' && _startDate != null && _endDate != null) ...[
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.date_range, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text(
                    '${DateFormat('MMM d, yyyy').format(_startDate!)} - ${DateFormat('MMM d, yyyy').format(_endDate!)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildPeriodButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).primaryColor
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected 
                ? Theme.of(context).primaryColor
                : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
  
  Widget _buildCashflowSummary(ThemeData theme, NumberFormat currencyFormatter) {
    final totals = _reportData!['totals'] as Map<String, dynamic>;
    final income = (totals['income'] as num).toDouble();
    final expenses = (totals['expenses'] as num).toDouble();
    final netCashflow = (totals['net_cashflow'] as num).toDouble();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cashflow Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    title: 'Income',
                    amount: income,
                    currencyFormatter: currencyFormatter,
                    color: Colors.green,
                    icon: Icons.arrow_upward,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem(
                    title: 'Expenses',
                    amount: expenses,
                    currencyFormatter: currencyFormatter,
                    color: Colors.red,
                    icon: Icons.arrow_downward,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem(
                    title: 'Net Cashflow',
                    amount: netCashflow,
                    currencyFormatter: currencyFormatter,
                    color: netCashflow >= 0 ? Colors.blue : Colors.red,
                    icon: netCashflow >= 0 ? Icons.check_circle : Icons.warning,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryItem({
    required String title,
    required double amount,
    required NumberFormat currencyFormatter,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
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
        SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 4),
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
  
  Widget _buildDailyCashflowChart(ThemeData theme) {
    final dailyCashflow = _reportData!['daily_cashflow'] as List<dynamic>;
    
    if (dailyCashflow.isEmpty) {
      return SizedBox.shrink();
    }
    
    // Extract data for the chart
    final List<BarChartGroupData> barGroups = [];
    final List<String> days = [];
    
    // Find max value for chart scaling
    double maxY = 0;
    
    for (int i = 0; i < dailyCashflow.length; i++) {
      final dayData = dailyCashflow[i];
      final date = DateTime.parse(dayData['date'] as String);
      final dayStr = DateFormat('d').format(date);
      final income = (dayData['income'] as num).toDouble();
      final expenses = (dayData['expenses'] as num).toDouble();
      final net = (dayData['net'] as num).toDouble();
      
      days.add(dayStr);
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: income,
              color: Colors.green,
              width: 8,
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            ),
            BarChartRodData(
              toY: expenses,
              color: Colors.red,
              width: 8,
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
          barsSpace: 4,
        ),
      );
      
      // Update max value
      maxY = [maxY, income, expenses].reduce((curr, next) => curr > next ? curr : next);
    }
    
    // Round up max value for nice chart scaling
    maxY = ((maxY / 500).ceil() * 500).toDouble();
    if (maxY < 500) maxY = 500;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Cashflow',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),
            
            // Chart
            Container(
              height: 240,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.center,
                  maxY: maxY,
                  minY: 0,
                  groupsSpace: 12,
                  barTouchData: BarTouchData(enabled: false),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: maxY / 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.dividerColor.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                    drawVerticalLine: false,
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < days.length && index % 5 == 0) {
                            return Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                days[index],
                                style: TextStyle(
                                  color: theme.textTheme.bodySmall?.color,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return Text('');
                          return Text(
                            '\${value.toInt()}',
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
                              fontSize: 10,
                            ),
                          );
                        },
                        interval: maxY / 5,
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: barGroups,
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(
                  label: 'Income',
                  color: Colors.green,
                ),
                SizedBox(width: 24),
                _buildLegendItem(
                  label: 'Expenses',
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLegendItem({required String label, required Color color}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
  
  Widget _buildTransactionLists(ThemeData theme, NumberFormat currencyFormatter) {
    final incomeEntries = _reportData!['income_entries'] as List<dynamic>;
    final expenseEntries = _reportData!['expense_entries'] as List<dynamic>;
    
    if (incomeEntries.isEmpty && expenseEntries.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No transactions found for this period'),
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Income entries
        if (incomeEntries.isNotEmpty) ...[
          Text(
            'Income Transactions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: incomeEntries.length,
              separatorBuilder: (context, index) => Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = incomeEntries[index];
                final date = DateFormat('MMM d, yyyy').format(DateTime.parse(entry['date'] as String));
                final source = entry['source'] as String;
                final description = entry['description'] as String? ?? '';
                final amount = (entry['amount'] as num).toDouble();
                
                return ListTile(
                  title: Text(source),
                  subtitle: Text('$date${description.isNotEmpty ? ' • $description' : ''}'),
                  trailing: Text(
                    currencyFormatter.format(amount),
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 24),
        ],
        
        // Expense entries
        if (expenseEntries.isNotEmpty) ...[
          Text(
            'Expense Transactions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: expenseEntries.length,
              separatorBuilder: (context, index) => Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = expenseEntries[index];
                final date = DateFormat('MMM d, yyyy').format(DateTime.parse(entry['date'] as String));
                final description = entry['description'] as String? ?? 'Expense';
                final category = entry['category'] as String? ?? 'Uncategorized';
                final amount = (entry['amount'] as num).toDouble();
                
                return ListTile(
                  title: Text(description),
                  subtitle: Text('$date • $category'),
                  trailing: Text(
                    currencyFormatter.format(amount),
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  });
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Cashflow Report'),
      ),
      drawer: AppDrawer(currentRoute: RouteNames.cashflowReport),
      body: _isLoading 
        ? LoadingIndicator(message: 'Loading cashflow report...')
        : _error != null
          ? ErrorDisplay(
              error: _error!,
              onRetry: _fetchCashflowReport,
            )
          : _reportData == null
            ? Center(child: Text('No report data available'))
            : RefreshIndicator(
                onRefresh: _refreshData,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Period selector
                      _buildPeriodSelector(theme),
                      SizedBox(height: 24),
                      
                      // Cashflow summary
                      _buildCashflowSummary(theme, currencyFormatter),
                      SizedBox(height: 24),
                      
                      // Daily cashflow chart
                      _buildDailyCashflowChart(theme),
                      SizedBox(height: 24),
                      
                      // Transactions lists
                      _buildTransactionLists(theme, currencyFormatter),
                    ],
                  ),
                ),
              ),
    );
  }
  
  Widget _buildPeriodSelector(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report Period',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            // Period buttons
            Row(
              children: [
                Expanded(
                  child: _buildPeriodButton(
                    label: 'This Month',
                    isSelected: _selectedPeriod == 'month',
                    onTap: () => _changePeriod('month'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildPeriodButton(
                    label: 'This Year',
                    isSelected: _selectedPeriod == 'year',
                    onTap: () => _changePeriod('year'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildPeriodButton(
                    label: 'Custom',
                    isSelected: _selectedPeriod == 'custom',
                    onTap: () => _selectDateRange(context),
                  ),
                ),
              ],
            ),
            
            // Date range (only show for custom)
            if (_selectedPeriod == 'custom' && _startDate != null && _endDate != null) ...[
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.date_range, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text(
                    '${DateFormat('MMM d, yyyy').format(_startDate!)} - ${DateFormat('MMM d, yyyy').format(_endDate!)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildPeriodButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).primaryColor
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected 
                ? Theme.of(context).primaryColor
                : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
  
  Widget _buildCashflowSummary(ThemeData theme, NumberFormat currencyFormatter) {
    final totals = _reportData!['totals'] as Map<String, dynamic>;
    final income = (totals['income'] as num).toDouble();
    final expenses = (totals['expenses'] as num).toDouble();
    final netCashflow = (totals['net_cashflow'] as num).toDouble();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cashflow Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    title: 'Income',
                    amount: income,
                    currencyFormatter: currencyFormatter,
                    color: Colors.green,
                    icon: Icons.arrow_upward,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem(
                    title: 'Expenses',
                    amount: expenses,
                    currencyFormatter: currencyFormatter,
                    color: Colors.red,
                    icon: Icons.arrow_downward,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem(
                    title: 'Net Cashflow',
                    amount: netCashflow,
                    currencyFormatter: currencyFormatter,
                    color: netCashflow >= 0 ? Colors.blue : Colors.red,
                    icon: netCashflow >= 0 ? Icons.check_circle : Icons.warning,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryItem({
    required String title,
    required double amount,
    required NumberFormat currencyFormatter,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
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
        SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 4),
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
  
  Widget _buildDailyCashflowChart(ThemeData theme) {
    final dailyCashflow = _reportData!['daily_cashflow'] as List<dynamic>;
    
    if (dailyCashflow.isEmpty) {
      return SizedBox.shrink();
    }
    
    // Extract data for the chart
    final List<BarChartGroupData> barGroups = [];
    final List<String> days = [];
    
    // Find max value for chart scaling
    double maxY = 0;
    
    for (int i = 0; i < dailyCashflow.length; i++) {
      final dayData = dailyCashflow[i];
      final date = DateTime.parse(dayData['date'] as String);
      final dayStr = DateFormat('d').format(date);
      final income = (dayData['income'] as num).toDouble();
      final expenses = (dayData['expenses'] as num).toDouble();
      final net = (dayData['net'] as num).toDouble();
      
      days.add(dayStr);
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: income,
              color: Colors.green,
              width: 8,
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            ),
            BarChartRodData(
              toY: expenses,
              color: Colors.red,
              width: 8,
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
          barsSpace: 4,
        ),
      );
      
      // Update max value
      maxY = [maxY, income, expenses].reduce((curr, next) => curr > next ? curr : next);
    }
    
    // Round up max value for nice chart scaling
    maxY = ((maxY / 500).ceil() * 500).toDouble();
    if (maxY < 500) maxY = 500;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Cashflow',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),
            
            // Chart
            Container(
              height: 240,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.center,
                  maxY: maxY,
                  minY: 0,
                  groupsSpace: 12,
                  barTouchData: BarTouchData(enabled: false),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: maxY / 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.dividerColor.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                    drawVerticalLine: false,
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < days.length && index % 5 == 0) {
                            return Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                days[index],
                                style: TextStyle(
                                  color: theme.textTheme.bodySmall?.color,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return Text('');
                          return Text(
                            '\${value.toInt()}',
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
                              fontSize: 10,
                            ),
                          );
                        },
                        interval: maxY / 5,
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: barGroups,
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(
                  label: 'Income',
                  color: Colors.green,
                ),
                SizedBox(width: 24),
                _buildLegendItem(
                  label: 'Expenses',
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLegendItem({required String label, required Color color}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
  
  Widget _buildTransactionLists(ThemeData theme, NumberFormat currencyFormatter) {
    final incomeEntries = _reportData!['income_entries'] as List<dynamic>;
    final expenseEntries = _reportData!['expense_entries'] as List<dynamic>;
    
    if (incomeEntries.isEmpty && expenseEntries.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No transactions found for this period'),
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Income entries
        if (incomeEntries.isNotEmpty) ...[
          Text(
            'Income Transactions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: incomeEntries.length,
              separatorBuilder: (context, index) => Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = incomeEntries[index];
                final date = DateFormat('MMM d, yyyy').format(DateTime.parse(entry['date'] as String));
                final source = entry['source'] as String;
                final description = entry['description'] as String? ?? '';
                final amount = (entry['amount'] as num).toDouble();
                
                return ListTile(
                  title: Text(source),
                  subtitle: Text('$date${description.isNotEmpty ? ' • $description' : ''}'),
                  trailing: Text(
                    currencyFormatter.format(amount),
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 24),
        ],
        
        // Expense entries
        if (expenseEntries.isNotEmpty) ...[
          Text(
            'Expense Transactions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: expenseEntries.length,
              separatorBuilder: (context, index) => Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = expenseEntries[index];
                final date = DateFormat('MMM d, yyyy').format(DateTime.parse(entry['date'] as String));
                final description = entry['description'] as String? ?? 'Expense';
                final category = entry['category'] as String? ?? 'Uncategorized';
                final amount = (entry['amount'] as num).toDouble();
                
                return ListTile(
                  title: Text(description),
                  subtitle: Text('$date • $category'),
                  trailing: Text(
                    currencyFormatter.format(amount),
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
      }
      
      final result = await _reportService.getCashFlowReport(
        period: _selectedPeriod,
        startDate: startDateStr,
        endDate: endDateStr,
      );
      
      if (result['success']) {
        setState(() {
          _reportData = result['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load cashflow report: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate ?? DateTime.now().subtract(Duration(days: 30)),
        end: _endDate ?? DateTime.now(),
      ),
    );
    
    if (picked != null) {
      setState(() {
        _selectedPeriod = 'custom';
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchCashflowReport();
    }
  }
  
  void _changePeriod(String period) {
    if (period == _selectedPeriod) return;
    
    setState(() {
      _selectedPeriod = period;
      
      // Update date range based on period
      final now = DateTime.now();
      if (period == 'month') {
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
      } else if (period == 'year') {
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, 12, 31);
      }
      // For custom, keep the existing dates or set defaults
      else if (period == 'custom' && (_startDate == null || _endDate == null)) {
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
      }
    });
    
    _fetchCashflowReport();
  }
  
  Future<void> _refreshData() async {
    await _fetchCashflowReport();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(symbol: '\);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Cashflow Report'),
      ),
      body: _isLoading 
        ? LoadingIndicator(message: 'Loading cashflow report...')
        : _error != null
          ? ErrorDisplay(
              error: _error!,
              onRetry: _fetchCashflowReport,
            )
          : _reportData == null
            ? Center(child: Text('No report data available'))
            : RefreshIndicator(
                onRefresh: _refreshData,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Period selector
                      _buildPeriodSelector(theme),
                      SizedBox(height: 24),
                      
                      // Cashflow summary
                      _buildCashflowSummary(theme, currencyFormatter),
                      SizedBox(height: 24),
                      
                      // Daily cashflow chart
                      _buildDailyCashflowChart(theme),
                      SizedBox(height: 24),
                      
                      // Transactions lists
                      _buildTransactionLists(theme, currencyFormatter),
                    ],
                  ),
                ),
              ),
    );
  }
  
  Widget _buildPeriodSelector(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report Period',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            // Period buttons
            Row(
              children: [
                Expanded(
                  child: _buildPeriodButton(
                    label: 'This Month',
                    isSelected: _selectedPeriod == 'month',
                    onTap: () => _changePeriod('month'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildPeriodButton(
                    label: 'This Year',
                    isSelected: _selectedPeriod == 'year',
                    onTap: () => _changePeriod('year'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildPeriodButton(
                    label: 'Custom',
                    isSelected: _selectedPeriod == 'custom',
                    onTap: () => _selectDateRange(context),
                  ),
                ),
              ],
            ),
            
            // Date range (only show for custom)
            if (_selectedPeriod == 'custom' && _startDate != null && _endDate != null) ...[
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.date_range, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text(
                    '${DateFormat('MMM d, yyyy').format(_startDate!)} - ${DateFormat('MMM d, yyyy').format(_endDate!)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildPeriodButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).primaryColor
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected 
                ? Theme.of(context).primaryColor
                : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
  
  Widget _buildCashflowSummary(ThemeData theme, NumberFormat currencyFormatter) {
    final totals = _reportData!['totals'] as Map<String, dynamic>;
    final income = (totals['income'] as num).toDouble();
    final expenses = (totals['expenses'] as num).toDouble();
    final netCashflow = (totals['net_cashflow'] as num).toDouble();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cashflow Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    title: 'Income',
                    amount: income,
                    currencyFormatter: currencyFormatter,
                    color: Colors.green,
                    icon: Icons.arrow_upward,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem(
                    title: 'Expenses',
                    amount: expenses,
                    currencyFormatter: currencyFormatter,
                    color: Colors.red,
                    icon: Icons.arrow_downward,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem(
                    title: 'Net Cashflow',
                    amount: netCashflow,
                    currencyFormatter: currencyFormatter,
                    color: netCashflow >= 0 ? Colors.blue : Colors.red,
                    icon: netCashflow >= 0 ? Icons.check_circle : Icons.warning,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryItem({
    required String title,
    required double amount,
    required NumberFormat currencyFormatter,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
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
        SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 4),
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
  
  Widget _buildDailyCashflowChart(ThemeData theme) {
    final dailyCashflow = _reportData!['daily_cashflow'] as List<dynamic>;
    
    if (dailyCashflow.isEmpty) {
      return SizedBox.shrink();
    }
    
    // Extract data for the chart
    final List<BarChartGroupData> barGroups = [];
    final List<String> days = [];
    
    // Find max value for chart scaling
    double maxY = 0;
    
    for (int i = 0; i < dailyCashflow.length; i++) {
      final dayData = dailyCashflow[i];
      final date = DateTime.parse(dayData['date'] as String);
      final dayStr = DateFormat('d').format(date);
      final income = (dayData['income'] as num).toDouble();
      final expenses = (dayData['expenses'] as num).toDouble();
      final net = (dayData['net'] as num).toDouble();
      
      days.add(dayStr);
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: income,
              color: Colors.green,
              width: 8,
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            ),
            BarChartRodData(
              toY: expenses,
              color: Colors.red,
              width: 8,
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
          barsSpace: 4,
        ),
      );
      
      // Update max value
      maxY = [maxY, income, expenses].reduce((curr, next) => curr > next ? curr : next);
    }
    
    // Round up max value for nice chart scaling
    maxY = ((maxY / 500).ceil() * 500).toDouble();
    if (maxY < 500) maxY = 500;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Cashflow',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),
            
            // Chart
            Container(
              height: 240,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.center,
                  maxY: maxY,
                  minY: 0,
                  groupsSpace: 12,
                  barTouchData: BarTouchData(enabled: false),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: maxY / 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.dividerColor.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                    drawVerticalLine: false,
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < days.length && index % 5 == 0) {
                            return Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                days[index],
                                style: TextStyle(
                                  color: theme.textTheme.bodySmall?.color,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return Text('');
                          return Text(
                            '\${value.toInt()}',
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
                              fontSize: 10,
                            ),
                          );
                        },
                        interval: maxY / 5,
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: barGroups,
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(
                  label: 'Income',
                  color: Colors.green,
                ),
                SizedBox(width: 24),
                _buildLegendItem(
                  label: 'Expenses',
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLegendItem({required String label, required Color color}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
  
  Widget _buildTransactionLists(ThemeData theme, NumberFormat currencyFormatter) {
    final incomeEntries = _reportData!['income_entries'] as List<dynamic>;
    final expenseEntries = _reportData!['expense_entries'] as List<dynamic>;
    
    if (incomeEntries.isEmpty && expenseEntries.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No transactions found for this period'),
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Income entries
        if (incomeEntries.isNotEmpty) ...[
          Text(
            'Income Transactions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: incomeEntries.length,
              separatorBuilder: (context, index) => Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = incomeEntries[index];
                final date = DateFormat('MMM d, yyyy').format(DateTime.parse(entry['date'] as String));
                final source = entry['source'] as String;
                final description = entry['description'] as String? ?? '';
                final amount = (entry['amount'] as num).toDouble();
                
                return ListTile(
                  title: Text(source),
                  subtitle: Text('$date${description.isNotEmpty ? ' • $description' : ''}'),
                  trailing: Text(
                    currencyFormatter.format(amount),
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 24),
        ],
        
        // Expense entries
        if (expenseEntries.isNotEmpty) ...[
          Text(
            'Expense Transactions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: expenseEntries.length,
              separatorBuilder: (context, index) => Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = expenseEntries[index];
                final date = DateFormat('MMM d, yyyy').format(DateTime.parse(entry['date'] as String));
                final description = entry['description'] as String? ?? 'Expense';
                final category = entry['category'] as String? ?? 'Uncategorized';
                final amount = (entry['amount'] as num).toDouble();
                
                return ListTile(
                  title: Text(description),
                  subtitle: Text('$date • $category'),
                  trailing: Text(
                    currencyFormatter.format(amount),
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }