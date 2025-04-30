import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/report_service.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_display.dart';
import '../../utils/data_utils.dart';

class MonthlyReportScreen extends StatefulWidget {
  @override
  _MonthlyReportScreenState createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  final ReportService _reportService = ReportService();
  
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _reportData;
  
  // Selected date
  DateTime _selectedDate = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    _fetchMonthlyReport();
  }
  
  Future<void> _fetchMonthlyReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final result = await _reportService.getMonthlyReport(
        month: _selectedDate.month,
        year: _selectedDate.year,
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
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
    });
    _fetchMonthlyReport();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Monthly Report'),
      ),
      body: _isLoading 
        ? LoadingIndicator(message: 'Loading monthly report...')
        : _error != null
          ? ErrorDisplay(
              error: _error!,
              onRetry: _fetchMonthlyReport,
            )
          : _reportData == null
            ? Center(child: Text('No report data available'))
            : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month selector
                    _buildMonthSelector(theme),
                    SizedBox(height: 24),
                    
                    // Monthly summary
                    _buildMonthlySummary(theme, currencyFormatter),
                    SizedBox(height: 24),
                    
                    // Daily trends
                    _buildDailyTrendsChart(theme),
                    SizedBox(height: 24),
                    
                    // Expense categories
                    _buildExpenseCategories(theme, currencyFormatter),
                    SizedBox(height: 24),
                    
                    // Income sources
                    _buildIncomeSources(theme, currencyFormatter),
                  ],
                ),
              ),
    );
  }
  
  Widget _buildMonthSelector(ThemeData theme) {
    // Get month name and year from report data
    final monthName = _reportData!['month_name'] as String;
    final year = _reportData!['year'] as int;
    
    // Get navigation data
    final navigation = _reportData!['navigation'] as Map<String, dynamic>;
    final hasNext = DateTime(navigation['next_year'], navigation['next_month'], 1)
                    .isBefore(DateTime.now().add(Duration(days: 1)));
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left),
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
              icon: Icon(Icons.chevron_right),
              onPressed: hasNext ? _nextMonth : null,
              tooltip: 'Next month',
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
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Summary',
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
  
  Widget _buildDailyTrendsChart(ThemeData theme) {
    final dailyData = _reportData!['daily_data'] as List<dynamic>;
    
    if (dailyData.isEmpty) {
      return SizedBox.shrink();
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
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Trends',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),
            
            // Chart
            Container(
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
                          if (value == 0) return Text('');
                          return Text(
                            '\$${value.toInt()}',
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
                          return Text('');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                      dotData: FlDotData(show: false),
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
                      dotData: FlDotData(show: false),
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
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                  ],
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
                SizedBox(width: 16),
                _buildLegendItem(
                  label: 'Expenses',
                  color: Colors.red,
                ),
                SizedBox(width: 16),
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
  
  Widget _buildExpenseCategories(ThemeData theme, NumberFormat currencyFormatter) {
    final categories = _reportData!['categories'] as List<dynamic>;
    
    if (categories.isEmpty) {
      return SizedBox.shrink();
    }
    
    // Prepare data for pie chart
    List<PieChartSectionData> sections = [];
    
    for (final category in categories) {
      final name = category['name'] as String;
      final color = category['color'] as String;
      final total = (category['total'] as num).toDouble();
      final percentage = (category['percentage'] as num).toDouble();
      
      // Skip categories with no spending
      if (total <= 0) continue;
      
      // Parse color from hex string
      final colorValue = Color(int.parse(color.replaceFirst('#', '0xFF')));
      
      sections.add(
        PieChartSectionData(
          color: colorValue,
          value: total,
          title: '${percentage.toInt()}%',
          radius: 80,
          titleStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expense Categories',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            // Pie chart
            Container(
              height: 200,
              child: sections.isEmpty
                ? Center(child: Text('No spending data available'))
                : PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
            ),
            
            SizedBox(height: 16),
            
            // Category list
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final name = category['name'] as String;
                final color = category['color'] as String;
                final total = (category['total'] as num).toDouble();
                final percentage = (category['percentage'] as num).toDouble();
                
                // Skip categories with no spending
                if (total <= 0) return SizedBox.shrink();
                
                // Parse color from hex string
                final colorValue = Color(int.parse(color.replaceFirst('#', '0xFF')));
                
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                  leading: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: colorValue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(name),
                  trailing: Text(
                    '${currencyFormatter.format(total)} (${percentage.toInt()}%)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildIncomeSources(ThemeData theme, NumberFormat currencyFormatter) {
    final sources = _reportData!['income_sources'] as List<dynamic>;
    
    if (sources.isEmpty) {
      return SizedBox.shrink();
    }
    
    // Prepare data for bar chart
    final List<BarChartGroupData> barGroups = [];
    final List<String> sourceNames = [];
    final List<Color> colors = [];
    
    double maxAmount = 0;
    
    for (int i = 0; i < sources.length; i++) {
      final source = sources[i];
      final name = source['name'] as String;
      final color = source['color'] as String;
      final total = (source['total'] as num).toDouble();
      
      // Skip sources with no income
      if (total <= 0) continue;
      
      // Update max amount
      if (total > maxAmount) {
        maxAmount = total;
      }
      
      // Parse color from hex string
      final colorValue = Color(int.parse(color.replaceFirst('#', '0xFF')));
      
      sourceNames.add(name);
      colors.add(colorValue);
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: total,
              color: colorValue,
              width: 20,
              borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ],
        ),
      );
    }
    
    // Round up max value for nice chart scaling
    maxAmount = ((maxAmount / 500).ceil() * 500).toDouble();
    if (maxAmount < 100) maxAmount = 100;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Income Sources',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            // Bar chart
            Container(
              height: 200,
              child: barGroups.isEmpty
                ? Center(child: Text('No income data available'))
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.center,
                      maxY: maxAmount,
                      minY: 0,
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: maxAmount / 5,
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
                              if (index >= 0 && index < sourceNames.length) {
                                return Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Text(
                                    sourceNames[index],
                                    style: TextStyle(
                                      color: theme.textTheme.bodySmall?.color,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
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
                                '\$${value.toInt()}',
                                style: TextStyle(
                                  color: theme.textTheme.bodySmall?.color,
                                  fontSize: 10,
                                ),
                              );
                            },
                            interval: maxAmount / 5,
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
            
            // Income sources list
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: sources.length,
              itemBuilder: (context, index) {
                final source = sources[index];
                final name = source['name'] as String;
                final color = source['color'] as String;
                final total = (source['total'] as num).toDouble();
                final percentage = (source['percentage'] as num).toDouble();
                
                // Skip sources with no income
                if (total <= 0) return SizedBox.shrink();
                
                // Parse color from hex string
                final colorValue = Color(int.parse(color.replaceFirst('#', '0xFF')));
                
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                  leading: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: colorValue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(name),
                  trailing: Text(
                    '${currencyFormatter.format(total)} (${percentage.toInt()}%)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}