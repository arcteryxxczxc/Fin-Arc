import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/expense_provider.dart';
import '../../providers/income_provider.dart';
import '../../services/report_service.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_display.dart';
import 'monthly_report_screen.dart';
import 'annual_report_screen.dart';
import 'budget_report_screen.dart';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportService _reportService = ReportService();
  
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _overviewData;
  
  @override
  void initState() {
    super.initState();
    _fetchOverviewData();
  }
  
  Future<void> _fetchOverviewData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final result = await _reportService.getDashboardData();
      
      if (result['success']) {
        setState(() {
          _overviewData = result['data'];
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
        _error = 'Failed to load overview data: $e';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Financial Reports'),
      ),
      body: _isLoading 
        ? LoadingIndicator(message: 'Loading reports data...')
        : _error != null
          ? ErrorDisplay(
              error: _error!,
              onRetry: _fetchOverviewData,
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Available reports
                  Text(
                    'Reports',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Report cards
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    children: [
                      _buildReportCard(
                        title: 'Monthly Report',
                        description: 'View your monthly income and expenses',
                        icon: Icons.calendar_month,
                        color: Colors.blue,
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => MonthlyReportScreen(),
                          ));
                        },
                      ),
                      _buildReportCard(
                        title: 'Annual Report',
                        description: 'Year-to-date financial summary',
                        icon: Icons.insert_chart,
                        color: Colors.green,
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => AnnualReportScreen(),
                          ));
                        },
                      ),
                      _buildReportCard(
                        title: 'Budget Report',
                        description: 'Track your budget progress',
                        icon: Icons.account_balance_wallet,
                        color: Colors.purple,
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => BudgetReportScreen(),
                          ));
                        },
                      ),
                      _buildReportCard(
                        title: 'Export Data',
                        description: 'Download your financial data',
                        icon: Icons.download,
                        color: Colors.orange,
                        onTap: () {
                          _showExportDialog(context);
                        },
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Financial overview
                  if (_overviewData != null) ...[
                    Text(
                      'Financial Overview',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Month trend chart
                    _buildTrendChart(theme),
                    SizedBox(height: 24),
                    
                    // Stats cards
                    _buildStatCards(theme, currencyFormatter),
                  ],
                ],
              ),
            ),
    );
  }
  
  Widget _buildReportCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 4),
              Expanded(
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTrendChart(ThemeData theme) {
    final trend = _overviewData!['trend'] as List<dynamic>;
    
    if (trend.isEmpty) {
      return SizedBox.shrink();
    }
    
    // Extract data for the chart
    final List<FlSpot> incomeSpots = [];
    final List<FlSpot> expenseSpots = [];
    final List<FlSpot> balanceSpots = [];
    final List<String> months = [];
    
    // Find max value for chart scaling
    double maxY = 0;
    
    for (int i = 0; i < trend.length; i++) {
      final monthData = trend[i];
      final month = monthData['month'] as String;
      final income = (monthData['income'] as num).toDouble();
      final expenses = (monthData['expenses'] as num).toDouble();
      final balance = (monthData['balance'] as num).toDouble();
      
      months.add(month);
      incomeSpots.add(FlSpot(i.toDouble(), income));
      expenseSpots.add(FlSpot(i.toDouble(), expenses));
      balanceSpots.add(FlSpot(i.toDouble(), balance));
      
      // Update max value
      maxY = [maxY, income, expenses, balance.abs()].reduce((curr, next) => curr > next ? curr : next);
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
              'Monthly Trend',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),
            
            // Chart
            Container(
              height: 200,
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
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < months.length) {
                            return Text(
                              months[index],
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
                  maxX: months.length - 1.0,
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
  
  Widget _buildStatCards(ThemeData theme, NumberFormat currencyFormatter) {
    final stats = _overviewData!['stats'] as Map<String, dynamic>;
    final monthStats = stats['month'] as Map<String, dynamic>;
    
    final income = (monthStats['income'] as num).toDouble();
    final expenses = (monthStats['expenses'] as num).toDouble();
    final balance = (monthStats['balance'] as num).toDouble();
    
    // Calculate savings rate
    final savingsRate = income > 0 ? (balance / income) * 100 : 0.0;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Current Month',
                value: currencyFormatter.format(balance),
                subtitle: 'Net Balance',
                icon: Icons.account_balance,
                iconColor: balance >= 0 ? Colors.green : Colors.red,
                theme: theme,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Savings Rate',
                value: '${savingsRate.toStringAsFixed(1)}%',
                subtitle: 'of Income',
                icon: Icons.savings,
                iconColor: Colors.blue,
                theme: theme,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Month Income',
                value: currencyFormatter.format(income),
                subtitle: 'Total Earnings',
                icon: Icons.arrow_upward,
                iconColor: Colors.green,
                theme: theme,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Month Expenses',
                value: currencyFormatter.format(expenses),
                subtitle: 'Total Spending',
                icon: Icons.arrow_downward,
                iconColor: Colors.red,
                theme: theme,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required ThemeData theme,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 18,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showExportDialog(BuildContext context) {
    final theme = Theme.of(context);
    
    // Export options
    final List<Map<String, dynamic>> exportOptions = [
      {
        'title': 'Expenses',
        'subtitle': 'Export your expense transactions',
        'icon': Icons.arrow_downward,
        'color': Colors.red,
        'type': 'expenses',
      },
      {
        'title': 'Income',
        'subtitle': 'Export your income transactions',
        'icon': Icons.arrow_upward,
        'color': Colors.green,
        'type': 'income',
      },
      {
        'title': 'Monthly Report',
        'subtitle': 'Current month summary',
        'icon': Icons.calendar_month,
        'color': Colors.blue,
        'type': 'monthly',
      },
      {
        'title': 'Annual Report',
        'subtitle': 'Year-to-date summary',
        'icon': Icons.insert_chart,
        'color': Colors.purple,
        'type': 'annual',
      },
    ];
    
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Data',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Select the data you want to export',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
            
            // Export options list
            ...exportOptions.map((option) => ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: option['color'].withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  option['icon'],
                  color: option['color'],
                ),
              ),
              title: Text(option['title']),
              subtitle: Text(option['subtitle']),
              onTap: () async {
                Navigator.of(ctx).pop();
                // Show date range picker if needed
                // Then call export service
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Export functionality will be implemented soon')),
                );
              },
            )),
            
            SizedBox(height: 16),
            
            // Cancel button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}