// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/layout/screen_wrapper.dart';
import '../routes/route_names.dart';
import '../utils/error_handler.dart';
import 'auth/change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Refresh user profile when screen is opened
    _refreshUserProfile();
  }

  Future<void> _refreshUserProfile() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshUserProfile();
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, 'Failed to refresh profile: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return ScreenWrapper(
      currentRoute: RouteNames.profile,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          actions: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(14.0),
                child: SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white
                    ),
                  )
                ),
              ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: _isLoading ? null : _refreshUserProfile,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile header
              _buildProfileHeader(context, authProvider),
              const SizedBox(height: 24),
              
              // Account settings
              _buildSection(
                title: 'Account Settings',
                icon: Icons.person_outline,
                children: [
                  _buildListTile(
                    title: 'Edit Profile',
                    icon: Icons.edit,
                    onTap: () {
                      // For now, just show a snackbar since this feature is coming soon
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edit profile feature coming soon')),
                      );
                    },
                  ),
                  _buildListTile(
                    title: 'Change Password',
                    icon: Icons.lock_outline,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ChangePasswordScreen(),
                        ),
                      );
                    },
                  ),
                  _buildListTile(
                    title: 'Login History',
                    icon: Icons.history,
                    onTap: () {
                      // For now, just show a snackbar since this feature is coming soon
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Login history feature coming soon')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // App settings
              _buildSection(
                title: 'App Settings',
                icon: Icons.settings_outlined,
                children: [
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    secondary: Icon(
                      themeProvider.isDarkMode
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      color: Theme.of(context).primaryColor,
                    ),
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme();
                    },
                  ),
                  _buildListTile(
                    title: 'Default Currency',
                    icon: Icons.attach_money,
                    subtitle: 'USD',
                    onTap: () {
                      // For now, just show a snackbar since this feature is coming soon
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Currency settings coming soon')),
                      );
                    },
                  ),
                  _buildListTile(
                    title: 'Notifications',
                    icon: Icons.notifications_none,
                    subtitle: 'Enabled',
                    onTap: () {
                      // For now, just show a snackbar since this feature is coming soon
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notification settings coming soon')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // About & Help
              _buildSection(
                title: 'About & Help',
                icon: Icons.help_outline,
                children: [
                  _buildListTile(
                    title: 'About Fin-Arc',
                    icon: Icons.info_outline,
                    onTap: () {
                      _showAboutDialog(context);
                    },
                  ),
                  _buildListTile(
                    title: 'Help & Support',
                    icon: Icons.support_agent,
                    onTap: () {
                      // For now, just show a snackbar since this feature is coming soon
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Help feature coming soon')),
                      );
                    },
                  ),
                  _buildListTile(
                    title: 'Privacy Policy',
                    icon: Icons.privacy_tip_outlined,
                    onTap: () {
                      // For now, just show a snackbar since this feature is coming soon
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Privacy policy coming soon')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Logout button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    // Show confirmation dialog
                    bool confirm = await _showLogoutConfirmationDialog(context);
                    if (confirm) {
                      await authProvider.logout();
                      if (mounted) {
                        Navigator.of(context).pushReplacementNamed(RouteNames.login);
                      }
                    }
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 8),
                      Text('LOGOUT', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // App version
              const Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              
              // Extra space for bottom navigation
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
  
  // Profile header with user info
  Widget _buildProfileHeader(BuildContext context, AuthProvider authProvider) {
    final user = authProvider.user;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User avatar
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                user?.initials ?? 'U',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // User name
            Text(
              user?.fullName ?? 'User',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            
            // User email
            Text(
              user?.email ?? 'email@example.com',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            
            // Account created date
            if (user?.createdAt != null)
              Text(
                'Member since: ${DateFormat('MMM yyyy').format(DateTime.parse(user!.createdAt!))}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            
            // Stats
            if (user?.stats != null) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                'Current Month Stats',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    label: 'Income',
                    value: user!.stats!.totalIncomeCurrentMonth ?? 0,
                    isPositive: true,
                  ),
                  _buildStatItem(
                    label: 'Expenses',
                    value: user.stats!.totalExpensesCurrentMonth ?? 0,
                    isPositive: false,
                  ),
                  _buildStatItem(
                    label: 'Balance',
                    value: user.stats!.currentMonthBalance ?? 0,
                    isPositive: user.stats!.currentMonthBalance != null && 
                               user.stats!.currentMonthBalance! >= 0,
                  ),
                ],
              ),
              if (user.stats!.savingsRate != null) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.savings_outlined,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Savings Rate: ${user.stats!.savingsRate!.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem({
    required String label,
    required double value,
    required bool isPositive,
  }) {
    final formatter = NumberFormat.currency(symbol: '\$');
    
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          formatter.format(value),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isPositive ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }
  
  // Section with title and children
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
  
  // List tile with leading icon
  Widget _buildListTile({
    required String title,
    required IconData icon,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
  
  // Logout confirmation dialog
  Future<bool> _showLogoutConfirmationDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    ) ?? false;
  }
  
  // About dialog
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: 'Fin-Arc',
        applicationVersion: '1.0.0',
        applicationIcon: Icon(
          Icons.account_balance_wallet,
          size: 48,
          color: Theme.of(context).primaryColor,
        ),
        applicationLegalese: '© 2025 Fin-Arc. All rights reserved.',
        children: const [
          SizedBox(height: 16),
          Text(
            'Fin-Arc is a personal finance application that helps you track expenses, manage income, and achieve your financial goals.',
          ),
          SizedBox(height: 8),
          Text(
            'Developed by Albert Jidebayev.',
          ),
        ],
      ),
    );
  }
}