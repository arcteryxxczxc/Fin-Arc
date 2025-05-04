// lib/screens/help/help_support_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/constants.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App info card
              _buildInfoCard(context),
              const SizedBox(height: 24),
              
              // FAQ section
              Text(
                'Frequently Asked Questions',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              _buildFaqItem(
                context,
                question: 'How do I add a new expense?',
                answer: 'To add a new expense, go to the Expenses tab and tap the + button at the bottom of the screen. Fill in the details of your expense and tap Save.',
              ),
              _buildFaqItem(
                context,
                question: 'How do I create or edit categories?',
                answer: 'Go to the Categories tab where you can view all your existing categories. Tap the + button to create a new category, or tap on an existing category to edit it.',
              ),
              _buildFaqItem(
                context,
                question: 'How do I generate reports?',
                answer: 'Navigate to the Reports section and select the type of report you want to generate. You can choose from monthly, annual, cashflow, and budget reports.',
              ),
              _buildFaqItem(
                context,
                question: 'Can I export my data?',
                answer: 'Yes! In the Reports section, select "Export Data" and choose the type of data you want to export and the date range.',
              ),
              _buildFaqItem(
                context,
                question: 'How do I set up budget limits?',
                answer: 'Go to the Categories section, select a category, and tap on "Set Budget" to define a budget limit for that category.',
              ),
              const SizedBox(height: 24),
              
              // Contact Support
              Text(
                'Contact Support',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              _buildContactCard(
                context,
                title: 'Email Support',
                subtitle: 'support@fin-arc.com',
                icon: Icons.email,
                onTap: () => _launchEmail('support@fin-arc.com'),
              ),
              const SizedBox(height: 12),
              _buildContactCard(
                context,
                title: 'Phone Support',
                subtitle: '+1 (555) 123-4567',
                icon: Icons.phone,
                onTap: () => _launchPhone('+15551234567'),
              ),
              const SizedBox(height: 12),
              _buildContactCard(
                context,
                title: 'Live Chat',
                subtitle: 'Chat with our support team',
                icon: Icons.chat,
                onTap: () => _showLiveChatNotAvailableDialog(context),
              ),
              const SizedBox(height: 24),
              
              // Resources
              Text(
                'Resources',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              _buildResourceCard(
                context,
                title: 'User Guide',
                subtitle: 'Detailed instructions on using Fin-Arc',
                icon: Icons.book,
                onTap: () => _showComingSoonDialog(context, 'User Guide'),
              ),
              const SizedBox(height: 12),
              _buildResourceCard(
                context,
                title: 'Video Tutorials',
                subtitle: 'Learn Fin-Arc through video lessons',
                icon: Icons.video_library,
                onTap: () => _showComingSoonDialog(context, 'Video Tutorials'),
              ),
              const SizedBox(height: 12),
              _buildResourceCard(
                context,
                title: 'Finance Tips',
                subtitle: 'Articles and advice on personal finance',
                icon: Icons.lightbulb,
                onTap: () => _showComingSoonDialog(context, 'Finance Tips'),
              ),
              
              // Bottom padding
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.account_balance_wallet,
                size: 32,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fin-Arc',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version ${AppConstants.appVersion}',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Personal Finance Management App',
                    style: TextStyle(
                      color: Colors.grey[800],
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

  Widget _buildFaqItem(
    BuildContext context, {
    required String question,
    required String answer,
  }) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: TextStyle(
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildResourceCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            icon,
            color: Colors.amber[800],
          ),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _launchEmail(String email) async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Fin-Arc Support Request',
        'body': 'Hello Support Team,\n\n',
      },
    );
    
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        print('Could not launch $emailUri');
      }
    } catch (e) {
      print('Error launching email: $e');
    }
  }

  void _launchPhone(String phoneNumber) async {
    final phoneUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        print('Could not launch $phoneUri');
      }
    } catch (e) {
      print('Error launching phone: $e');
    }
  }

  void _showLiveChatNotAvailableDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Live Chat'),
        content: const Text(
          'Live chat support is currently unavailable. Please try again during business hours (9 AM - 5 PM ET, Monday-Friday).',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$feature Coming Soon'),
        content: Text(
          'The $feature feature is coming soon! We\'re working hard to make it available in the next update.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}