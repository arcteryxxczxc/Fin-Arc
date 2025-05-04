// lib/screens/help/privacy_policy_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last Updated: May 05, 2023',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Fin-Arc ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how your personal information is collected, used, and disclosed by Fin-Arc.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            
            _buildSectionTitle(context, 'Information We Collect'),
            _buildParagraph(
              'We collect information you provide directly to us when you:',
            ),
            _buildBulletList([
              'Create or modify your account',
              'Log in to the application',
              'Enter financial information such as expenses, income, and budget categories',
              'Upload supporting documents',
              'Contact us for support or information',
            ]),
            _buildParagraph(
              'The types of information we collect include:',
            ),
            _buildBulletList([
              'Personal identifiers (name, email address)',
              'Authentication information (username, password)',
              'Financial information (expenses, income, budgets)',
              'Device information and usage data',
            ]),
            
            _buildSectionTitle(context, 'How We Use Your Information'),
            _buildParagraph(
              'We use your information for the following purposes:',
            ),
            _buildBulletList([
              'Provide, maintain, and improve our services',
              'Process and display your financial data',
              'Send you technical notices, updates, and support messages',
              'Respond to your comments, questions, and requests',
              'Monitor usage patterns and analyze trends',
              'Protect against, identify, and prevent fraud and other illegal activity',
            ]),
            
            _buildSectionTitle(context, 'Data Security'),
            _buildParagraph(
              'We implement appropriate security measures to protect your personal information:',
            ),
            _buildBulletList([
              'All financial data is encrypted during transmission and storage',
              'Password requirements include complexity and minimum length',
              'Authentication uses secure token-based methods',
              'Regular security audits and updates',
            ]),
            _buildParagraph(
              'While we strive to protect your information, no method of transmission over the internet or electronic storage is 100% secure. We cannot guarantee absolute security.',
            ),
            
            _buildSectionTitle(context, 'Your Rights and Choices'),
            _buildParagraph(
              'You have certain rights regarding your personal information:',
            ),
            _buildBulletList([
              'Access and update your information through your account settings',
              'Request deletion of your account and associated data',
              'Opt out of marketing communications',
              'Export your financial data in standard formats',
            ]),
            
            _buildSectionTitle(context, 'Third-Party Services'),
            _buildParagraph(
              'Fin-Arc may use third-party services that collect information about you:',
            ),
            _buildBulletList([
              'Currency conversion and exchange rate providers',
              'Cloud storage and database services',
              'Analytics providers',
            ]),
            _buildParagraph(
              'These third parties have their own privacy policies addressing how they use such information.',
            ),
            
            _buildSectionTitle(context, 'Children\'s Privacy'),
            _buildParagraph(
              'Fin-Arc is not directed to children under 16. We do not knowingly collect personal information from children under 16. If you believe we have collected information from a child under 16, please contact us.',
            ),
            
            _buildSectionTitle(context, 'Changes to This Privacy Policy'),
            _buildParagraph(
              'We may update this privacy policy from time to time. We will notify you of any changes by posting the new privacy policy on this page and updating the "Last Updated" date.',
            ),
            
            _buildSectionTitle(context, 'Contact Us'),
            _buildParagraph(
              'If you have any questions about this Privacy Policy, please contact us at:',
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _launchEmail('privacy@fin-arc.com'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.email, size: 18, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'privacy@fin-arc.com',
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom padding
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildBulletList(List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) => _buildBulletItem(item)).toList(),
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _launchEmail(String email) async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Privacy Policy Inquiry',
        'body': 'Hello Privacy Team,\n\n',
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
}