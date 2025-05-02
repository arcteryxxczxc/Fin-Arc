import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class FinArcLineChart extends StatelessWidget {
  final List<double> incomeData;
  final List<double> expenseData;
  final List<String> labels;
  final double? maxY;
  final String title;
  
  const FinArcLineChart({
    super.key,
    required this.incomeData,
    required this.expenseData,
    required this.labels,
    this.maxY,
    this.title = 'Income vs Expenses',
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Calculate max Y value if not provided
    double yMax = maxY ?? 0;
    if (maxY == null) {
      for (int i = 0; i < incomeData.length; i++) {
        yMax = [yMax, incomeData[i], expenseData[i]].reduce((curr, next) => curr > next ? curr : next);
      }
      // Round up max value for nice chart scaling
      yMax = ((yMax / 500).ceil() * 500).toDouble();
      if (yMax < 100) yMax = 100;
    }
    
    // Create data spots
    final List<FlSpot> incomeSpots = [];
    final List<FlSpot> expenseSpots = [];
    
    for (int i = 0; i < incomeData.length; i++) {
      incomeSpots.add(FlSpot(i.toDouble(), incomeData[i]));
      expenseSpots.add(FlSpot(i.toDouble(), expenseData[i]));
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
              title,
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
                    horizontalInterval: yMax / 5,
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
                            '\$${value.toInt()}',
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
                              fontSize: 10,
                            ),
                          );
                        },
                        interval: yMax / 5,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < labels.length) {
                            return Text(
                              labels[index],
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
                  maxX: labels.length - 1.0,
                  minY: 0,
                  maxY: yMax,
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
}

class FinArcPieChart extends StatelessWidget {
  final List<ChartDataItem> items;
  final String title;
  final double radius;
  
  const FinArcPieChart({
    super.key,
    required this.items,
    this.title = 'Distribution',
    this.radius = 80,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    
    // Prepare pie chart sections
    List<PieChartSectionData> sections = [];
    
    for (final item in items) {
      if (item.value <= 0) continue; // Skip zero or negative values
      
      sections.add(
        PieChartSectionData(
          color: item.color,
          value: item.value,
          title: '${item.percentage.toInt()}%',
          radius: radius,
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
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Pie chart
            SizedBox(
              height: radius * 2 + 40,
              child: sections.isEmpty
                ? const Center(child: Text('No data available'))
                : PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
            ),
            
            const SizedBox(height: 16),
            
            // Legend list
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                
                // Skip items with no value
                if (item.value <= 0) return const SizedBox.shrink();
                
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  leading: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(item.label),
                  trailing: Text(
                    '${currencyFormatter.format(item.value)} (${item.percentage.toInt()}%)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
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

class FinArcBarChart extends StatelessWidget {
  final List<ChartDataItem> items;
  final String title;
  final bool horizontal;
  
  const FinArcBarChart({
    super.key,
    required this.items,
    this.title = 'Bar Chart',
    this.horizontal = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    
    // Skip items with no value
    final validItems = items.where((item) => item.value > 0).toList();
    
    if (validItems.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(
                height: 200,
                child: Center(child: Text('No data available')),
              ),
            ],
          ),
        ),
      );
    }
    
    // Find max value for chart scaling
    double maxValue = validItems.map((item) => item.value).reduce((a, b) => a > b ? a : b);
    
    // Round up max value for nice chart scaling
    maxValue = ((maxValue / 1000).ceil() * 1000).toDouble();
    if (maxValue < 100) maxValue = 100;
    
    // Prepare bar chart groups
    final List<BarChartGroupData> barGroups = [];
    
    for (int i = 0; i < validItems.length; i++) {
      final item = validItems[i];
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: item.value,
              color: item.color,
              width: 20,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ],
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
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Bar chart
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.center,
                  maxY: maxValue,
                  minY: 0,
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: maxValue / 5,
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
                          if (index >= 0 && index < validItems.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                validItems[index].label,
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
                            '\$${(value / 1000).toInt()}K',
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
                              fontSize: 10,
                            ),
                          );
                        },
                        interval: maxValue / 5,
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
            
            // Legend list
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: validItems.length,
              itemBuilder: (context, index) {
                final item = validItems[index];
                
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  leading: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(item.label),
                  trailing: Text(
                    currencyFormatter.format(item.value),
                    style: const TextStyle(fontWeight: FontWeight.bold),
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

class FinArcBudgetProgressChart extends StatelessWidget {
  final List<BudgetProgressItem> items;
  final String title;
  
  const FinArcBudgetProgressChart({
    super.key,
    required this.items,
    this.title = 'Budget Progress',
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Progress bars
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final item = items[index];
                
                // Determine color based on percentage
                Color progressColor;
                if (item.percentage >= 100) {
                  progressColor = Colors.red;
                } else if (item.percentage >= 80) {
                  progressColor = Colors.orange;
                } else {
                  progressColor = Colors.green;
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: item.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.label,
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
                        Text('Budget: ${currencyFormatter.format(item.budget)}'),
                        Text(
                          '${item.percentage.toInt()}%',
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
                        value: item.percentage / 100 > 1 ? 1 : item.percentage / 100,
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
                          'Spent: ${currencyFormatter.format(item.spent)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          'Remaining: ${currencyFormatter.format(item.remaining)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: item.remaining >= 0 ? Colors.green : Colors.red,
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
}

class ChartDataItem {
  final String label;
  final double value;
  final double percentage;
  final Color color;
  
  ChartDataItem({
    required this.label,
    required this.value,
    required this.percentage,
    required this.color,
  });
  
  factory ChartDataItem.fromJson(Map<String, dynamic> json, {String? colorKey}) {
    final colorHex = json[colorKey ?? 'color'] as String? ?? '#757575';
    final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    
    return ChartDataItem(
      label: json['name'] as String,
      value: (json['total'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
      color: color,
    );
  }
}

class BudgetProgressItem {
  final String label;
  final double budget;
  final double spent;
  final double remaining;
  final double percentage;
  final Color color;
  final String status;
  
  BudgetProgressItem({
    required this.label,
    required this.budget,
    required this.spent,
    required this.remaining,
    required this.percentage,
    required this.color,
    required this.status,
  });
  
  factory BudgetProgressItem.fromJson(Map<String, dynamic> json) {
    final colorHex = json['color_code'] as String? ?? '#757575';
    final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    
    return BudgetProgressItem(
      label: json['name'] as String,
      budget: (json['budget'] as num).toDouble(),
      spent: (json['spent'] as num).toDouble(),
      remaining: (json['remaining'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
      color: color,
      status: json['status'] as String? ?? '',
    );
  }
}