import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  
  // Define pages for the bottom navigation
  final List<Widget> _pages = [
    DashboardHomePage(),
    ExpensesPage(),
    IncomePage(),
    ReportsPage(),
    ProfilePage(),
  ];
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fin-Arc Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              // Open notifications
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
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
          // Show dialog to add expense or income
          _showAddTransactionDialog(context);
        },
      ),
    );
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
                // Navigate to add expense screen
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
                // Navigate to add income screen
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
}

// Dashboard home page
class DashboardHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Financial summary card
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Summary',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryItem(
                        context, 
                        'Income', 
                        '\$2,500.00', 
                        Colors.green
                      ),
                      _buildSummaryItem(
                        context, 
                        'Expenses', 
                        '\$1,800.00', 
                        Colors.red
                      ),
                      _buildSummaryItem(
                        context, 
                        'Balance', 
                        '\$700.00', 
                        Theme.of(context).primaryColor
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          
          // Recent transactions
          Text(
            'Recent Transactions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Card(
            elevation: 4,
            child: ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: 5, // Placeholder for 5 recent transactions
              separatorBuilder: (context, index) => Divider(),
              itemBuilder: (context, index) {
                // Placeholder transaction data
                bool isExpense = index % 2 == 0;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isExpense ? Colors.red[100] : Colors.green[100],
                    child: Icon(
                      isExpense ? Icons.money_off : Icons.attach_money,
                      color: isExpense ? Colors.red : Colors.green,
                    ),
                  ),
                  title: Text('Transaction ${index + 1}'),
                  subtitle: Text('Category • April ${20 + index}, 2025'),
                  trailing: Text(
                    isExpense ? '-\$${(index + 1) * 50}.00' : '+\$${(index + 1) * 100}.00',
                    style: TextStyle(
                      color: isExpense ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 20),
          
          // Placeholder for charts/graphs
          Text(
            'Spending by Category',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Card(
            elevation: 4,
            child: Container(
              height: 200,
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text('Chart will be displayed here'),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryItem(BuildContext context, String title, String amount, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        Text(
          amount,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// Placeholder pages for bottom navigation
class ExpensesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Expenses Page - Implementation in progress'));
  }
}

class IncomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Income Page - Implementation in progress'));
  }
}

class ReportsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Reports Page - Implementation in progress'));
  }
}

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile header
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).primaryColor,
            child: Icon(
              Icons.person,
              size: 50,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          Text(
            authProvider.user?.fullName ?? 'User',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            authProvider.user?.email ?? 'user@example.com',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 32),
          
          // Profile options
          ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit Profile'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to edit profile screen
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.lock),
            title: Text('Change Password'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to change password screen
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to settings screen
            },
          ),
          Divider(),
          SizedBox(height: 16),
          
          // Logout button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(Icons.logout),
              label: Text('Logout'),
              onPressed: () async {
                await authProvider.logout();
                Navigator.of(context).pushReplacementNamed('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}