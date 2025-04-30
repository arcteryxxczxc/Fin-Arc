import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'dart:math';
import 'package:zxcvbn/zxcvbn.dart';

class ChangePasswordScreen extends StatefulWidget {
  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _zxcvbn = Zxcvbn();
  
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _passwordsMatch = false;
  bool _passwordChanged = false;
  
  // Password strength variables
  int _passwordStrength = 0;
  int _zxcvbnScore = 0;
  bool _hasLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecial = false;
  String _strengthText = '';
  
  // Animation controller for password strength
  late AnimationController _animationController;
  late Animation<double> _strengthAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _strengthAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Listen for changes in confirm password field
    _confirmPasswordController.addListener(_checkPasswordsMatch);
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  // Check if passwords match
  void _checkPasswordsMatch() {
    if (_confirmPasswordController.text.isNotEmpty) {
      setState(() {
        _passwordsMatch = _confirmPasswordController.text == _newPasswordController.text;
      });
    } else {
      setState(() {
        _passwordsMatch = false;
      });
    }
  }
  
  // Check password strength using both custom checks and zxcvbn
  void _checkPasswordStrength(String password) {
    // Check for complexity requirements
    setState(() {
      _hasLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      
      _passwordStrength = 0;
      if (_hasLength) _passwordStrength += 1;
      if (_hasUppercase) _passwordStrength += 1;
      if (_hasLowercase) _passwordStrength += 1;
      if (_hasNumber) _passwordStrength += 1;
      if (_hasSpecial) _passwordStrength += 1;
      
      // Get zxcvbn score
      if (password.isNotEmpty) {
        final result = _zxcvbn.evaluate(password);
        _zxcvbnScore = result.score ?? 0;
        
        // Update strength text
        switch (_zxcvbnScore) {
          case 0:
          case 1:
            _strengthText = 'Very Weak';
            break;
          case 2:
            _strengthText = 'Weak';
            break;
          case 3:
            _strengthText = 'Moderate';
            break;
          case 4:
            _strengthText = 'Strong';
            break;
          default:
            _strengthText = '';
        }
      } else {
        _zxcvbnScore = 0;
        _strengthText = '';
      }
      
      // Combine both scores for the progress indicator
      final combinedScore = _passwordStrength > 0 ? 
          (_passwordStrength / 5 + _zxcvbnScore / 4) / 2 : 0.0;
      
      // Animate to the new strength value
      _strengthAnimation = Tween<double>(
        begin: _strengthAnimation.value,
        end: combinedScore,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        ),
      );
      
      _animationController.forward(from: 0);
    });
    
    // Check if passwords match if confirm password is not empty
    if (_confirmPasswordController.text.isNotEmpty) {
      _checkPasswordsMatch();
    }
  }
  
  // Get color based on password strength
  Color _getStrengthColor(double value) {
    if (value < 0.3) {
      return Colors.red;
    } else if (value < 0.6) {
      return Colors.orange;
    } else if (value < 0.8) {
      return Colors.amber;
    } else {
      return Colors.green;
    }
  }
  
  // Calculate password entropy (approximate)
  double _calculateEntropy(String password) {
    if (password.isEmpty) return 0;
    
    // Calculate character pool size
    int poolSize = 0;
    if (password.contains(RegExp(r'[a-z]'))) poolSize += 26;
    if (password.contains(RegExp(r'[A-Z]'))) poolSize += 26;
    if (password.contains(RegExp(r'[0-9]'))) poolSize += 10;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) poolSize += 32;
    
    // If no character types are detected, assume ASCII (94 characters)
    if (poolSize == 0) poolSize = 94;
    
    // Calculate entropy: log2(poolSize^length)
    return password.length * (log(poolSize) / log(2));
  }
  
  // Submit form
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Get auth provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Change password
      final success = await authProvider.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      
      if (success && mounted) {
        // Show success animation
        setState(() {
          _passwordChanged = true;
        });
        
        // Show success message and navigate back after delay
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password changed successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Delay navigation to show the success animation
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      } else if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Failed to change password'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // If password has been changed successfully, show success animation
    if (_passwordChanged) {
      return _buildSuccessScreen();
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Change Password'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and title
              Center(
                child: Column(
                  children: [
                    Hero(
                      tag: 'lockIcon',
                      child: Icon(
                        Icons.lock_outline,
                        size: 72,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Update Your Password',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Choose a strong password for better security',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
              
              // Current password field
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrentPassword,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  hintText: 'Enter your current password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrentPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureCurrentPassword = !_obscureCurrentPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              
              // New password field
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  hintText: 'Create a strong password',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  if (!value.contains(RegExp(r'[A-Z]'))) {
                    return 'Password must contain an uppercase letter';
                  }
                  if (!value.contains(RegExp(r'[a-z]'))) {
                    return 'Password must contain a lowercase letter';
                  }
                  if (!value.contains(RegExp(r'[0-9]'))) {
                    return 'Password must contain a number';
                  }
                  if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                    return 'Password must contain a special character';
                  }
                  return null;
                },
                onChanged: _checkPasswordStrength,
              ),
              SizedBox(height: 8),
              
              // Password strength indicator
              if (_newPasswordController.text.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Password Strength:',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      _strengthText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getStrengthColor(_strengthAnimation.value),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                AnimatedBuilder(
                  animation: _strengthAnimation,
                  builder: (context, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _strengthAnimation.value,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getStrengthColor(_strengthAnimation.value),
                        ),
                        minHeight: 8,
                      ),
                    );
                  },
                ),
                if (_strengthAnimation.value > 0) ...[
                  SizedBox(height: 4),
                  Text(
                    'Estimated entropy: ${_calculateEntropy(_newPasswordController.text).toStringAsFixed(1)} bits',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ],
              SizedBox(height: 16),
              
              // Password requirements
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Password Requirements:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    _buildRequirement('At least 8 characters', _hasLength),
                    SizedBox(height: 4),
                    _buildRequirement('At least one uppercase letter (A-Z)', _hasUppercase),
                    SizedBox(height: 4),
                    _buildRequirement('At least one lowercase letter (a-z)', _hasLowercase),
                    SizedBox(height: 4),
                    _buildRequirement('At least one number (0-9)', _hasNumber),
                    SizedBox(height: 4),
                    _buildRequirement('At least one special character (!@#$...)', _hasSpecial),
                  ],
                ),
              ),
              SizedBox(height: 24),
              
              // Confirm password field
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  hintText: 'Repeat your new password',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_confirmPasswordController.text.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(
                            _passwordsMatch ? Icons.check_circle : Icons.cancel,
                            color: _passwordsMatch ? Colors.green : Colors.red,
                            size: 20,
                          ),
                        ),
                      IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your new password';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              if (_confirmPasswordController.text.isNotEmpty && !_passwordsMatch)
                Padding(
                  padding: EdgeInsets.only(top: 8, left: 12),
                  child: Text(
                    'Passwords do not match',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),
              SizedBox(height: 32),
              
              // Password suggestions (if new password is weak)
              if (_newPasswordController.text.isNotEmpty && _zxcvbnScore < 3)
                _buildPasswordSuggestions(),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: authProvider.isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('CHANGE PASSWORD', style: TextStyle(fontSize: 16)),
                ),
              ),
              SizedBox(height: 16),
              
              // Security tip
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Security Tips:',
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '• For security reasons, you will be logged out after changing your password.\n'
                            '• Use a unique password for each of your accounts.\n'
                            '• Consider using a password manager for better security.',
                            style: TextStyle(color: Colors.blue[800], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Success screen animation
  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'lockIcon',
              child: Icon(
                Icons.check_circle_outline,
                size: 120,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Password Changed!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your password has been updated successfully',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
  
  // Password suggestion widget
  Widget _buildPasswordSuggestions() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggestions to improve your password:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.amber[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            '• Make it longer (12+ characters is recommended)\n'
            '• Use a mix of characters, not just letters\n'
            '• Don\'t use common words or patterns\n'
            '• Avoid personal information or common substitutions\n'
            '• Consider using a passphrase of random words',
            style: TextStyle(
              fontSize: 12,
              color: Colors.amber[800],
            ),
          ),
        ],
      ),
    );
  }
  
  // Password requirement item with animation
  Widget _buildRequirement(String text, bool isMet) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Row(
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isMet ? Colors.green[50] : Colors.grey[50],
              shape: BoxShape.circle,
              border: Border.all(
                color: isMet ? Colors.green : Colors.grey,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Icon(
                isMet ? Icons.check : Icons.close,
                size: 14,
                color: isMet ? Colors.green : Colors.grey,
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isMet ? Colors.green[800] : Colors.grey[700],
                fontSize: 13,
                fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}