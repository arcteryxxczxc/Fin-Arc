// lib/screens/profile/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../utils/error_handler.dart';
import '../../widgets/common/loading_indicator.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _isLoading = false;
  String? _error;
  late User _user;
  
  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }
  
  void _initializeUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _user = authProvider.user!;
    
    // Initialize form fields
    _firstNameController.text = _user.firstName ?? '';
    _lastNameController.text = _user.lastName ?? '';
    _emailController.text = _user.email;
  }
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
  
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // This is a placeholder - in a real app, you'd call the API to update the profile
      // For now, we'll just show a success message and return to the profile screen
      
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        
        // Return to profile screen
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to update profile: $e';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Updating profile...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile picture
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: theme.primaryColor,
                            child: Text(
                              _user.initials,
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Change photo'),
                            onPressed: () {
                              // Show coming soon dialog
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('This feature is coming soon!')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Error message if any
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Form fields
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your first name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your last name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      enabled: false, // Email cannot be changed
                    ),
                    const SizedBox(height: 24),
                    
                    // Currency preference (placeholder for now)
                    const Text(
                      'Preferences',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.attach_money),
                        title: const Text('Default Currency'),
                        subtitle: const Text('USD'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Show coming soon dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Currency selection coming soon!')),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.language),
                        title: const Text('Language'),
                        subtitle: const Text('English'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Show coming soon dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Language selection coming soon!')),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _updateProfile,
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}