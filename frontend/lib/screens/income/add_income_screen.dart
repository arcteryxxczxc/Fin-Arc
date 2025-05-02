import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/category_provider.dart';
import '../../providers/income_provider.dart';
import '../../models/category.dart';

class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  _AddIncomeScreenState createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _sourceController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;
  bool _isRecurring = false;
  String? _recurringType;
  int _recurringDay = 1;
  bool _isTaxable = false;
  final _taxRateController = TextEditingController(text: '0');
  
  final List<String> _recurringTypes = [
    'Daily',
    'Weekly',
    'Monthly',
    'Yearly'
  ];
  
  @override
  void initState() {
    super.initState();
    // Load categories if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      if (categoryProvider.categories.isEmpty) {
        categoryProvider.fetchCategories();
      }
    });
  }
  
  @override
  void dispose() {
    _amountController.dispose();
    _sourceController.dispose();
    _descriptionController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }
  
  // Show date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  // Submit form
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Get providers
      final incomeProvider = Provider.of<IncomeProvider>(context, listen: false);
      
      // Format date
      final date = DateFormat('yyyy-MM-dd').format(_selectedDate);
      
      // Parse amount as double
      final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
      
      // Parse tax rate if taxable
      double? taxRate;
      if (_isTaxable) {
        taxRate = double.tryParse(_taxRateController.text.replaceAll(',', '.')) ?? 0.0;
      }
      
      // Add income
      final success = await incomeProvider.addIncome(
        amount: amount,
        source: _sourceController.text,
        date: date,
        description: _descriptionController.text,
        categoryId: _selectedCategory?.id,
        isRecurring: _isRecurring,
        recurringType: _isRecurring ? _recurringType?.toLowerCase() : null,
        recurringDay: _isRecurring ? _recurringDay : null,
        isTaxable: _isTaxable,
        taxRate: taxRate,
      );
      
      if (success && mounted) {
        // Show success message and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Income added successfully')),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(incomeProvider.error ?? 'Failed to add income'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final incomeProvider = Provider.of<IncomeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Income'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount field
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value.replaceAll(',', '.')) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Source field
              TextFormField(
                controller: _sourceController,
                decoration: const InputDecoration(
                  labelText: 'Source',
                  prefixIcon: Icon(Icons.account_balance),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an income source';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Date selector
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    DateFormat('yyyy-MM-dd').format(_selectedDate),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Category dropdown
              DropdownButtonFormField<Category>(
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                value: _selectedCategory,
                items: categoryProvider.incomeCategories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Color(int.parse(category.colorCode.substring(1, 7), radix: 16) + 0xFF000000),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(category.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (Category? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Recurring income toggle
              SwitchListTile(
                title: const Text('Recurring Income'),
                subtitle: const Text('Enable for repeating income'),
                value: _isRecurring,
                onChanged: (bool value) {
                  setState(() {
                    _isRecurring = value;
                    if (!value) {
                      _recurringType = null;
                    } else {
                      _recurringType ??= _recurringTypes.first;
                    }
                  });
                },
              ),
              
              // Recurring options (if recurring is enabled)
              if (_isRecurring)
                Column(
                  children: [
                    // Recurring type dropdown
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Recurrence Type',
                          prefixIcon: Icon(Icons.repeat),
                          border: OutlineInputBorder(),
                        ),
                        value: _recurringType ?? _recurringTypes.first,
                        items: _recurringTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _recurringType = newValue;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Recurring day field (for monthly and yearly)
                    if (_recurringType == 'Monthly' || _recurringType == 'Yearly')
                      TextFormField(
                        initialValue: _recurringDay.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Day of Month',
                          prefixIcon: Icon(Icons.date_range),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a day';
                          }
                          int? day = int.tryParse(value);
                          if (day == null || day < 1 || day > 31) {
                            return 'Day must be between 1 and 31';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          int? day = int.tryParse(value);
                          if (day != null && day >= 1 && day <= 31) {
                            setState(() {
                              _recurringDay = day;
                            });
                          }
                        },
                      ),
                  ],
                ),
              const SizedBox(height: 16),
              
              // Taxable income toggle
              SwitchListTile(
                title: const Text('Taxable Income'),
                subtitle: const Text('Enable if income is subject to tax'),
                value: _isTaxable,
                onChanged: (bool value) {
                  setState(() {
                    _isTaxable = value;
                  });
                },
              ),
              
              // Tax rate field (if taxable is enabled)
              if (_isTaxable)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextFormField(
                    controller: _taxRateController,
                    decoration: const InputDecoration(
                      labelText: 'Tax Rate (%)',
                      prefixIcon: Icon(Icons.percent),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a tax rate';
                      }
                      double? rate = double.tryParse(value.replaceAll(',', '.'));
                      if (rate == null || rate < 0 || rate > 100) {
                        return 'Rate must be between 0 and 100';
                      }
                      return null;
                    },
                  ),
                ),
              const SizedBox(height: 24),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: incomeProvider.isLoading ? null : _submitForm,
                  child: incomeProvider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Add Income', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}