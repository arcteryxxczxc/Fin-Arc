import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../routes/route_names.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;
  
  const AppDrawer({Key? key, required this.currentRoute}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = authProvider.user;
    final theme = Theme.of(context);
    
    return Drawer(
      child: Column(
        children: [
          // User header
          UserAccountsDrawerHeader(
            accountName: Text(user?.fullName ?? 'User'),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: theme.colorScheme.surface,
              child: Text(
                user?.initials ?? 'U',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
            ),
          ),
          
          // Navigation items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context: context,
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  route: RouteNames.dashboard,
                  isSelected: currentRoute == RouteNames.dashboard,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.arrow_downward,
                  title: 'Expenses',
                  route: RouteNames.expenseList,
                  isSelected: currentRoute.startsWith('/expenses'),
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.arrow_upward,
                  title: 'Income',
                  route: RouteNames.incomeList,
                  isSelected: currentRoute.startsWith('/income'),
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.category,
                  title: 'Categories',
                  route: RouteNames.categoryList,
                  isSelected: currentRoute.startsWith('/categories'),
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.bar_chart,
                  title: 'Reports',
                  route: RouteNames.reports,
                  isSelected: currentRoute.startsWith('/reports'),
                ),
                Divider(),
                // Settings & Profile
                _buildDrawerItem(
                  context: context,
                  icon: Icons.person,
                  title: 'Profile',
                  route: RouteNames.profile,
                  isSelected: currentRoute == RouteNames.profile,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.settings,
                  title: 'Settings',
                  route: RouteNames.settings,
                  isSelected: currentRoute == RouteNames.settings,
                ),
                
                // Theme switcher
                ListTile(
                  leading: Icon(
                    themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text('Dark Mode'),
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme();
                    },
                    activeColor: theme.colorScheme.primary,
                  ),
                ),
                
                Divider(),
                // Logout
                ListTile(
                  leading: Icon(
                    Icons.logout,
                    color: Colors.red,
                  ),
                  title: Text(
                    'Logout',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () => _confirmLogout(context),
                ),
              ],
            ),
          ),
          
          // App version
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Fin-Arc v1.0.0',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String route,
    bool isSelected = false,
  }) {
    final theme = Theme.of(context);
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? theme.colorScheme.primary : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? theme.colorScheme.primary : null,
        ),
      ),
      tileColor: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : null,
      onTap: () {
        Navigator.of(context).pop(); // Close drawer
        
        // Only navigate if not already on the same route
        if (!isSelected) {
          Navigator.of(context).pushReplacementNamed(route);
        }
      },
    );
  }
  
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirm Logout'),
        content: Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
          ElevatedButton(
            child: Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              
              // Close drawer
              Navigator.of(context).pop();
              
              // Logout user
              final authProvider = Provider.of<AuthProvider>(
                context, 
                listen: false
              );
              
              await authProvider.logout();
              
              // Navigate to login screen
              Navigator.of(context).pushReplacementNamed(RouteNames.login);
            },
          ),
        ],
      ),
    );
  }
}