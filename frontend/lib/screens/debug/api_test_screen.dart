import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/connectivity_test.dart';
import '../../utils/constants.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  _ApiTestScreenState createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  bool _isLoading = false;
  String _results = 'Press the "Run Tests" button to check API connectivity.';
  Map<String, dynamic>? _rawResults;
  bool _showRawData = false;

  Future<void> _runTests() async {
    setState(() {
      _isLoading = true;
      _results = 'Running tests...';
      _rawResults = null;
    });

    try {
      // Run connectivity tests
      final results = await ConnectivityTest.testApiConnectivity();
      _rawResults = results;
      
      // Generate formatted report
      final report = await ConnectivityTest.generateReport();
      
      if (mounted) {
        setState(() {
          _results = report;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _results = 'Error running tests: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _results));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Results copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Connectivity Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyToClipboard,
            tooltip: 'Copy results to clipboard',
          ),
          IconButton(
            icon: Icon(_showRawData ? Icons.view_headline : Icons.data_array),
            onPressed: () {
              setState(() {
                _showRawData = !_showRawData;
              });
            },
            tooltip: _showRawData ? 'Show formatted report' : 'Show raw data',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // API Information card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'API Configuration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Base URL: ${AppConstants.baseUrl}'),
                    const SizedBox(height: 4),
                    Text('App Version: ${AppConstants.appVersion}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Run test button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _runTests,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Run API Connectivity Tests'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Results section
            const Text(
              'Test Results:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Results display
            Expanded(
              child: Card(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: _showRawData && _rawResults != null
                      ? Text(_rawResults.toString())
                      : SelectableText(
                          _results,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                ),
              ),
            ),
            
            // Help text
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'This tool helps diagnose connectivity issues between the Flutter frontend and the Flask backend API. '
                'It tests API health, CORS configuration, and authentication endpoints.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}