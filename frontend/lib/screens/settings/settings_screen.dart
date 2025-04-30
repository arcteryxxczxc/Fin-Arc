import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/common/drawer.dart';
import '../routes/route_names.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedCurrency = 'USD';
  String _selectedLanguage = 'English';
  bool _notificationsEnabled = true;
  final Map<String, bool> _notificationTypes = {
    'Budget alerts': true,
    'Payment reminders': true,
    'Monthly reports': true,
    'Tips & suggestions': false,
  };
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      drawer: AppDrawer(currentRoute: RouteNames.settings),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appearance section
            _buildSectionHeader('Appearance', Icons.palette),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text('Dark Mode'),
                    subtitle: Text('Use dark color scheme'),
                    secondary: Icon(
                      themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: theme.primaryColor,
                    ),
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme();
                    },
                  ),
                  _buildDivider(),
                  ListTile(
                    leading: Icon(Icons.language, color: theme.primaryColor),
                    title: Text('Language'),
                    subtitle: Text(_selectedLanguage),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _showLanguageSelector,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            
            // Preferences section
            _buildSectionHeader('Preferences', Icons.settings),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.attach_money, color: theme.primaryColor),
                    title: Text('Currency'),
                    subtitle: Text(_selectedCurrency),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _showCurrencySelector,
                  ),
                  _buildDivider(),
                  ListTile(
                    leading: Icon(Icons.calendar_today, color: theme.primaryColor),
                    title: Text('First Day of Month'),
                    subtitle: Text('Set when your budget month starts'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Show date selection dialog
                      _showNumberPicker('First Day of Month', 1, 28, 1);
                    },
                  ),
                  _buildDivider(),
                  ListTile(
                    leading: Icon(Icons.home, color: theme.primaryColor),
                    title: Text('Default View'),
                    subtitle: Text('Dashboard'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Show default view selection dialog
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            
            // Notifications section
            _buildSectionHeader('Notifications', Icons.notifications),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text('Enable Notifications'),
                    subtitle: Text('Receive alerts and reminders'),
                    secondary: Icon(
                      _notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
                      color: theme.primaryColor,
                    ),
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                    },
                  ),
                  if (_notificationsEnabled) ...[
                    _buildDivider(),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notification Types',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          ..._notificationTypes.entries.map((entry) {
                            return CheckboxListTile(
                              title: Text(entry.key),
                              value: entry.value,
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (bool? value) {
                                setState(() {
                                  _notificationTypes[entry.key] = value ?? false;
                                });
                              },
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 24),
            
            // Data management section
            _buildSectionHeader('Data Management', Icons.storage),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.file_download, color: theme.primaryColor),
                    title: Text('Export Data'),
                    subtitle: Text('Download your financial data'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Show export options dialog
                    },
                  ),
                  _buildDivider(),
                  ListTile(
                    leading: Icon(Icons.file_upload, color: theme.primaryColor),
                    title: Text('Import Data'),
                    subtitle: Text('Import from CSV or Excel file'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Show import options dialog
                    },
                  ),
                  _buildDivider(),
                  ListTile(
                    leading: Icon(Icons.delete_outline, color: Colors.red),
                    title: Text('Clear All Data'),
                    subtitle: Text('Remove all your financial data'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _showClearDataConfirmation,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            
            // About section
            _buildSectionHeader('About', Icons.info_outline),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.help_outline, color: theme.primaryColor),
                    title: Text('Help & Support'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Show help & support dialog
                    },
                  ),
                  _buildDivider(),
                  ListTile(
                    leading: Icon(Icons.description_outlined, color: theme.primaryColor),
                    title: Text('Privacy Policy'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Show privacy policy
                    },
                  ),
                  _buildDivider(),
                  ListTile(
                    leading: Icon(Icons.info_outline, color: theme.primaryColor),
                    title: Text('About Fin-Arc'),
                    subtitle: Text('Version 1.0.0'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _showAboutDialog,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDivider() {
    return Divider(height: 1, indent: 16, endIndent: 16);
  }
  
  void _showLanguageSelector() {
    final languages = ['English', 'Spanish', 'French', 'German', 'Russian'];
    
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Select Language'),
        children: languages.map((language) {
          return SimpleDialogOption(
            onPressed: () {
              setState(() {
                _selectedLanguage = language;
              });
              Navigator.of(ctx).pop();
            },
            child: Text(language),
          );
        }).toList(),
      ),
    );
  }
  
  void _showCurrencySelector() {
    final currencies = ['USD', 'EUR', 'GBP', 'JPY', 'CNY', 'RUB'];
    
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Select Currency'),
        children: currencies.map((currency) {
          return SimpleDialogOption(
            onPressed: () {
              setState(() {
                _selectedCurrency = currency;
              });
              Navigator.of(ctx).pop();
            },
            child: Text(currency),
          );
        }).toList(),
      ),
    );
  }
  
  void _showNumberPicker(String title, int min, int max, int current) {
    int selectedValue = current;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Select a number between $min and $max:'),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: selectedValue > min ? () {
                        setState(() {
                          selectedValue--;
                        });
                      } : null,
                    ),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          selectedValue.toString(),
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: selectedValue < max ? () {
                        setState(() {
                          selectedValue++;
                        });
                      } : null,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop(selectedValue);
            },
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }
  
  void _showClearDataConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Clear All Data'),
        content: Text(
          'This will permanently delete all your financial data. This action cannot be undone.\n\nAre you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              // Implement clear data functionality
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('All data has been cleared')),
              );
            },
            child: Text('Delete All Data'),
          ),
        ],
      ),
    );
  }
  
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AboutDialog(
        applicationName: 'Fin-Arc',
        applicationVersion: '1.0.0',
        applicationIcon: Icon(
          Icons.account_balance_wallet,
          size: 48,
          color: Theme.of(context).primaryColor,
        ),
        applicationLegalese: '© 2023 Fin-Arc. All rights reserved.',
        children: [
          SizedBox(height: 16),
          Text(
            'Fin-Arc is a personal finance application that helps you track expenses, manage income, and achieve your financial goals.',
          ),
          SizedBox(height: 8),
          Text(
            'Developed with Flutter.',
          ),
        ],
      ),
    );
  }
}