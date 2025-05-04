// lib/screens/settings/currency_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/settings_service.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_display.dart';
import '../../utils/error_handler.dart';

class CurrencySettingsScreen extends StatefulWidget {
  const CurrencySettingsScreen({Key? key}) : super(key: key);

  @override
  _CurrencySettingsScreenState createState() => _CurrencySettingsScreenState();
}

class _CurrencySettingsScreenState extends State<CurrencySettingsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  String _selectedCurrency = 'USD';
  List<Map<String, dynamic>> _availableCurrencies = [];
  final SettingsService _settingsService = SettingsService();

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
  }

  Future<void> _loadCurrencies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load available currencies
      final currenciesResult = await _settingsService.getAvailableCurrencies();
      
      if (!currenciesResult['success']) {
        setState(() {
          _error = currenciesResult['message'] ?? 'Failed to load currencies';
          _isLoading = false;
        });
        return;
      }
      
      _availableCurrencies = List<Map<String, dynamic>>.from(currenciesResult['data'] ?? []);
      
      // Load user's current currency setting
      final settingsResult = await _settingsService.getUserSettings();
      
      if (settingsResult['success'] && settingsResult['data'] != null) {
        final settings = settingsResult['data'];
        _selectedCurrency = settings['default_currency'] ?? 'USD';
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading currency settings: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCurrencySetting(String currency) async {
    if (_selectedCurrency == currency) {
      return; // No change needed
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final result = await _settingsService.updateUserSetting('default_currency', currency);
      
      if (result['success']) {
        setState(() {
          _selectedCurrency = currency;
          _isSaving = false;
        });
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Currency updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _isSaving = false;
        });
        
        // Show error message
        if (mounted) {
          ErrorHandler.showErrorSnackBar(
            context, 
            result['message'] ?? 'Failed to update currency'
          );
        }
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      
      // Show error message
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, 'Error updating currency: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Settings'),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading currencies...')
          : _error != null
              ? ErrorDisplay(
                  error: _error!,
                  onRetry: _loadCurrencies,
                )
              : _buildCurrencyList(),
    );
  }

  Widget _buildCurrencyList() {
    // If the API doesn't return any currencies, use a hardcoded fallback list
    if (_availableCurrencies.isEmpty) {
      _availableCurrencies = [
        {"code": "UZS", "name": "Uzbekistan Sщm", "symbol": "сўм"},
        {"code": "USD", "name": "US Dollar", "symbol": "\$"},
        {"code": "EUR", "name": "Euro", "symbol": "€"},
        {"code": "RUB", "name": "Russian Ruble", "symbol": "₽"},
        {"code": "KZT", "name": "Kazakhstan Tenge", "symbol": "₸"},
        {"code": "GBP", "name": "British Pound", "symbol": "£"},
        {"code": "JPY", "name": "Japanese Yen", "symbol": "¥"},
        {"code": "CNY", "name": "Chinese Yuan", "symbol": "¥"},
        {"code": "KRW", "name": "South Korean Won", "symbol": "₩"},
        {"code": "INR", "name": "Indian Rupee", "symbol": "₹"}
      ];
    }

    return Stack(
      children: [
        // Main content
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Select Default Currency',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'This currency will be used as the default for all transactions and reports.',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _availableCurrencies.length,
                itemBuilder: (context, index) {
                  final currency = _availableCurrencies[index];
                  final code = currency['code'] ?? '';
                  final name = currency['name'] ?? '';
                  final symbol = currency['symbol'] ?? '';
                  final isSelected = _selectedCurrency == code;
                  
                  return RadioListTile<String>(
                    title: Text(
                      name,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text('$code ($symbol)'),
                    value: code,
                    groupValue: _selectedCurrency,
                    activeColor: Theme.of(context).primaryColor,
                    onChanged: _isSaving ? null : (value) {
                      if (value != null) {
                        _saveCurrencySetting(value);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
        
        // Loading overlay
        if (_isSaving)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}