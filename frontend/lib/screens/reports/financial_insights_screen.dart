// lib/screens/reports/financial_insights_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/report_service.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_display.dart';
import '../../widgets/layout/screen_wrapper.dart';
import '../../routes/route_names.dart';

class FinancialInsightsScreen extends StatefulWidget {
  const FinancialInsightsScreen({super.key});

  @override
  _FinancialInsightsScreenState createState() => _FinancialInsightsScreenState();
}

class _FinancialInsightsScreenState extends State<FinancialInsightsScreen> {
  final ReportService _reportService = ReportService();
  
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _insightsData;
  
  @override
  void initState() {
    super.initState();
    _fetchInsightsData();
  }
  
  Future<void> _fetchInsightsData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // For now, we're using the dashboard data endpoint
      // In the future, this would be replaced with a dedicated insights endpoint
      final result = await _reportService.getDashboardData();
      
      if (result['success']) {
        setState(() {
          // Extract insights data or use the full dashboard data if insights aren't separated
          _insightsData = result['data']['insights'] as Map<String, dynamic>? ?? result['data'];
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
        _error = 'Failed to load insights: $e';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ScreenWrapper(
      currentRoute: RouteNames.reports,
      showBottomNav: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Financial Insights'),
        ),
        body: _isLoading 
          ? const LoadingIndicator(message: 'Analyzing your financial data...')
          : _error != null
            ? ErrorDisplay(
                error: _error!,
                onRetry: _fetchInsightsData,
              )
            : _buildInsightsContent(theme),
      ),
    );
  }
  
  Widget _buildInsightsContent(ThemeData theme) {
    // For now, show a placeholder screen with example insights
    // This will be replaced with actual data when the API is ready
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Financial Health',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Financial health score card
          _buildHealthScoreCard(theme),
          const SizedBox(height: 24),
          
          // Key insights
          Text(
            'Key Insights',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // List of insights
          ...List.generate(5, (index) => _buildInsightCard(
            theme,
            _getSampleInsights()[index],
          )),
          
          const SizedBox(height: 24),
          
          // Recommendations
          Text(
            'Recommendations',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // List of recommendations
          ...List.generate(3, (index) => _buildRecommendationCard(
            theme,
            _getSampleRecommendations()[index],
          )),
          
          const SizedBox(height: 80),
        ],
      ),
    );
  }
  
  Widget _buildHealthScoreCard(ThemeData theme) {
    // Sample health score between 0-100
    const healthScore = 78;
    
    // Determine score color based on value
    Color scoreColor;
    String scoreText;
    if (healthScore >= 80) {
      scoreColor = Colors.green;
      scoreText = 'Excellent';
    } else if (healthScore >= 60) {
      scoreColor = Colors.orange;
      scoreText = 'Good';
    } else if (healthScore >= 40) {
      scoreColor = Colors.amber;
      scoreText = 'Fair';
    } else {
      scoreColor = Colors.red;
      scoreText = 'Needs Improvement';
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
              'Financial Health Score',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Circular progress indicator
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: healthScore / 100,
                          strokeWidth: 12,
                          backgroundColor: Colors.grey.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$healthScore',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: scoreColor,
                              ),
                            ),
                            const Text(
                              'out of 100',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                
                // Score details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scoreText,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your financial health is good, but there\'s room for improvement.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            
            const Text(
              'Last updated: Today',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInsightCard(ThemeData theme, Map<String, dynamic> insight) {
    final IconData icon = insight['icon'];
    final Color color = insight['color'];
    final String title = insight['title'];
    final String description = insight['description'];
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
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
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
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
  
  Widget _buildRecommendationCard(ThemeData theme, Map<String, dynamic> recommendation) {
    final String title = recommendation['title'];
    final String description = recommendation['description'];
    final IconData icon = recommendation['icon'];
    final Color color = recommendation['color'];
    final String actionText = recommendation['actionText'];
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('This feature is coming soon!'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                ),
                child: Text(actionText),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  List<Map<String, dynamic>> _getSampleInsights() {
    return [
      {
        'icon': Icons.trending_up,
        'color': Colors.green,
        'title': 'Spending is stable',
        'description': 'Your overall spending has been consistent over the past 3 months.',
      },
      {
        'icon': Icons.restaurant,
        'color': Colors.orange,
        'title': 'Food expenses increasing',
        'description': 'Your food and dining expenses increased by 15% compared to last month.',
      },
      {
        'icon': Icons.savings,
        'color': Colors.blue,
        'title': 'Good savings rate',
        'description': 'You\'re saving 20% of your income, which is above the recommended 15%.',
      },
      {
        'icon': Icons.warning,
        'color': Colors.red,
        'title': 'Budget alert',
        'description': 'You\'ve reached 90% of your transportation budget for this month.',
      },
      {
        'icon': Icons.calendar_today,
        'color': Colors.purple,
        'title': 'Subscription due soon',
        'description': 'Your streaming service subscription will renew in 3 days.',
      },
    ];
  }
  
  List<Map<String, dynamic>> _getSampleRecommendations() {
    return [
      {
        'icon': Icons.savings,
        'color': Colors.blue,
        'title': 'Create an emergency fund',
        'description': 'It\'s recommended to have 3-6 months of expenses saved for emergencies. Based on your spending, aim for \$10,000.',
        'actionText': 'Start Saving Plan',
      },
      {
        'icon': Icons.credit_card,
        'color': Colors.green,
        'title': 'Reduce credit card debt',
        'description': 'Paying off your high-interest credit card debt could save you \$120 in interest payments each month.',
        'actionText': 'View Debt Payoff Plan',
      },
      {
        'icon': Icons.pie_chart,
        'color': Colors.purple,
        'title': 'Adjust your budget allocation',
        'description': 'Your entertainment spending is higher than recommended. Consider reducing it by 15% and redirecting those funds to savings.',
        'actionText': 'Optimize Budget',
      },
    ];
  }
}