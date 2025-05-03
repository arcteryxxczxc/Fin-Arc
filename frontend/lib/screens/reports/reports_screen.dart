// lib/screens/reports/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widgets/layout/screen_wrapper.dart';
import '../../services/report_service.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_display.dart';
import '../../routes/route_names.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

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
    
    return ScreenWrapper(
      currentRoute: RouteNames.reports,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Financial Reports'),
        ),
        body: _isLoading 
          ? const LoadingIndicator(message: 'Loading reports data...')
          : _error != null
            ? ErrorDisplay(
                error: _error!,
                onRetry: _fetchOverviewData,
              )
            : RefreshIndicator(
                onRefresh: _fetchOverviewData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
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
                      const SizedBox(height: 16),
                      
                      // Report cards
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildReportCard(
                            title: 'Monthly Report',
                            description: 'View your monthly income and expenses',
                            icon: Icons.calendar_month,
                            color: Colors.blue,
                            onTap: () {
                              Navigator.of(context).pushNamed(RouteNames.monthlyReport);
                            },
                          ),
                          _buildReportCard(
                            title: 'Annual Report',
                            description: 'Year-to-date financial summary',
                            icon: Icons.insert_chart,
                            color: Colors.green,
                            onTap: () {
                              Navigator.of(context).pushNamed(RouteNames.annualReport);
                            },
                          ),
                          _buildReportCard(
                            title: 'Budget Report',
                            description: 'Track your budget progress',
                            icon: Icons.account_balance_wallet,
                            color: Colors.purple,
                            onTap: () {
                              Navigator.of(context).pushNamed(RouteNames.budgetReport);
                            },
                          ),
                          _buildReportCard(
                            title: 'Cashflow Report',
                            description: 'Analyze your cash movement',
                            icon: Icons.show_chart,
                            color: Colors.teal,
                            onTap: () {
                              Navigator.of(context).pushNamed(RouteNames.cashflowReport);
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
                          _buildReportCard(
                            title: 'Financial Insights',
                            description: 'Get actionable financial advice',
                            icon: Icons.lightbulb_outline,
                            color: Colors.amber,
                            onTap: () {
                              _showComingSoonDialog(context, 'Financial Insights');
                            },
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Financial overview
                      if (_overviewData != null) ...[
                        Text(
                          'Financial Overview',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Month trend chart
                        _buildTrendChart(theme),
                        const SizedBox(height: 24),
                        
                        // Stats cards
                        _buildStatCards(theme, currencyFormatter),
                        
                        // Add bottom padding for bottom navigation
                        const SizedBox(height: 80),
                      ],
                    ],
                  ),
                ),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
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
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
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
      return const SizedBox.shrink();
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Trend',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Chart
            SizedBox(
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
                          if (value == 0) return const Text('');
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
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
        const SizedBox(width: 4),
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
            const SizedBox(width: 16),
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
        const SizedBox(height: 16),
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
            const SizedBox(width: 16),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
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
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 8),
            Text(
              'Select the data you want to export',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            
            // Export options list
            ...exportOptions.map((option) => ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
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
                // Show date range picker for proper interval
                await _showDateRangePicker(context, option['type'], option['title']);
              },
            )),
            
            const SizedBox(height: 16),
            
            // Cancel button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _showDateRangePicker(BuildContext context, String exportType, String title) async {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: firstDayOfMonth,
        end: now,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      // Format dates for API
      final startDate = DateFormat('yyyy-MM-dd').format(picked.start);
      final endDate = DateFormat('yyyy-MM-dd').format(picked.end);
      
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Text('Exporting $title data...'),
            ],
          ),
          duration: const Duration(seconds: 1),
        ),
      );
      
      try {
        // Call export API based on type
        final result = await _reportService.exportReport(
          reportType: exportType,
          startDate: startDate,
          endDate: endDate,
        );
        
        if (result['success']) {
          // Here we would handle the downloaded file
          // For now, just show a success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title data exported successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Export failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Coming Soon'),
        content: Text('The $feature feature is coming soon! Stay tuned for updates.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}