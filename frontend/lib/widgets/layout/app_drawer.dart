// lib/widgets/layout/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Drawer(
      child: Column(
        children: [
          // Drawer header with user info
          UserAccountsDrawerHeader(
            accountName: Text(user?.firstName ?? 'User'),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?.initials ?? 'U',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
            ),
            decoration: BoxDecoration(
              color: theme.primaryColor,
            ),
          ),

          // Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Dashboard
                _buildDrawerItem(
                  context,
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  route: RouteNames.dashboard,
                  isSelected: currentRoute == RouteNames.dashboard,
                ),

                // Expenses
                _buildDrawerItem(
                  context,
                  icon: Icons.arrow_downward,
                  title: 'Expenses',
                  route: RouteNames.expenseList,
                  isSelected: currentRoute == RouteNames.expenseList,
                ),

                // Income
                _buildDrawerItem(
                  context,
                  icon: Icons.arrow_upward,
                  title: 'Income',
                  route: RouteNames.incomeList,
                  isSelected: currentRoute == RouteNames.incomeList,
                ),

                // Categories - Highlighted as new
                Stack(
                  children: [
                    _buildDrawerItem(
                      context,
                      icon: Icons.category,
                      title: 'Categories',
                      route: RouteNames.categoryList,
                      isSelected: currentRoute == RouteNames.categoryList,
                    ),
                    Positioned(
                      right: 16,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'New',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Category Budget Management - Also new
                _buildDrawerItem(
                  context,
                  icon: Icons.account_balance_wallet,
                  title: 'Budget Management',
                  route: '/categories/budget',
                  isSelected: currentRoute == '/categories/budget',
                  indent: 16, // Indented to show it's related to categories
                ),

                const Divider(),

                // Reports
                _buildDrawerItem(
                  context,
                  icon: Icons.bar_chart,
                  title: 'Reports',
                  route: RouteNames.reports,
                  isSelected: currentRoute == RouteNames.reports,
                ),

                // Profile
                _buildDrawerItem(
                  context,
                  icon: Icons.person,
                  title: 'Profile',
                  route: RouteNames.profile,
                  isSelected: currentRoute == RouteNames.profile,
                ),

                // Settings
                _buildDrawerItem(
                  context,
                  icon: Icons.settings,
                  title: 'Settings',
                  route: RouteNames.settings,
                  isSelected: currentRoute == RouteNames.settings,
                ),

                const Divider(),

                // Logout
                ListTile(
                  leading: const Icon(Icons.exit_to_app),
                  title: const Text('Logout'),
                  onTap: () async {
                    // Close drawer
                    Navigator.pop(context);
                    
                    // Show confirmation dialog
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );

                    if (shouldLogout == true && context.mounted) {
                      // Perform logout
                      await authProvider.logout();
                      
                      // Navigate to login screen
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          RouteNames.login,
                          (route) => false,
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    bool isSelected = false,
    double indent = 0,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Theme.of(context).primaryColor : null,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Theme.of(context).primaryColor : null,
            fontWeight: isSelected ? FontWeight.bold : null,
          ),
        ),
        selected: isSelected,
        onTap: () {
          // Close drawer
          Navigator.pop(context);

          // If we're not already on this route, navigate to it
          if (!isSelected) {
            Navigator.pushNamed(context, route);
          }
        },
      ),
    );
  }
}