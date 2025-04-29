import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/income_provider.dart';
import '../../providers/category_provider.dart';
import '../../services/report_service.dart';
import '../expenses/add_expense_screen.dart';
import '../income/add_income_screen.dart';
import '../profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final currencyFormatter = NumberFormat.currency(symbol: '\$');
  final ReportService _reportService = ReportService();
  
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _dashboardData;
  
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Fetch initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDashboardData();
      
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      final incomeProvider = Provider.of<IncomeProvider>(context, listen: false);
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      
      // Fetch recent expenses, income, and categories
      expenseProvider.fetchExpenses(refresh: true);
      incomeProvider.fetchIncomes(refresh: true);
      categoryProvider.fetchCategories();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final result = await _reportService.getDashboardData();
      
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
      setState(() {
        _error = 'Failed to load dashboard data: $e';
        _isLoading = false;
      });
    }
  }
  
  // Define pages for the bottom navigation
  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return _buildDashboardHome();
      case 1:
        return _buildExpensesPage();
      case 2:
        return _buildIncomePage();
      case 3:
        return _buildReportsPage();
      case 4:
        return ProfileScreen();
      default:
        return _buildDashboardHome();
    }
  }
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  void _showAddTransactionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.money_off),
              label: Text('Add Expense'),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AddExpenseScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              icon: Icon(Icons.attach_money),
              label: Text('Add Income'),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AddIncomeScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fin-Arc Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchDashboardData,
          ),
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              // Show notifications
            },
          ),
        ],
      ),
      body: _getPage(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.money_off),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Income',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(Icons.add),
        onPressed: () {
          _showAddTransactionDialog(context);
        },
      ),
    );
  }
  
  // Dashboard home page
  Widget _buildDashboardHome() {
    final authProvider = Provider.of<AuthProvider>(context);
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final incomeProvider = Provider.of<IncomeProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    
    // Use dashboard data or defaults
    final stats = _dashboardData?['stats'] ?? {
      'today': {'expenses': 35, 'income': 0, 'balance': -35},
      'week': {'expenses': 250, 'income': 100, 'balance': -150},
      'month': {'expenses': 1800, 'income': 2500, 'balance': 700},
      'year': {'expenses': 22000, 'income': 30000, 'balance': 8000}
    };
    
    final categories = _dashboardData?['categories'] ?? [];
    
    final recentTransactions = _dashboardData?['recent_transactions'] ?? {
      'expenses': [],
      'income': []
    };
    
    return RefreshIndicator(
      onRefresh: () async {
        await _fetchDashboardData();
        await expenseProvider.fetchExpenses(refresh: true);
        await incomeProvider.fetchIncomes(refresh: true);
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${authProvider.user?.firstName ?? authProvider.user?.username ?? 'User'}!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Today is ${DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now())}',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            
            // Financial summary cards
            _buildSummaryCards(stats),
            SizedBox(height: 20),
            
            // Recent transactions
            Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            
            if (_isLoading)
              Center(child: CircularProgressIndicator())
            else if (_error != null)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red),
                      SizedBox(height: 8),
                      Text(
                        'Error loading data',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(_error!, textAlign: TextAlign.center),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _fetchDashboardData,
                        child: Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              )
            else if ((recentTransactions['expenses'] as List).isEmpty && 
                     (recentTransactions['income'] as List).isEmpty)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.info_outline, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'No transactions yet',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add your first expense or income to get started',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              _buildRecentTransactions(recentTransactions),
            
            SizedBox(height: 20),
            
            // Spending by Category
            Text(
              'Spending by Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            
            _buildCategoryChart(categories, categoryProvider),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryCards(Map<String, dynamic> stats) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: [
        _buildSummaryCard('Today', stats['today']),
        _buildSummaryCard('This Week', stats['week']),
        _buildSummaryCard('This Month', stats['month']),
        _buildSummaryCard('This Year', stats['year']),
      ],
    );
  }
  
  Widget _buildSummaryCard(String title, Map<String, dynamic> data) {
    final balance = data['balance'] ?? 0.0;
    final income = data['income'] ?? 0.0;
    final expenses = data['expenses'] ?? 0.0;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              currencyFormatter.format(balance),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: balance >= 0 ? Colors.green[700] : Colors.red[700],
              ),
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '+${currencyFormatter.format(income)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[600],
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  '|',
                  style: TextStyle(
                    color: Colors.grey[300],
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  '-${currencyFormatter.format(expenses)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRecentTransactions(Map<String, dynamic> recentTransactions) {
    final expenses = List<Map<String, dynamic>>.from(recentTransactions['expenses'] ?? []);
    final income = List<Map<String, dynamic>>.from(recentTransactions['income'] ?? []);
    
    // Combine expenses and income, sort by date (newest first)
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transactions list
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: recentList.length,
              separatorBuilder: (context, index) => Divider(),
              itemBuilder: (context, index) {
                final transaction = recentList[index];
                final isExpense = transaction['type'] == 'expense';
                final title = isExpense 
                  ? transaction['description'] ?? 'Expense'
                  : transaction['source'] ?? 'Income';
                final category = isExpense 
                  ? transaction['category'] ?? 'Uncategorized'
                  : '';
                final amount = (transaction['amount'] ?? 0.0).toDouble();
                final date = transaction['date'] ?? '';
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isExpense ? Colors.red[100] : Colors.green[100],
                    child: Icon(
                      isExpense ? Icons.money_off : Icons.attach_money,
                      color: isExpense ? Colors.red : Colors.green,
                    ),
                  ),
                  title: Text(title),
                  subtitle: Text(
                    isExpense 
                      ? '${category} • ${DateFormat('MMM d, yyyy').format(DateTime.parse(date))}'
                      : DateFormat('MMM d, yyyy').format(DateTime.parse(date))
                  ),
                  trailing: Text(
                    isExpense ? '-${currencyFormatter.format(amount)}' : '+${currencyFormatter.format(amount)}',
                    style: TextStyle(
                      color: isExpense ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
            
            SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  // Navigate to transactions list
                  if (_selectedIndex != 1 && _selectedIndex != 2) {
                    setState(() {
                      _selectedIndex = 1; // Go to expenses page
                    });
                  }
                },
                icon: Icon(Icons.list),
                label: Text('View All Transactions'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategoryChart(List<dynamic> categories, CategoryProvider categoryProvider) {
    // If no categories data from API, use categories from provider
    if (categories.isEmpty && categoryProvider.expenseCategories.isNotEmpty) {
      categories = categoryProvider.expenseCategories.map((cat) {
        // Create a map with the format expected by the chart
        return {
          'id': cat.id,
          'name': cat.name, 
          'color': cat.colorCode,
          'total': cat.currentSpending ?? 0.0,
        };
      }).toList();
    }
    
    // If still no data, show placeholder
    if (categories.isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          height: 200,
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No category data available'),
          ),
        ),
      );
    }
    
    // Convert categories to data for pie chart
    final List<PieChartSectionData> sections = [];
    double totalSpending = 0;
    
    // Calculate total spending
    for (final category in categories) {
      totalSpending += (category['total'] ?? 0.0).toDouble();
    }
    
    // Create pie sections
    for (final category in categories) {
      final name = category['name'] ?? 'Uncategorized';
      final color = category['color'] ?? '#CCCCCC';
      final total = (category['total'] ?? 0.0).toDouble();
      
      // Skip categories with no spending
      if (total <= 0) continue;
      
      // Calculate percentage
      final percentage = totalSpending > 0 ? (total / totalSpending) * 100 : 0;
      
      // Parse color from hex string
      final colorValue = int.parse(color.replaceFirst('#', '0xFF'));
      
      sections.add(
        PieChartSectionData(
          color: Color(colorValue),
          value: total,
          title: '${percentage.round()}%',
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 250,
              child: sections.isEmpty
                ? Center(child: Text('No spending data'))
                : PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
            ),
            SizedBox(height: 16),
            
            // Legend
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: categories.map((category) {
                final name = category['name'] ?? 'Uncategorized';
                final color = category['color'] ?? '#CCCCCC';
                final total = (category['total'] ?? 0.0).toDouble();
                
                // Skip categories with no spending
                if (total <= 0) return SizedBox.shrink();
                
                // Parse color from hex string
                final colorValue = int.parse(color.replaceFirst('#', '0xFF'));
                
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(colorValue),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '$name: ${currencyFormatter.format(total)}',
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  // Expenses page placeholder
  Widget _buildExpensesPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.money_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Expenses Page',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'View and manage your expenses here',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.add),
            label: Text('Add New Expense'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddExpenseScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  // Income page placeholder
  Widget _buildIncomePage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.attach_money, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Income Page',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'View and manage your income here',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.add),
            label: Text('Add New Income'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddIncomeScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  // Reports page
  Widget _buildReportsPage() {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          flexibleSpace: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TabBar(
                tabs: [
                  Tab(text: 'Monthly'),
                  Tab(text: 'Annual'),
                  Tab(text: 'Budget'),
                ],
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMonthlyReportTab(),
            _buildAnnualReportTab(),
            _buildBudgetReportTab(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMonthlyReportTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Monthly Report',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Monthly financial reports coming soon',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.analytics),
            label: Text('Generate Monthly Report'),
            onPressed: () {
              // Generate monthly report
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildAnnualReportTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Annual Report',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Annual financial reports coming soon',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.analytics),
            label: Text('Generate Annual Report'),
            onPressed: () {
              // Generate annual report
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildBudgetReportTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Budget Report',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Budget reports coming soon',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.analytics),
            label: Text('Generate Budget Report'),
            onPressed: () {
              // Generate budget report
            },
          ),
        ],
      ),
    );
  }
}