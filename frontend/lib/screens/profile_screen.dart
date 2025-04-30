import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'auth/change_password_screen.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile header
          _buildProfileHeader(context, authProvider),
          SizedBox(height: 24),
          
          // Account settings
          _buildSection(
            title: 'Account Settings',
            icon: Icons.person_outline,
            children: [
              _buildListTile(
                title: 'Edit Profile',
                icon: Icons.edit,
                onTap: () {
                  // Navigate to edit profile screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Edit profile feature coming soon')),
                  );
                },
              ),
              _buildListTile(
                title: 'Change Password',
                icon: Icons.lock_outline,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChangePasswordScreen(),
                    ),
                  );
                },
              ),
              _buildListTile(
                title: 'Login History',
                icon: Icons.history,
                onTap: () {
                  // Navigate to login history screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Login history feature coming soon')),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // App settings
          _buildSection(
            title: 'App Settings',
            icon: Icons.settings_outlined,
            children: [
              SwitchListTile(
                title: Text('Dark Mode'),
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
                  // Navigate to currency settings
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Currency settings coming soon')),
                  );
                },
              ),
              _buildListTile(
                title: 'Notifications',
                icon: Icons.notifications_none,
                subtitle: 'Enabled',
                onTap: () {
                  // Navigate to notification settings
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Notification settings coming soon')),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 16),
          
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
                  // Show help information
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Help feature coming soon')),
                  );
                },
              ),
              _buildListTile(
                title: 'Privacy Policy',
                icon: Icons.privacy_tip_outlined,
                onTap: () {
                  // Show privacy policy
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Privacy policy coming soon')),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 24),
          
          // Logout button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () async {
                // Show confirmation dialog
                bool confirm = await _showLogoutConfirmationDialog(context);
                if (confirm) {
                  await authProvider.logout();
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout),
                  SizedBox(width: 8),
                  Text('LOGOUT', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          
          // App version
          Text(
            'Version 1.0.0',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 16),
        ],
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
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // User avatar
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                user?.initials ?? 'U',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // User name
            Text(
              user?.fullName ?? 'User',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            
            // User email
            Text(
              user?.email ?? 'email@example.com',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            
            // Account created date
            if (user?.createdAt != null)
              Text(
                'Member since: ${DateFormat('MMM yyyy').format(DateTime.parse(user!.createdAt!))}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
      ),
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
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
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
      trailing: Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
  
  // Logout confirmation dialog
  Future<bool> _showLogoutConfirmationDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Logout'),
        content: Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('LOGOUT'),
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
        children: [
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