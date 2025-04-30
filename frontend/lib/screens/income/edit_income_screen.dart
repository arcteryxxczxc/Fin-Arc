import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/category_provider.dart';
import '../../providers/income_provider.dart';
import '../../models/category.dart';
import '../../models/income.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_display.dart';

class EditIncomeScreen extends StatefulWidget {
  final int incomeId;
  
  const EditIncomeScreen({Key? key, required this.incomeId}) : super(key: key);

  @override
  _EditIncomeScreenState createState() => _EditIncomeScreenState();
}

class _EditIncomeScreenState extends State<EditIncomeScreen> {
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
  
  bool _isLoading = true;
  String? _error;
  Income? _income;
  
  final List<String> _recurringTypes = [
    'Daily',
    'Weekly',
    'Monthly',
    'Yearly'
  ];
  
  @override
  void initState() {
    super.initState();
    
    // Load income data and categories
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadIncomeData();
      
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      if (categoryProvider.categories.isEmpty) {
        await categoryProvider.fetchCategories();
      }
      
      // Find the category if it exists
      if (_income?.categoryId != null && categoryProvider.categories.isNotEmpty) {
        setState(() {
          _selectedCategory = categoryProvider.categories.firstWhere(
            (cat) => cat.id == _income!.categoryId,
            orElse: () => null,
          );
        });
      }
    });
  }
  
  Future<void> _loadIncomeData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final incomeProvider = Provider.of<IncomeProvider>(context, listen: false);
      final result = await incomeProvider.getIncomeDetails(widget.incomeId);
      
      if (result['success']) {
        final income = Income.fromJson(result['data']['income']);
        
        // Set form values
        _amountController.text = income.amount.toString();
        _sourceController.text = income.source;
        if (income.description != null) {
          _descriptionController.text = income.description!;
        }
        
        // Parse date
        _selectedDate = DateTime.parse(income.date);
        
        // Set other fields
        _isRecurring = income.isRecurring;
        _recurringType = income.recurringType;
        if (income.recurringDay != null) {
          _recurringDay = income.recurringDay!;
        }
        _isTaxable = income.isTaxable;
        if (income.taxRate != null) {
          _taxRateController.text = income.taxRate!.toString();
        }
        
        if (mounted) {
          setState(() {
            _income = income;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to load income data: ${result['message']}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading income data: $e';
          _isLoading = false;
        });
      }
    }
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
      lastDate: DateTime.now().add(Duration(days: 365)),
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
      
      // Update income
      final success = await incomeProvider.updateIncome(
        incomeId: widget.incomeId,
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
          SnackBar(content: Text('Income updated successfully')),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(incomeProvider.error ?? 'Failed to update income'),
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
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Edit Income'),
        ),
        body: LoadingIndicator(message: 'Loading income data...'),
      );
    }
    
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Edit Income'),
        ),
        body: ErrorDisplay(
          error: _error!,
          onRetry: _loadIncomeData,
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Income'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount field
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
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
              SizedBox(height: 16),
              
              // Source field
              TextFormField(
                controller: _sourceController,
                decoration: InputDecoration(
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
              SizedBox(height: 16),
              
              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              
              // Date selector
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    DateFormat('yyyy-MM-dd').format(_selectedDate),
                  ),
                ),
              ),
              SizedBox(height: 16),
              
              // Category dropdown
              DropdownButtonFormField<Category>(
                decoration: InputDecoration(
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
                        SizedBox(width: 10),
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
              SizedBox(height: 16),
              
              // Recurring income toggle
              SwitchListTile(
                title: Text('Recurring Income'),
                subtitle: Text('Enable for repeating income'),
                value: _isRecurring,
                onChanged: (bool value) {
                  setState(() {
                    _isRecurring = value;
                    if (!value) {
                      _recurringType = null;
                    } else if (_recurringType == null) {
                      _recurringType = _recurringTypes.first;
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
                      padding: EdgeInsets.only(top: 8),
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
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
                    SizedBox(height: 16),
                    
                    // Recurring day field (for monthly and yearly)
                    if (_recurringType == 'Monthly' || _recurringType == 'Yearly')
                      TextFormField(
                        initialValue: _recurringDay.toString(),
                        decoration: InputDecoration(
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
              SizedBox(height: 16),
              
              // Taxable income toggle
              SwitchListTile(
                title: Text('Taxable Income'),
                subtitle: Text('Enable if income is subject to tax'),
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
                  padding: EdgeInsets.only(top: 8),
                  child: TextFormField(
                    controller: _taxRateController,
                    decoration: InputDecoration(
                      labelText: 'Tax Rate (%)',
                      prefixIcon: Icon(Icons.percent),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
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
              SizedBox(height: 24),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: incomeProvider.isLoading ? null : _submitForm,
                  child: incomeProvider.isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Update Income', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}