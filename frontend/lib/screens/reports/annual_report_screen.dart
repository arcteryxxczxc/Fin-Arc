import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '/services/report_service.dart';
import '/widgets/common/loading_indicator.dart';
import '/widgets/common/error_display.dart';
import '/widgets/common/drawer.dart';
import '/routes/route_names.dart';
import '/utils/error_handler.dart';

class AnnualReportScreen extends StatefulWidget {
  const AnnualReportScreen({super.key});

  @override
  _AnnualReportScreenState createState() => _AnnualReportScreenState();
}

class _AnnualReportScreenState extends State<AnnualReportScreen> {
  final ReportService _reportService = ReportService();

  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _reportData;

  // Selected year
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
    _fetchAnnualReport();
  }

  Future<void> _fetchAnnualReport() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _reportService.getAnnualReport(
        year: _selectedYear,
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
    // Don't allow going beyond current year
    if (_selectedYear >= DateTime.now().year) {
      return;
    }

    setState(() {
      _selectedYear++;
    });
    _fetchAnnualReport();
  }

  // Allow user to pick a year from a dialog
  void _showYearPicker(BuildContext context) {
    final now = DateTime.now();
    const firstYear = 2020; // First available year

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Year'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: now.year - firstYear + 1,
            itemBuilder: (context, index) {
              final year = firstYear + index;
              final isSelected = year == _selectedYear;

              return ListTile(
                title: Text('$year'),
                tileColor: isSelected
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : null,
                textColor: isSelected ? Theme.of(context).primaryColor : null,
                trailing: isSelected
                    ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                    : null,
                onTap: () {
                  Navigator.of(context).pop();
                  if (year != _selectedYear) {
                    setState(() {
                      _selectedYear = year;
                    });
                    _fetchAnnualReport();
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Annual Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _showYearPicker(context),
            tooltip: 'Choose Year',
          ),
        ],
      ),
      drawer: AppDrawer(currentRoute: RouteNames.annualReport),
      body: _isLoading
          ? LoadingIndicator(message: 'Loading annual report...')
          : _error != null
              ? ErrorDisplay(
                  error: _error!,
                  onRetry: _fetchAnnualReport,
                )
              : _reportData == null
                  ? const Center(child: Text('No report data available'))
                  : RefreshIndicator(
                      onRefresh: _fetchAnnualReport,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Year selector
                            _buildYearSelector(theme),
                            const SizedBox(height: 24),

                            // Annual summary
                            _buildAnnualSummary(theme, currencyFormatter),
                            const SizedBox(height: 24),

                            // Monthly trends
                            _buildMonthlyTrendsChart(theme),
                            const SizedBox(height: 24),

                            // Quarterly data
                            _buildQuarterlyData(theme, currencyFormatter),
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
    );
  }

  Widget _buildYearSelector(ThemeData theme) {
    // Check if we can go to next year (not beyond current year)
    final now = DateTime.now();
    final canGoNext = _selectedYear < now.year;

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
              onPressed: _previousYear,
              tooltip: 'Previous year',
            ),
            GestureDetector(
              onTap: () => _showYearPicker(context),
              child: Text(
                '$_selectedYear',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: canGoNext ? _nextYear : null,
              tooltip: canGoNext ? 'Next year' : 'Cannot go to future years',
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Annual Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

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

            const SizedBox(height: 24),

            // Savings rate
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.savings,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Savings Rate',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You saved ${savingsRate.toStringAsFixed(1)}% of your income this year',
                          style: const TextStyle(
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

  Widget _buildMonthlyTrendsChart(ThemeData theme) {
    final monthlyData = _reportData!['monthly_data'] as List<dynamic>? ?? [];

    if (monthlyData.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monthly Trends',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('No monthly data available for this year'),
                ),
              ),
            ],
          ),
        ),
      );
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

      months.add(monthName.substring(0, 3)); // Abbreviate month name

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: income,
              color: Colors.green,
              width: 12,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
            ),
            BarChartRodData(
              toY: expenses,
              color: Colors.red,
              width: 12,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
          barsSpace: 4,
        ),
      );

      // Update max value
      maxY = [maxY, income, expenses]
          .reduce((curr, next) => curr > next ? curr : next);
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
              'Monthly Trends',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Chart
            SizedBox(
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
                          if (index >= 0 && index < months.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
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
                          return const Text('');
                        },
                      ),
                    ),
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
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: barGroups,
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
                const SizedBox(width: 24),
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

  Widget _buildQuarterlyData(ThemeData theme, NumberFormat currencyFormatter) {
    final quarterlyData =
        _reportData!['quarterly_data'] as List<dynamic>? ?? [];

    if (quarterlyData.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quarterly Summary',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('No quarterly data available for this year'),
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
              'Quarterly Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Quarterly data table
            Table(
              columnWidths: const {
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
                  children: const [
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(quarterName),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          currencyFormatter.format(income),
                          style: const TextStyle(
                            color: Colors.green,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          currencyFormatter.format(expenses),
                          style: const TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCategories(
      ThemeData theme, NumberFormat currencyFormatter) {
    final categories = _reportData!['categories'] as List<dynamic>? ?? [];

    if (categories.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Expense Categories',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('No expense data available for this year'),
                ),
              ),
            ],
          ),
        ),
      );
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
            Text(
              'Expense Categories',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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

              // Category list
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final name = category['name'] as String;
                  final color = category['color'] as String;
                  final total = (category['total'] as num).toDouble();
                  final percentage = (category['percentage'] as num).toDouble();

                  // Skip categories with no spending
                  if (total <= 0) return const SizedBox.shrink();

                  // Parse color from hex string
                  final colorValue =
                      Color(int.parse(color.replaceFirst('#', '0xFF')));

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
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
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeSources(ThemeData theme, NumberFormat currencyFormatter) {
    final sources = _reportData!['income_sources'] as List<dynamic>? ?? [];

    if (sources.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Income Sources',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('No income data available for this year'),
                ),
              ),
            ],
          ),
        ),
      );
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(6)),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Income Sources',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (barGroups.isEmpty) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No income data available'),
                ),
              ),
            ] else ...[
              // Bar chart
              SizedBox(
                height: 200,
                child: BarChart(
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
                                padding: const EdgeInsets.only(top: 8),
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
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const Text('');
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
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: barGroups,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Income sources list
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sources.length,
                itemBuilder: (context, index) {
                  final source = sources[index];
                  final name = source['name'] as String;
                  final color = source['color'] as String;
                  final total = (source['total'] as num).toDouble();
                  final percentage = (source['percentage'] as num).toDouble();

                  // Skip sources with no income
                  if (total <= 0) return const SizedBox.shrink();

                  // Parse color from hex string
                  final colorValue =
                      Color(int.parse(color.replaceFirst('#', '0xFF')));

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
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
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
