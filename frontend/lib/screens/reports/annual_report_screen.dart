import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/report_service.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_display.dart';
import '../../utils/data_utils.dart';

class AnnualReportScreen extends StatefulWidget {
  @override
  _AnnualReportScreenState createState() => _AnnualReportScreenState();
}

class _AnnualReportScreenState extends State<AnnualReportScreen> {
  final ReportService _reportService = ReportService();
  
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _reportData;
  
  // Selected year
  int _selectedYear = DateTime.now().year;
  
  @override
  void initState() {
    super.initState();
    _fetchAnnualReport();
  }
  
  Future<void> _fetchAnnualReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final result = await _reportService.getAnnualReport(
        year: _selectedYear,
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
        _error = 'Failed to load annual report: $e';
        _isLoading = false;
      });
    }
  }
  
  // Navigate to previous year
  void _previousYear() {
    setState(() {
      _selectedYear--;
    });
    _fetchAnnualReport();
  }
  
  // Navigate to next year
  void _nextYear() {
    setState(() {
      _selectedYear++;
    });
    _fetchAnnualReport();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Annual Report'),
      ),
      body: _isLoading 
        ? LoadingIndicator(message: 'Loading annual report...')
        : _error != null
          ? ErrorDisplay(
              error: _error!,
              onRetry: _fetchAnnualReport,
            )
          : _reportData == null
            ? Center(child: Text('No report data available'))
            : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Year selector
                    _buildYearSelector(theme),
                    SizedBox(height: 24),
                    
                    // Annual summary
                    _buildAnnualSummary(theme, currencyFormatter),
                    SizedBox(height: 24),
                    
                    // Monthly trends
                    _buildMonthlyTrendsChart(theme),
                    SizedBox(height: 24),
                    
                    // Quarterly data
                    _buildQuarterlyData(theme, currencyFormatter),
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
  
  Widget _buildYearSelector(ThemeData theme) {
    // Get navigation data
    final navigation = _reportData!['navigation'] as Map<String, dynamic>;
    final hasNext = _selectedYear < DateTime.now().year;
    
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
              onPressed: _previousYear,
              tooltip: 'Previous year',
            ),
            Text(
              '$_selectedYear',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right),
              onPressed: hasNext ? _nextYear : null,
              tooltip: 'Next year',
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAnnualSummary(ThemeData theme, NumberFormat currencyFormatter) {
    final totals = _reportData!['totals'] as Map<String, dynamic>;
    final income = (totals['income'] as num).toDouble();
    final expenses = (totals['expenses'] as num).toDouble();
    final balance = (totals['balance'] as num).toDouble();
    
    // Calculate savings rate
    final savingsRate = income > 0 ? (balance / income) * 100 : 0.0;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Annual Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            // Income, Expenses, Balance
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
            
            SizedBox(height: 24),
            
            // Savings rate
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.savings,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Savings Rate',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'You saved ${savingsRate.toStringAsFixed(1)}% of your income this year',
                          style: TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
  
  Widget _buildMonthlyTrendsChart(ThemeData theme) {
    final monthlyData = _reportData!['monthly_data'] as List<dynamic>;
    
    if (monthlyData.isEmpty) {
      return SizedBox.shrink();
    }
    
    // Extract data for the chart
    final List<BarChartGroupData> barGroups = [];
    final List<String> months = [];
    
    // Find max value for chart scaling
    double maxY = 0;
    
    for (int i = 0; i < monthlyData.length; i++) {
      final monthData = monthlyData[i];
      final monthName = monthData['month_name'] as String;
      final income = (monthData['income'] as num).toDouble();
      final expenses = (monthData['expenses'] as num).toDouble();
      
      months.add(monthName);
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: income,
              color: Colors.green,
              width: 16,
              borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
            ),
            BarChartRodData(
              toY: expenses,
              color: Colors.red,
              width: 16,
              borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ],
          barsSpace: 4,
        ),
      );
      
      // Update max value
      maxY = [maxY, income, expenses].reduce((curr, next) => curr > next ? curr : next);
    }
    
    // Round up max value for nice chart scaling
    maxY = ((maxY / 1000).ceil() * 1000).toDouble();
    if (maxY < 1000) maxY = 1000;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Trends',
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
                  groupsSpace: 16,
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
                          if (index >= 0 && index < months.length) {
                            return Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                months[index],
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
                            '\$${(value / 1000).toInt()}K',
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
  
  Widget _buildQuarterlyData(ThemeData theme, NumberFormat currencyFormatter) {
    final quarterlyData = _reportData!['quarterly_data'] as List<dynamic>;
    
    if (quarterlyData.isEmpty) {
      return SizedBox.shrink();
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
              'Quarterly Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            // Quarterly data table
            Table(
              columnWidths: {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(3),
                2: FlexColumnWidth(3),
                3: FlexColumnWidth(3),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                // Table header
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: theme.dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Quarter',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Income',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Expenses',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Balance',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                
                // Table data rows
                ...quarterlyData.map((quarter) {
                  final quarterName = quarter['quarter_name'] as String;
                  final income = (quarter['income'] as num).toDouble();
                  final expenses = (quarter['expenses'] as num).toDouble();
                  final balance = (quarter['balance'] as num).toDouble();
                  
                  return TableRow(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: theme.dividerColor.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                    ),
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(quarterName),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          currencyFormatter.format(income),
                          style: TextStyle(
                            color: Colors.green,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          currencyFormatter.format(expenses),
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          currencyFormatter.format(balance),
                          style: TextStyle(
                            color: balance >= 0 ? Colors.blue : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ],
        ),
      ),
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
    maxAmount = ((maxAmount / 1000).ceil() * 1000).toDouble();
    if (maxAmount < 1000) maxAmount = 1000;
    
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
                                '\${(value / 1000).toInt()}K',
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