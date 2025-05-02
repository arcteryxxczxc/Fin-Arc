// lib/utils/error_handler.dart
import 'package:flutter/material.dart';

class ErrorHandler {
  // For field validation errors
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
  
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }
  
  static String? validatePassword(String? value, {bool isConfirm = false}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (!isConfirm && value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }
  
  static String? validateNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    return null;
  }
  
  // For API errors
  static String parseApiError(dynamic error) {
    if (error is Map && error.containsKey('message')) {
      return error['message'];
    }
    if (error is String) {
      return error;
    }
    return 'An unexpected error occurred';
  }
  
  // Show error snackbar
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  // Show success snackbar
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  // Show error dialog
  static Future<void> showErrorDialog(BuildContext context, String title, String message) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
  
  // Handle connection errors
  static String handleConnectionError(dynamic error) {
    if (error.toString().contains('SocketException')) {
      return 'No internet connection. Please check your network settings.';
    }
    if (error.toString().contains('TimeoutException')) {
      return 'Request timed out. Please try again later.';
    }
    return 'Connection error: ${error.toString()}';
  }
}