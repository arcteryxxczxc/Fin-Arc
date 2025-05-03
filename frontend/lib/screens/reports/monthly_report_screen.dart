// lib/screens/reports/monthly_report_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/report_service.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_display.dart';
import '../../widgets/layout/screen_wrapper.dart';
import '../../routes/route_names.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  _MonthlyReportScreenState createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  final ReportService _reportService = ReportService();
  
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _reportData;
  
  // Selected date
  late DateTime _selectedDate;
  
  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _fetchMonthlyReport();
  }
  
  Future<void> _fetchMonthlyReport() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final result = await _reportService.getMonthlyReport(
        _selectedDate.month,
        _selectedDate.year,
      );
      
      if (!mounted) return;
      
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
      if (!mounted) return;
      
      setState(() {
        _error = 'Failed to load monthly report: $e';
        _isLoading = false;
      });
    }
  }
  
  // Navigate to previous month
  void _previousMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
    });
    _fetchMonthlyReport();
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
    _fetchMonthlyReport();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Fix the currency formatter
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    
    return ScreenWrapper(
      currentRoute: RouteNames.monthlyReport, 
      showBottomNav: false, // Hide bottom nav on detail screens
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Monthly Report'),
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () => _showMonthPicker(context),
              tooltip: 'Choose Month',
            ),
          ],
        ),
        body: _isLoading 
          ? const LoadingIndicator(message: 'Loading monthly report...')
          : _error != null
            ? ErrorDisplay(
                error: _error!,
                onRetry: _fetchMonthlyReport,
              )
            : _reportData == null
              ? const Center(child: Text('No report data available'))
              : RefreshIndicator(
                  onRefresh: _fetchMonthlyReport,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Month selector
                        _buildMonthSelector(theme),
                        const SizedBox(height: 24),
                        
                        // Monthly summary
                        _buildMonthlySummary(theme, currencyFormatter),
                        const SizedBox(height: 24),
                        
                        // Daily trends
                        _buildDailyTrendsChart(theme),
                        const SizedBox(height: 24),
                        
                        // Expense categories
                        _buildExpenseCategories(theme, currencyFormatter),
                        const SizedBox(height: 24),
                        
                        // Income sources
                        _buildIncomeSources(theme, currencyFormatter),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }
  
  // Allow user to pick a month from a dialog
  Future<void> _showMonthPicker(BuildContext context) async {
    final now = DateTime.now();
    const firstYear = 2020; // First available year
    
    final years = List<int>.generate(now.year - firstYear + 1, (i) => firstYear + i);
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    int selectedYear = _selectedDate.year;
    int selectedMonth = _selectedDate.month;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
                      setState(() {
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
                        setState(() {
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
                _fetchMonthlyReport();
              },
              child: const Text('SELECT'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMonthSelector(ThemeData theme) {
    // Get month name and year from report data or use current selection
    final monthName = _reportData?['month_name'] as String? ?? 
                      DateFormat('MMMM').format(_selectedDate);
    final year = _reportData?['year'] as int? ?? _selectedDate.year;
    
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
            Text(
              '$monthName $year',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
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
  
  Widget _buildMonthlySummary(ThemeData theme, NumberFormat currencyFormatter) {
    final totals = _reportData!['totals'] as Map<String, dynamic>;
    final income = (totals['income'] as num).toDouble();
    final expenses = (totals['expenses'] as num).toDouble();
    final balance = (totals['balance'] as num).toDouble();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
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
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem(
                    title: 'Expenses',
                    amount: expenses,
                    currencyFormatter: currencyFormatter,
                    color: Colors.red,
                    icon: Icons.arrow_downward,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem(
                    title: 'Balance',
                    amount: balance,
                    currencyFormatter: currencyFormatter,
                    color: balance >= 0 ? Colors.blue : Colors.red,
                    icon: balance >= 0 ? Icons.check_circle : Icons.warning,
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
  
  Widget _buildDailyTrendsChart(ThemeData theme) {
    final dailyData = _reportData!['daily_data'] as List<dynamic>? ?? [];
    
    if (dailyData.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily Trends',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('No daily data available for this month'),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Extract data for the chart
    final List<FlSpot> incomeSpots = [];
    final List<FlSpot> expenseSpots = [];
    final List<FlSpot> balanceSpots = [];
    final List<String> days = [];
    
    // Find max value for chart scaling
    double maxY = 0;
    
    for (int i = 0; i < dailyData.length; i++) {
      final dayData = dailyData[i];
      final date = DateTime.parse(dayData['date'] as String);
      final day = date.day.toString();
      final income = (dayData['income'] as num).toDouble();
      final expenses = (dayData['expenses'] as num).toDouble();
      final balance = (dayData['balance'] as num).toDouble();
      
      days.add(day);
      incomeSpots.add(FlSpot(i.toDouble(), income));
      expenseSpots.add(FlSpot(i.toDouble(), expenses));
      balanceSpots.add(FlSpot(i.toDouble(), balance));
      
      // Update max value
      maxY = [maxY, income, expenses, balance.abs()].reduce((curr, next) => curr > next ? curr : next);
    }
    
    // Round up max value for nice chart scaling
    maxY = ((maxY / 500).ceil() * 500).toDouble();
    if (maxY < 100) maxY = 100;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Trends',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Chart
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.dividerColor.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const Text('');
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
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < days.length && index % 5 == 0) {
                            return Text(
                              days[index],
                              style: TextStyle(
                                color: theme.textTheme.bodySmall?.color,
                                fontSize: 10,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: days.length - 1.0,
                  minY: 0,
                  maxY: maxY,
                  lineBarsData: [
                    // Income line
                    LineChartBarData(
                      spots: incomeSpots,
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.1),
                      ),
                    ),
                    // Expense line
                    LineChartBarData(
                      spots: expenseSpots,
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.red.withOpacity(0.1),
                      ),
                    ),
                    // Balance line
                    LineChartBarData(
                      spots: balanceSpots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(
                  label: 'Income',
                  color: Colors.green,
                ),
                const SizedBox(width: 16),
                _buildLegendItem(
                  label: 'Expenses',
                  color: Colors.red,
                ),
                const SizedBox(width: 16),
                _buildLegendItem(
                  label: 'Balance',
                  color: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}     