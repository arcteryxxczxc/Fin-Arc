// lib/screens/profile/login_history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_display.dart';

class LoginHistoryScreen extends StatefulWidget {
  const LoginHistoryScreen({Key? key}) : super(key: key);

  @override
  _LoginHistoryScreenState createState() => _LoginHistoryScreenState();
}

class _LoginHistoryScreenState extends State<LoginHistoryScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _loginHistory = [];
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _fetchLoginHistory();
  }

  Future<void> _fetchLoginHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch login history from API
      final result = await _authService.getLoginHistory();
      
      if (result['success']) {
        setState(() {
          _loginHistory = List<Map<String, dynamic>>.from(result['data'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to load login history';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error fetching login history: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login History'),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading login history...')
          : _error != null
              ? ErrorDisplay(
                  error: _error!,
                  onRetry: _fetchLoginHistory,
                )
              : _buildLoginHistory(),
    );
  }

  Widget _buildLoginHistory() {
    // If no login history, show empty state
    if (_loginHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No login history available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your login activity will appear here',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Show login history
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Recent Login Activity',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: _loginHistory.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final entry = _loginHistory[index];
              final DateTime timestamp = DateTime.parse(entry['timestamp'] ?? '2023-01-01T00:00:00');
              final bool success = entry['success'] ?? false;
              final String ipAddress = entry['ip_address'] ?? 'Unknown';
              final String userAgent = entry['user_agent'] ?? 'Unknown device';
              
              // Extract device info from user agent (simplified)
              String deviceInfo = 'Unknown device';
              if (userAgent.contains('iPhone') || userAgent.contains('iPad')) {
                deviceInfo = 'iOS device';
              } else if (userAgent.contains('Android')) {
                deviceInfo = 'Android device';
              } else if (userAgent.contains('Windows')) {
                deviceInfo = 'Windows device';
              } else if (userAgent.contains('Mac')) {
                deviceInfo = 'Mac device';
              }

              return ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: success ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    success ? Icons.check_circle : Icons.error,
                    color: success ? Colors.green : Colors.red,
                  ),
                ),
                title: Text(
                  DateFormat('MMM d, yyyy - h:mm a').format(timestamp),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(deviceInfo),
                    Text('IP: $ipAddress'),
                  ],
                ),
                trailing: Icon(
                  Icons.info_outline,
                  color: Colors.grey[600],
                ),
                onTap: () {
                  // Show more details in a dialog
                  _showLoginDetailsDialog(entry);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showLoginDetailsDialog(Map<String, dynamic> entry) {
    final DateTime timestamp = DateTime.parse(entry['timestamp'] ?? '2023-01-01T00:00:00');
    final bool success = entry['success'] ?? false;
    final String ipAddress = entry['ip_address'] ?? 'Unknown';
    final String userAgent = entry['user_agent'] ?? 'Unknown device';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Status', success ? 'Successful' : 'Failed'),
            const SizedBox(height: 8),
            _buildDetailRow('Time', DateFormat('MMM d, yyyy - h:mm a').format(timestamp)),
            const SizedBox(height: 8),
            _buildDetailRow('IP Address', ipAddress),
            const SizedBox(height: 8),
            _buildDetailRow('User Agent', userAgent, maxLines: 3),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
          ),
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}