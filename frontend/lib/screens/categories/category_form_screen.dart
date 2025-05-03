// lib/screens/categories/category_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';
import '../../models/category.dart';

class CategoryFormScreen extends StatefulWidget {
  final Category? category;
  final bool isExpense;
  
  const CategoryFormScreen({
    super.key,
    this.category,
    this.isExpense = true,
  });

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetLimitController = TextEditingController();
  
  String _colorHex = '#4285F4'; // Default color
  int _budgetStartDay = 1;
  bool _isActive = true;
  bool _isIncome = false;
  bool _hasBudget = false;
  
  final List<Map<String, dynamic>> _colorOptions = [
    {'name': 'Blue', 'hex': '#4285F4'},
    {'name': 'Red', 'hex': '#EA4335'},
    {'name': 'Green', 'hex': '#34A853'},
    {'name': 'Yellow', 'hex': '#FBBC05'},
    {'name': 'Purple', 'hex': '#9C27B0'},
    {'name': 'Teal', 'hex': '#009688'},
    {'name': 'Pink', 'hex': '#E91E63'},
    {'name': 'Orange', 'hex': '#FF9800'},
    {'name': 'Brown', 'hex': '#795548'},
    {'name': 'Grey', 'hex': '#607D8B'},
  ];
  
  @override
  void initState() {
    super.initState();
    
    // Set isIncome based on constructor parameter
    _isIncome = !widget.isExpense;
    
    // If editing an existing category, initialize form fields
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      if (widget.category!.description != null) {
        _descriptionController.text = widget.category!.description!;
      }
      _colorHex = widget.category!.colorCode;
      _isActive = widget.category!.isActive;
      _isIncome = widget.category!.isIncome;
      
      if (widget.category!.budgetLimit != null && widget.category!.budgetLimit! > 0) {
        _hasBudget = true;
        _budgetLimitController.text = widget.category!.budgetLimit!.toString();
        _budgetStartDay = widget.category!.budgetStartDay;
      }
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _budgetLimitController.dispose();
    super.dispose();
  }
  
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      
      // Prepare category data
      double? budgetLimit;
      if (_hasBudget && _budgetLimitController.text.isNotEmpty) {
        budgetLimit = double.tryParse(_budgetLimitController.text);
      }
      
      bool success;
      
      if (widget.category == null) {
        // Add new category
        success = await categoryProvider.addCategory(
          name: _nameController.text,
          description: _descriptionController.text,
          colorCode: _colorHex,
          budgetLimit: budgetLimit,
          budgetStartDay: _budgetStartDay,
          isIncome: _isIncome,
        );
      } else {
        // Update existing category
        success = await categoryProvider.updateCategory(
          categoryId: widget.category!.id,
          name: _nameController.text,
          description: _descriptionController.text,
          colorCode: _colorHex,
          budgetLimit: budgetLimit,
          budgetStartDay: _budgetStartDay,
          isIncome: _isIncome,
          isActive: _isActive,
        );
      }
      
      if (success && mounted) {
        // Show success message and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
            widget.category == null 
              ? 'Category added successfully'
              : 'Category updated successfully'
          )),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(categoryProvider.error ?? 'Failed to save category'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category == null ? 'Add Category' : 'Edit Category'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a category name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Category type selector
              Card(
                elevation: 0,
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.dividerColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Category Type',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            label: Text('Expense'),
                            icon: Icon(Icons.arrow_downward),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text('Income'),
                            icon: Icon(Icons.arrow_upward),
                          ),
                        ],
                        selected: {_isIncome},
                        onSelectionChanged: (Set<bool> selected) {
                          setState(() {
                            _isIncome = selected.first;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Color selector
              Card(
                elevation: 0,
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.dividerColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Category Color',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _colorOptions.map((colorOption) {
                          final isSelected = _colorHex == colorOption['hex'];
                          final color = Color(int.parse(colorOption['hex'].substring(1, 7), radix: 16) + 0xFF000000);
                          
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _colorHex = colorOption['hex'];
                              });
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected
                                  ? Border.all(color: Colors.white, width: 2)
                                  : null,
                                boxShadow: isSelected
                                  ? [BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )]
                                  : null,
                              ),
                              child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                  )
                                : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Budget section (only for expense categories)
              if (!_isIncome) ...[
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.dividerColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Budget',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Switch(
                              value: _hasBudget,
                              onChanged: (value) {
                                setState(() {
                                  _hasBudget = value;
                                });
                              },
                            ),
                          ],
                        ),
                        if (_hasBudget) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _budgetLimitController,
                            decoration: const InputDecoration(
                              labelText: 'Budget Amount',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.attach_money),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (_hasBudget && (value == null || value.isEmpty)) {
                                return 'Please enter a budget amount';
                              }
                              if (_hasBudget && double.tryParse(value!) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text('Budget Start Day'),
                          const SizedBox(height: 8),
                          Slider(
                            value: _budgetStartDay.toDouble(),
                            min: 1,
                            max: 28,
                            divisions: 27,
                            label: _budgetStartDay.toString(),
                            onChanged: (value) {
                              setState(() {
                                _budgetStartDay = value.round();
                              });
                            },
                          ),
                          Text(
                            'Day $_budgetStartDay of each month',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Active toggle (only for editing)
              if (widget.category != null) ...[
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.dividerColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Category Status',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Text(_isActive ? 'Active' : 'Inactive'),
                            const SizedBox(width: 8),
                            Switch(
                              value: _isActive,
                              onChanged: (value) {
                                setState(() {
                                  _isActive = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: categoryProvider.isLoading ? null : _submitForm,
                  child: categoryProvider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.category == null ? 'Add Category' : 'Save Changes',
                        style: const TextStyle(fontSize: 16),
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