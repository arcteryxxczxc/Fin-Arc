// lib/screens/dashboard/updated_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../services/report_service.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_display.dart';
import '../../widgets/layout/screen_wrapper.dart';
import '../../routes/route_names.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ReportService _reportService = ReportService();
  
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _dashboardData;
  final currencyFormatter = NumberFormat.currency(symbol: '\$');
  
  int _selectedPeriod = 1; // 0: Today, 1: Week, 2: Month, 3: Year
  final List<String> _periods = ['Today', 'This Week', 'This Month', 'This Year'];
  
  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }
  
  Future<void> _fetchDashboardData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final result = await _reportService.getDashboardData();
      
      if (!mounted) return;
      
      if (result['success']) {
        setState(() {
          _dashboardData = result['data'];
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
        _error = 'Failed to load dashboard data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    
    return ScreenWrapper(
      currentRoute: RouteNames.dashboard,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Fin-Arc Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchDashboardData,
              tooltip: 'Refresh data',
            ),
            IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.notifications_outlined),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: const Text(
                        '3',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              onPressed: () {
                // Show notifications
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications coming soon')),
                );
              },
              tooltip: 'Notifications',
            ),
          ],
        ),
        body: _isLoading 
          ? const LoadingIndicator(message: 'Loading dashboard data...')
          : _error != null
            ? ErrorDisplay(
                error: _error!,
                onRetry: _fetchDashboardData,
              )
            : RefreshIndicator(
                onRefresh: _fetchDashboardData,
                child: _buildDashboardContent(themeData, user),
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddTransactionDialog(context),
          tooltip: 'Add transaction',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
  
  Widget _buildDashboardContent(ThemeData themeData, user) {
    // Use dashboard data or defaults
    final stats = _dashboardData?['stats'] ?? {
      'today': {'expenses': 0, 'income': 0, 'balance': 0},
      'week': {'expenses': 0, 'income': 0, 'balance': 0},
      'month': {'expenses': 0, 'income': 0, 'balance': 0},
      'year': {'expenses': 0, 'income': 0, 'balance': 0}
    };
    
    final categories = _dashboardData?['categories'] ?? [];
    
    final trend = _dashboardData?['trend'] ?? [];
    
    final recentTransactions = _dashboardData?['recent_transactions'] ?? {
      'expenses': [],
      'income': []
    };
    
    final budgetOverview = _dashboardData?['budget_overview'] ?? [];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome message and date
          _buildWelcomeCard(user, themeData),
          const SizedBox(height: 20),
          
          // Financial summary
          _buildFinancialSummary(stats, themeData),
          const SizedBox(height: 24),
          
          // Main charts section
          _buildFinancialCharts(trend, themeData),
          const SizedBox(height: 24),
          
          // Budget progress
          if (budgetOverview.isNotEmpty) ...[
            _buildBudgetProgress(budgetOverview, themeData),
            const SizedBox(height: 24),
          ],
          
          // Spending breakdown
          if (categories.isNotEmpty) ...[
            _buildSpendingBreakdown(categories, themeData),
            const SizedBox(height: 24),
          ],
          
          // Recent transactions
          _buildRecentTransactions(recentTransactions, themeData),
          
          // Add bottom padding for floating action button
          const SizedBox(height: 80),
        ],
      ),
    );
  }
  
  Widget _buildWelcomeCard(user, ThemeData themeData) {
    final now = DateTime.now();
    String greeting;
    
    // Determine greeting based on time of day
    final hour = now.hour;
    if (hour < 12) {
      greeting = "Good Morning";
    } else if (hour < 17) {
      greeting = "Good Afternoon";
    } else {
      greeting = "Good Evening";
    }
    
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
                    "$greeting, ${user?.firstName ?? user?.username ?? 'User'}!",
                    style: themeData.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(now),
                    style: themeData.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            CircleAvatar(
              radius: 24,
              backgroundColor: themeData.primaryColor,
              child: Text(
                user?.initials ?? 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFinancialSummary(Map<String, dynamic> stats, ThemeData themeData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Financial Summary',
              style: themeData.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            DropdownButton<int>(
              value: _selectedPeriod,
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPeriod = value;
                  });
                }
              },
              items: _periods.asMap().entries.map((entry) {
                return DropdownMenuItem<int>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Summary cards based on selected period
        _buildSummaryCards(stats, _selectedPeriod, themeData),
      ],
    );
  }
  
  Widget _buildSummaryCards(Map<String, dynamic> stats, int selectedPeriod, ThemeData themeData) {
    final Map<String, dynamic> periodData;
    switch (selectedPeriod) {
      case 0:
        periodData = stats['today'];
        break;
      case 1:
        periodData = stats['week'];
        break;
      case 2:
        periodData = stats['month'];
        break;
      case 3:
        periodData = stats['year'];
        break;
      default:
        periodData = stats['month'];
    }
    
    final income = (periodData['income'] as num?)?.toDouble() ?? 0.0;
    final expenses = (periodData['expenses'] as num?)?.toDouble() ?? 0.0;
    final balance = (periodData['balance'] as num?)?.toDouble() ?? 0.0;
    
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Income',
            income,
            Icons.arrow_upward,
            Colors.green,
            themeData,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Expenses',
            expenses,
            Icons.arrow_downward,
            Colors.red,
            themeData,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Balance',
            balance,
            balance >= 0 ? Icons.account_balance_wallet : Icons.warning,
            balance >= 0 ? Colors.blue : Colors.orange,
            themeData,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSummaryCard(
    String title,
    double amount,
    IconData icon,
    Color color,
    ThemeData themeData,
  ) {
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
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: themeData.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              currencyFormatter.format(amount),
              style: themeData.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: title == 'Balance' ? (amount >= 0 ? null : Colors.red) : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFinancialCharts(List<dynamic> trend, ThemeData themeData) {
    // Extract data for the chart
    final List<FlSpot> incomeSpots = [];
    final List<FlSpot> expenseSpots = [];
    final List<String> months = [];
    
    if (trend.isNotEmpty) {
      for (int i = 0; i < trend.length; i++) {
        final monthData = trend[i];
        final income = (monthData['income'] as num?)?.toDouble() ?? 0.0;
        final expenses = (monthData['expenses'] as num?)?.toDouble() ?? 0.0;
        
        incomeSpots.add(FlSpot(i.toDouble(), income));
        expenseSpots.add(FlSpot(i.toDouble(), expenses));
        months.add(monthData['month'] ?? '');
      }
    } else {
      // Sample data if no trend data is available
      final now = DateTime.now();
      for (int i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        months.add(DateFormat('MMM').format(month));
        
        // Zero data
        incomeSpots.add(FlSpot((5 - i).toDouble(), 0));
        expenseSpots.add(FlSpot((5 - i).toDouble(), 0));
      }
    }
    
    // Find max Y value for chart scaling
    double maxY = 0;
    for (final spot in incomeSpots) {
      if (spot.y > maxY) maxY = spot.y;
    }
    for (final spot in expenseSpots) {
      if (spot.y > maxY) maxY = spot.y;
    }
    
    // Round up max value for nice chart scaling
    maxY = ((maxY / 500).ceil() * 500).toDouble();
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
              'Income & Expenses Trend',
              style: themeData.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last 6 months',
              style: themeData.textTheme.bodySmall,
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
                        color: themeData.dividerColor.withOpacity(0.2),
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
                            '\$${value.toInt()}',
                            style: TextStyle(
                              color: themeData.textTheme.bodySmall?.color,
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
                                color: themeData.textTheme.bodySmall?.color,
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
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('Income', style: themeData.textTheme.bodySmall),
                  ],
                ),
                const SizedBox(width: 24),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('Expenses', style: themeData.textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBudgetProgress(List<dynamic> budgetOverview, ThemeData themeData) {
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
                  'Budget Progress',
                  style: themeData.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(RouteNames.budgetReport);
                  },
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Budget progress bars
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: budgetOverview.length > 3 ? 3 : budgetOverview.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final budget = budgetOverview[index];
                final name = budget['name'] ?? 'Category';
                final spent = (budget['spent'] as num?)?.toDouble() ?? 0.0;
                final total = (budget['budget'] as num?)?.toDouble() ?? 0.0;
                final percentage = (budget['percentage'] as num?)?.toDouble() ?? 0.0;
                final status = budget['status'] ?? '';
                
                // Determine color based on budget status
                Color progressColor;
                if (status == 'over') {
                  progressColor = Colors.red;
                } else if (status == 'warning' || percentage > 80) {
                  progressColor = Colors.orange;
                } else {
                  progressColor = Colors.green;
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(name, style: themeData.textTheme.bodyMedium),
                        Text(
                          '${currencyFormatter.format(spent)} / ${currencyFormatter.format(total)}',
                          style: themeData.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage > 0 ? (percentage / 100 > 1 ? 1 : percentage / 100) : 0,
                        minHeight: 8,
                        backgroundColor: themeData.dividerColor.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${percentage.toInt()}%',
                          style: themeData.textTheme.bodySmall,
                        ),
                        if (status == 'over')
                          const Text(
                            'Over budget!',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
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
  
  Widget _buildSpendingBreakdown(List<dynamic> categories, ThemeData themeData) {
    // Calculate total spending
    double totalSpent = 0;
    for (final category in categories) {
      totalSpent += (category['total'] as num?)?.toDouble() ?? 0.0;
    }
    
    // Prepare data for pie chart
    List<PieChartSectionData> sections = [];
    
    for (final category in categories) {
      final name = category['name'] ?? 'Category';
      final spent = (category['total'] as num?)?.toDouble() ?? 0.0;
      final colorHex = category['color'] ?? '#757575';
      
      // Skip categories with no spending
      if (spent <= 0) continue;
      
      // Calculate percentage
      final percentage = totalSpent > 0 ? (spent / totalSpent) * 100 : 0;
      
      // Parse color from hex string
      final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
      
      sections.add(
        PieChartSectionData(
          color: color,
          value: spent,
          title: '${percentage.toInt()}%',
          radius: 70,
          titleStyle: const TextStyle(
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spending by Category',
                  style: themeData.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(RouteNames.categoryList);
                  },
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (sections.isEmpty) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No spending data available'),
                ),
              ),
            ] else ...[
              // Pie chart
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Categories legend
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: categories.map((category) {
                  final name = category['name'] ?? 'Category';
                  final spent = (category['total'] as num?)?.toDouble() ?? 0.0;
                  final colorHex = category['color'] ?? '#757575';
                  
                  // Skip categories with no spending
                  if (spent <= 0) return const SizedBox.shrink();
                  
                  // Parse color from hex string
                  final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
                  
                  return Row(
                    mainAxisSize: MainAxisSize.min,
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
                      Flexible(
                        child: Text(
                          '$name: ${currencyFormatter.format(spent)}',
                          style: themeData.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildRecentTransactions(Map<String, dynamic> recentTransactions, ThemeData themeData) {
    final expenses = List<Map<String, dynamic>>.from(recentTransactions['expenses'] ?? []);
    final income = List<Map<String, dynamic>>.from(recentTransactions['income'] ?? []);
    
    // Combine and sort by date (newest first)
    final allTransactions = [
      ...expenses.map((e) => {...e, 'type': 'expense'}),
      ...income.map((i) => {...i, 'type': 'income'}),
    ];
    
    allTransactions.sort((a, b) {
      final dateA = DateTime.parse(a['date'] as String);
      final dateB = DateTime.parse(b['date'] as String);
      return dateB.compareTo(dateA);
    });
    
    // Take only the first 5 transactions
    final recentList = allTransactions.take(5).toList();
    
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
                  'Recent Transactions',
                  style: themeData.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to transactions screen - choose expense or income list
                    Navigator.of(context).pushNamed(RouteNames.expenseList);
                  },
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (recentList.isEmpty) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No recent transactions'),
                ),
              ),
            ] else ...[
              // Transactions list
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentList.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final transaction = recentList[index];
                  final isExpense = transaction['type'] == 'expense';
                  final title = isExpense 
                    ? (transaction['description'] ?? 'Expense')
                    : (transaction['source'] ?? 'Income');
                  final category = transaction['category'] ?? 'Uncategorized';
                  final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
                  final date = transaction['date'] ?? '';
                  
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                    leading: CircleAvatar(
                      backgroundColor: isExpense ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                      child: Icon(
                        isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isExpense ? Colors.red : Colors.green,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      title,
                      style: themeData.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      isExpense
                        ? '$category • ${DateFormat('MMM d').format(DateTime.parse(date))}'
                        : DateFormat('MMM d').format(DateTime.parse(date)),
                      style: themeData.textTheme.bodySmall,
                    ),
                    trailing: Text(
                      isExpense ? '-${currencyFormatter.format(amount)}' : '+${currencyFormatter.format(amount)}',
                      style: TextStyle(
                        color: isExpense ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      // Navigate to transaction detail
                      if (isExpense) {
                        Navigator.of(context).pushNamed(
                          RouteNames.expenseDetail,
                          arguments: {'expenseId': transaction['id']},
                        );
                      } else {
                        Navigator.of(context).pushNamed(
                          RouteNames.incomeDetail,
                          arguments: {'incomeId': transaction['id']},
                        );
                      }
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  void _showAddTransactionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Transaction',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildAddButton(
                    context: ctx,
                    icon: Icons.arrow_downward,
                    label: 'Add Expense',
                    color: Colors.red,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).pushNamed(RouteNames.addExpense);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAddButton(
                    context: ctx,
                    icon: Icons.arrow_upward,
                    label: 'Add Income',
                    color: Colors.green,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).pushNamed(RouteNames.addIncome);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAddButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}