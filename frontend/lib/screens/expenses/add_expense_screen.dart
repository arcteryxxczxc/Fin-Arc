import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';
import '../../models/category.dart';

class AddExpenseScreen extends StatefulWidget {
  @override
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  Category? _selectedCategory;
  String? _selectedPaymentMethod;
  bool _isRecurring = false;
  String? _recurringType;
  
  final List<String> _paymentMethods = [
    'Cash',
    'Credit Card',
    'Debit Card',
    'Bank Transfer',
    'Mobile Payment',
    'Other'
  ];
  
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
    _descriptionController.dispose();
    _locationController.dispose();
    _notesController.dispose();
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
  
  // Show time picker
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }
  
  // Submit form
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Get providers
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      
      // Format date and time
      final date = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final time = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
      
      // Parse amount as double
      final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
      
      // Add expense
      final success = await expenseProvider.addExpense(
        amount: amount,
        date: date,
        description: _descriptionController.text,
        categoryId: _selectedCategory?.id,
        paymentMethod: _selectedPaymentMethod,
        location: _locationController.text,
        time: time,
        isRecurring: _isRecurring,
        recurringType: _isRecurring ? _recurringType?.toLowerCase() : null,
        notes: _notesController.text,
      );
      
      if (success && mounted) {
        // Show success message and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Expense added successfully')),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(expenseProvider.error ?? 'Failed to add expense'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Expense'),
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
              
              // Date and time selectors
              Row(
                children: [
                  Expanded(
                    child: InkWell(
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
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Time',
                          prefixIcon: Icon(Icons.access_time),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ),
                ],
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
                items: categoryProvider.expenseCategories.map((category) {
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
              
              // Payment method dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Payment Method',
                  prefixIcon: Icon(Icons.payment),
                  border: OutlineInputBorder(),
                ),
                value: _selectedPaymentMethod,
                items: _paymentMethods.map((method) {
                  return DropdownMenuItem(
                    value: method,
                    child: Text(method),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedPaymentMethod = newValue;
                  });
                },
              ),
              SizedBox(height: 16),
              
              // Location field
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              
              // Recurring expense toggle
              SwitchListTile(
                title: Text('Recurring Expense'),
                subtitle: Text('Enable for repeating expenses'),
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
              
              // Recurring type dropdown (if recurring is enabled)
              if (_isRecurring)
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
              
              // Notes field
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 24),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: expenseProvider.isLoading ? null : _submitForm,
                  child: expenseProvider.isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Add Expense', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}