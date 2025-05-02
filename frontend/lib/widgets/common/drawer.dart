// lib/widgets/common/drawer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../routes/route_names.dart';
import '../../utils/color_utils.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;
  
  const AppDrawer({super.key, required this.currentRoute});
  
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
                
                // Comment out screens that don't exist yet
                /*
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
                */
                
                const Divider(),
                // Settings & Profile
                _buildDrawerItem(
                  context: context,
                  icon: Icons.person,
                  title: 'Profile',
                  route: RouteNames.profile,
                  isSelected: currentRoute == RouteNames.profile,
                ),
                
                // Comment out settings screen for now
                /*
                _buildDrawerItem(
                  context: context,
                  icon: Icons.settings,
                  title: 'Settings',
                  route: RouteNames.settings,
                  isSelected: currentRoute == RouteNames.settings,
                ),
                */
                
                // Theme switcher
                ListTile(
                  leading: Icon(
                    themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Dark Mode'),
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme();
                    },
                    activeColor: theme.colorScheme.primary,
                  ),
                ),
                
                const Divider(),
                // Logout
                ListTile(
                  leading: const Icon(
                    Icons.logout,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () => _confirmLogout(context),
                ),
              ],
            ),
          ),
          
          // App version
          const Padding(
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
      tileColor: isSelected ? ColorUtils.withOpacity(theme.colorScheme.primary, 0.1) : null,
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
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
          ElevatedButton(
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
              
              // Check if widget is still mounted before using context
              if (context.mounted) {
                // Navigate to login screen
                Navigator.of(context).pushReplacementNamed(RouteNames.login);
              }
            },
            child: const Text('Logout'),        
          ),
        ],
      ),
    );
  }
}