// lib/widgets/common/error_display.dart
import 'package:flutter/material.dart';

class ErrorDisplay extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;
  
  const ErrorDisplay({
    Key? key, 
    required this.error,
    this.onRetry,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            if (onRetry != null) ...[
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: Icon(Icons.refresh),
                label: Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}